Param (
  [string]$PwshLibSource,
  [string]$PwshLibRepo,
  [string]$PwshLibReference
)

Describe 'Acceptance Tests: Multi-Module' -Tag MultiModule {
  BeforeAll {
    $ModuleRoot = Split-Path $PSCommandPath -Parent |
      Split-Path -Parent |
      Join-Path -ChildPath 'src'
    . "$ModuleRoot\Puppet.Dsc\internal\functions\Invoke-PdkCommand.ps1"
    Import-Module "$ModuleRoot/Puppet.Dsc/puppet.dsc.psd1"
  }

  BeforeDiscovery {
    $ProjectRoot = Split-Path $PSCommandPath -Parent |
      Split-Path |
      Resolve-Path
    $OutputDirectory = Join-Path (Split-Path $ProjectRoot -Parent) -ChildPath 'modules'
    $SiteDirectory = Join-Path (Split-Path $ProjectRoot -Parent) -ChildPath 'site'

    Remove-Item -Path $OutputDirectory -Recurse -Force -ErrorAction SilentlyContinue
    # Ensure the output directory exists and install pwshlib
    New-Item -Path $OutputDirectory -ItemType Directory -Force
    If ($null -eq $PwshLibSource -or 'forge' -eq $PwshLibSource) {
      If ($null -eq $PwshLibRepo) { $PwshLibRepo = 'puppetlabs/pwshlib' }
      If ([string]::IsNullOrEmpty($PwshLibReference) -or $PwshLibReference -eq 'latest' ) {
        pdk bundle exec puppet module install $PwshLibRepo --target-dir $OutputDirectory --force
        If ($LastExitCode -ne 0) { Throw "Something went wrong installing $PwshLibRepo to $OutputDirectory with Puppet" }
      } Else {
        puppet bundle exec module install $PwshLibRepo --version $PwshLibReference --target-dir $OutputDirectory --force
        If ($LastExitCode -ne 0) { Throw "Something went wrong installing $PwshLibRepo at $PwshLibReference to $OutputDirectory with Puppet" }
      }
    } ElseIf ('git' -eq $PwshLibSource) {
      If ($null -eq $PwshLibRepo) { Throw 'Specified pwshlib source as git without a repo!' }
      Push-Location -Path $OutputDirectory
      git clone $PwshLibRepo pwshlib
      if ($LastExitCode -ne 0) { Throw "Something went wrong installing $PwshLibRepo to $OutputDirectory with git" }
      If ($PwshLibReference) {
        Push-Location -Path (Join-Path -Path $OutputDirectory -ChildPath 'pwshlib')
        git checkout $PwshLibReference
        if ($LastExitCode -ne 0) { Throw "Something went wrong checking out $PwshLibReference" }
        Pop-Location
      }
      Pop-Location
      puppet bundle exec module list --modulepath $OutputDirectory
    } Else { Throw "Unexpected pwshlib source: $PwshLibSource" }
    # Ensure the website test directory exists
    If (-not (Test-Path $SiteDirectory -PathType Container -ErrorAction SilentlyContinue)) {
      mkdir $SiteDirectory
    }

    $ModuleBuildingScenarios = @(
      @{
        expected_base    = "$OutputDirectory/xwebadministration"
        PuppetModuleName = 'xwebadministration'
        BuildParameters  = @{
          PowerShellModuleName = 'xWebAdministration'
          PuppetModuleAuthor   = 'testuser'
          OutputDirectory      = $OutputDirectory
        }
      }
      @{
        expected_base    = "$OutputDirectory/xpsdesiredstateconfiguration"
        PuppetModuleName = 'xpsdesiredstateconfiguration'
        BuildParameters  = @{
          PowerShellModuleName = 'xPSDesiredStateConfiguration'
          PuppetModuleAuthor   = 'testuser'
          OutputDirectory      = $OutputDirectory
        }
      }
    )

    $WebServerManifest = "$ProjectRoot\examples\webserver\webserver.pp"
    If (Test-Path $WebServerManifest) {
      Remove-Item $WebServerManifest
    }
    Get-Content "$ProjectRoot\examples\webserver\webserver_template.pp" -Raw | ForEach-Object -Process {
      $UpdatedContent = $_ -replace '%%SOURCE_PATH%% .+', "'$ProjectRoot/examples/webserver/website'"
      $UpdatedContent = $UpdatedContent -replace '%%DESTINATION_PATH%% .+', "'$SiteDirectory'"
      $UpdatedContent = $UpdatedContent -replace '%%WEBSITE_NAME%% .+', "'Puppet DSC Site'"
      $UpdatedContent = $UpdatedContent -replace '%%SITE_ID%% .+', '7'
      $UpdatedContent
    } | New-Item $WebServerManifest

    $IdempotentTestCase = @{
      ScriptBlock = "pdk bundle exec puppet apply $WebServerManifest --modulepath $OutputDirectory --verbose --trace *>&1"
      SiteContent = (Get-Content -Raw -Path "$ProjectRoot\examples\webserver\website\index.html")
    }
  }

  Context 'validating build of <puppetmodulename>' -ForEach $ModuleBuildingScenarios {
    BeforeAll {
      # Clean up prior builds
      Remove-Item $expected_base -Force -Recurse -ErrorAction Ignore
    }
    It 'is puppetizable' {
      { New-PuppetDscModule @BuildParameters } | Should -Not -Throw
    }
    It 'is buildable' {
      Invoke-PdkCommand -Path $expected_base -Command "pdk build --target-dir='$($BuildParameters.OutputDirectory)'" -SuccessFilterScript {
        $_ -match "Build of testuser-$PuppetModuleName has completed successfully."
      }
    }
  }

  Context 'validating idempotency' {
    BeforeAll {
      # Ensure IIS is not installed
      $Feature = Get-WindowsFeature -Name 'Web-Asp-Net45'
      If ($Feature.Installed) {
        Remove-WindowsFeature -Name $Feature.Name -ErrorAction Stop
      }
      $DefaultSite = Get-Website 'Default Web Site'
      $ExampleSite = Get-Website 'Puppet DSC Site'
      If ($DefaultSite.State -eq 'Stopped') {
        Start-Website -Name $DefaultSite.Name
      }
      If ($ExampleSite) {
        Stop-Website -Name $ExampleSite.Name
        Remove-Website -Name $ExampleSite.Name
        Remove-Item -Path $SiteDirectory -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
    It 'idempotently applies without unexpected errors' -TestCases $IdempotentTestCase {
      $PuppetApply = [scriptblock]::Create($ScriptBlock)
      $FirstRunResult = Start-Job -ScriptBlock $PuppetApply |
        Wait-Job | Select-Object -ExpandProperty ChildJobs | Select-Object -First 1
      $FirstRunOutput = $FirstRunResult.Output -join "`r`n"
      $FirstRunErrors = $FirstRunResult.Output | Where-Object -FilterScript { $_ -match '^Error: ' }
      $ExpectedFirstRunErrors = $FirstRunErrors | Where-Object -FilterScript { $_ -match "Please ensure that the PowerShell module for role 'WebAdministration' is installed." }
      $FirstRunErrors | Should -Be $ExpectedFirstRunErrors
      $FirstRunOutput | Should -Match "Dsc_xwindowsfeature\[AspNet45\]/dsc_ensure: dsc_ensure changed 'Absent' to 'Present'"
      $FirstRunOutput | Should -Match 'dsc_xwindowsfeature\[\{:name=>"AspNet45", :dsc_name=>"Web-Asp-Net45"\}\]: Creating: Finished'
      $FirstRunOutput | Should -Match "Dsc_xwebsite\[DefaultSite\]/dsc_state: dsc_state changed 'Started' to 'Stopped'"
      $FirstRunOutput | Should -Match "Dsc_xwebsite\[DefaultSite\]/dsc_serverautostart: dsc_serverautostart changed true to 'false'"
      $FirstRunOutput | Should -Match 'dsc_xwebsite\[\{:name=>"DefaultSite", :dsc_name=>"Default Web Site"\}\]: Updating: Finished'
      $FirstRunOutput | Should -Match 'File\[.+\]/ensure: defined content'
      $FirstRunOutput | Should -Match 'Dsc_xwebsite\[NewWebsite\]/dsc_siteid: dsc_siteid changed  to 7'
      $FirstRunOutput | Should -Match "Dsc_xwebsite\[NewWebsite\]/dsc_ensure: dsc_ensure changed 'Absent' to 'Present'"
      $FirstRunOutput | Should -Match "Dsc_xwebsite\[NewWebsite\]/dsc_physicalpath: dsc_physicalpath changed  to '.+'"
      $FirstRunOutput | Should -Match "Dsc_xwebsite\[NewWebsite\]/dsc_state: dsc_state changed  to 'Started'"
      $FirstRunOutput | Should -Match "Dsc_xwebsite\[NewWebsite\]/dsc_serverautostart: dsc_serverautostart changed  to 'true'"
      $FirstRunOutput | Should -Match 'dsc_xwebsite\[\{:name=>"NewWebsite", :dsc_name=>"Puppet DSC Site"\}\]: Creating: Finished'
      # Pending next release of puppetlabs-pwshlib
      # $FirstRunOutput | Should -Not -Match 'Value type mismatch'
      $FirstRunOutput | Should -Match 'Notice: Applied catalog'
      $SecondRunResult = Start-Job -ScriptBlock $PuppetApply |
        Wait-Job | Select-Object -ExpandProperty ChildJobs | Select-Object -First 1
      $SecondRunOutput = $FirstRunResult.Output -join "`r`n"
      $SecondRunOutput | Should -Match 'Notice: Compiled catalog for .+ in environment production'
      $SecondRunResult.Count | Should -Be 1
      Invoke-WebRequest -Uri 'http://localhost' -UseBasicParsing |
        Select-Object -ExpandProperty StatusCode | Should -Be 200
    }
  }
}
