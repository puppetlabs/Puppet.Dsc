Describe 'Update-PuppetModuleReadme' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'Basic Verification' {
      BeforeAll {
        # Setup fixtures
        $PuppetFolderPath = 'TestDrive:\'
        New-Item -Path "$PuppetFolderPath/README.md"
        $ModuleRootPath = Split-Path -Parent $PSCommandPath |
          Split-Path -Parent |
          Split-Path -Parent
        $ManifestFixtureFile = Resolve-Path -Path "$ModuleRootPath/tests/fixtures/PowerShellGet.psd1"
        $ManifestFilePath = 'TestDrive:\PowerShellGet.psd1'
        Copy-Item -Path $ManifestFixtureFile -Destination $ManifestFilePath
        # Import from the Manifest Fixture
        $ManifestData = Import-PSFPowerShellDataFile -Path $ManifestFixtureFile
        # Setup mocks
        Mock Import-PSFPowerShellDataFile { return $ManifestData }
        Mock Get-ReadmeContent { return 'Content' }
        Mock Out-Utf8File { }
      }

      Context 'Parameter handling' {
        BeforeAll {
          Mock Get-PuppetizedModuleName { return 'foo' }
        }

        It 'Errors if the specified Puppet readme file cannot be found' {
          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PowerShellModuleName         = 'PowerShellGet'
            PuppetModuleFolderPath       = 'TestDrive:\foo\bar'
            PuppetModuleName             = 'powershellget'
          }
          # NB: This test may only work on English language test nodes?
          { Update-PuppetModuleReadme @Parameters } | Should -Throw "Cannot find path 'TestDrive:\foo\bar\README.md' because it does not exist."
        }
        It 'Errors if the specified PowerShell module manifest cannot be found' {
          $Parameters = @{
            PowerShellModuleManifestPath = 'TestDrive:\foo\bar'
            PowerShellModuleName         = 'PowerShellGet'
            PuppetModuleFolderPath       = $PuppetFolderPath
            PuppetModuleName             = 'powershellget'
          }
          { Update-PuppetModuleReadme @Parameters } | Should -Throw "Cannot find path 'TestDrive:\foo\bar' because it does not exist."
        }
        It 'Errors if the PowerShellModuleManifestPath is not specified' {
          (Get-Command -Name Update-PuppetModuleReadme).Parameters['PowerShellModuleManifestPath'].Attributes |
            Where-Object -FilterScript { $_ -is [parameter] } |
            Select-Object -ExpandProperty Mandatory | Should -Be $true
        }
        It 'Errors if the PowerShellModuleName is not specified' {
          (Get-Command -Name Update-PuppetModuleReadme).Parameters['PowerShellModuleName'].Attributes |
            Where-Object -FilterScript { $_ -is [parameter] } |
            Select-Object -ExpandProperty Mandatory | Should -Be $true
        }
        It 'Errors if the PuppetModuleFolderPath is not specified' {
          (Get-Command -Name Update-PuppetModuleReadme).Parameters['PuppetModuleFolderPath'].Attributes |
            Where-Object -FilterScript { $_ -is [parameter] } |
            Select-Object -ExpandProperty Mandatory | Should -Be $true
        }
        It 'Sets the Puppet module name if not specified' {
          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PowerShellModuleName         = 'PowerShellGet'
            PuppetModuleFolderPath       = $PuppetFolderPath
          }
          # Specified
          { Update-PuppetModuleReadme @Parameters -PuppetModuleName override } | Should -Not -Throw
          Should -Invoke Get-PuppetizedModuleName -Times 0
          Should -Invoke Get-ReadmeContent -Times 1 -ParameterFilter {
            $PuppetModuleName -ceq 'override'
          }
          # Unspecified
          { Update-PuppetModuleReadme @Parameters } | Should -Not -Throw
          Should -Invoke Get-PuppetizedModuleName -Times 1
          Should -Invoke Get-ReadmeContent -Times 1 -ParameterFilter {
            $PuppetModuleName -ceq 'foo'
          }
        }
        It 'Errors if the PowerShellModuleManifestPath is specified as an empty string' {
          $Parameters = @{
            PowerShellModuleManifestPath = ''
            PowerShellModuleName         = 'PowerShellGet'
            PuppetModuleFolderPath       = $PuppetFolderPath
            PuppetModuleName             = 'powershellget'
          }
          { Update-PuppetModuleReadme @Parameters } | Should -Throw "Cannot validate argument on parameter 'PowerShellModuleManifestPath'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
        }
        It 'Errors if the PowerShellModuleName is specified as an empty string' {
          $Parameters = @{
            PowerShellModuleManifestPath = 'TestDrive:\foo\bar'
            PowerShellModuleName         = ''
            PuppetModuleFolderPath       = $PuppetFolderPath
            PuppetModuleName             = 'powershellget'
          }
          { Update-PuppetModuleReadme @Parameters } | Should -Throw "Cannot validate argument on parameter 'PowerShellModuleName'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
        }
        It 'Errors if the PuppetModuleFolderPath is specified as an empty string' {
          $Parameters = @{
            PowerShellModuleManifestPath = 'TestDrive:\foo\bar'
            PowerShellModuleName         = 'PowerShellGet'
            PuppetModuleFolderPath       = ''
            PuppetModuleName             = 'powershellget'
          }
          { Update-PuppetModuleReadme @Parameters } | Should -Throw "Cannot validate argument on parameter 'PuppetModuleFolderPath'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
        }
        It 'Sets the Puppet module name if specified as an empty string' {
          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PowerShellModuleName         = 'PowerShellGet'
            PuppetModuleFolderPath       = $PuppetFolderPath
            PuppetModuleName             = ''
          }
          # empty
          { Update-PuppetModuleReadme @Parameters } | Should -Not -Throw
          Should -Invoke Get-PuppetizedModuleName -Times 1
          Should -Invoke Get-ReadmeContent -Times 1 -ParameterFilter {
            $PuppetModuleName -ceq 'foo'
          }
        }
      }
      Context 'Updating Readme' {
        BeforeAll {
          Mock Get-PuppetizedModuleName { }
          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PowerShellModuleName         = 'PowerShellGet'
            PuppetModuleFolderPath       = $PuppetFolderPath
            PuppetModuleName             = 'powershellget'
          }
        }

        It 'does not throw' {
          { Update-PuppetModuleReadme @Parameters } | Should -Not -Throw
        }

        It 'Retrieves the README text' {
          Should -Invoke Get-ReadmeContent -Times 1 -Scope Context
        }
        It 'Writes the file once' {
          Should -Invoke Out-Utf8File -Times 1 -Scope Context
        }
        It 'Passes the PowerShell module name' {
          Should -Invoke Get-ReadmeContent -Times 1 -Scope Context -ParameterFilter {
            $PowerShellModuleName -eq $Parameters.PowerShellModuleName
          }
        }
        It 'Constructs the PowerShell gallery link' {
          Should -Invoke Get-ReadmeContent -Times 1 -Scope Context -ParameterFilter {
            $PowerShellModuleGalleryUri -eq "https://www.powershellgallery.com/packages/$($Parameters.PowerShellModuleName)/$($ManifestData.ModuleVersion)"
          }
        }
        It 'Passes the PowerShell module description, project uri, and version' {
          $Description
          Should -Invoke Get-ReadmeContent -Times 1 -Scope Context -ParameterFilter {
            $PowerShellModuleDescription -eq $ManifestData.Description -and
            $PowerShellModuleProjectUri -eq $ManifestData.PrivateData.PSData.ProjectUri -and
            $PowerShellModuleVersion -eq $ManifestData.ModuleVersion
          }
        }
      }
    }
  }
}
