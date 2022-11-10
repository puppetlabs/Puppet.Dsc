function Update-PuppetModuleFixture {
  <#
    .SYNOPSIS
      Update the Puppet module's .fixtures.yml
    .DESCRIPTION
      Update the Puppet module's .fixtures.yml with dependencies.
    .PARAMETER PuppetModuleFolderPath
      The Path, relative or literal, to the Puppet module's root folder.
    .PARAMETER Fixture
      The fixture reference for the puppetlabs-pwshlib dependency, defined as a hash with the
      mandatory keys `Section` ('forge_modules' or 'repositories') and `Repo` (the name of the
      module on the forge, like 'puppetlabs/pwshlib', or the git repo url) and the optional
      keys `Ref` (the version on the forge or the git ref - tag or commit sha) and `Branch`
      (source code repository only, identifying the branch to be pulled from).

      Defaults to retrieving the latest released version of pwshlib from the forge.
    .PARAMETER Confirm
      Prompts for confirmation before overwriting the file
    .PARAMETER WhatIf
      Shows what would happen if the function runs.
    .EXAMPLE
      Update-PuppetModuleFixture -PuppetModuleFolderPath ./import/powershellget

      This command will update `./import/powershellget/.fixtures.yml`, adding a
      key to the Forge Modules fixture for puppetlabs/pwshlib.
    .EXAMPLE
      Update-PuppetModuleFixture -PuppetModuleFolderPath ./import/powershellget -Fixture @{
        Section = 'repositories'
        Repo    = 'https://github.com/puppetlabs/ruby-pwsh.git'
        Ref     = '0.7.4'
      }

      This command will update `./import/powershellget/.fixtures.yml`, adding a key to the
      repositories fixture for puppetlabs/ruby-pwsh on github and pulling down the `0.7.4` tag.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param (
    [string]$PuppetModuleFolderPath,
    [hashtable]$Fixture = @{
      Section = 'forge_modules'
      Repo    = 'puppetlabs/pwshlib'
    }
  )

  begin {
    # Validate Fixture definition
    Function Test-FixtureSchema ($Fixture) {
      $ValidSections = @('forge_modules', 'repositories')
      If ($Fixture.Keys -notcontains 'Section' -or $Fixture.Keys -notcontains 'Repo') {
        Throw "Passed fixture is missing a mandatory key; must specify both 'Section' and 'Repo'.`r`nPassed fixture hash:`r`n$($Fixture | Out-String)"
      }
      If ($Fixture.Section -notin $ValidSections) {
        Throw "Invalid fixture section passed: must be one of: $($ValidSections -join ', ')`r`nPassed value: $($Fixture.Section)"
      }
      If ([string]::IsNullOrEmpty($Fixture.Repo)) {
        Throw 'Fixture repo cannot be null or empty; specify a Forge module name or repository URI'
      }
    }
  }

  process {
    Try {
      $ErrorActionPreference = 'Stop'
      Test-FixtureSchema -Fixture $Fixture
      $FixturesFilePath = Resolve-Path -Path (Join-Path $PuppetModuleFolderPath '.fixtures.yml')
      $FixturesYaml = Get-Content -Path $FixturesFilePath -Raw | ConvertFrom-Yaml
      $FixturesYaml.fixtures.($Fixture.Section) = @{
        pwshlib = @{
          repo = $Fixture.Repo
        }
      }
      # References can be tags or git references
      if (![string]::IsNullOrEmpty($Fixture.ref)) {
        $FixturesYaml.fixtures.($Fixture.Section).pwshlib.ref = $Fixture.ref
      }
      if (![string]::IsNullOrEmpty($Fixture.branch)) {
        $FixturesYaml.fixtures.($Fixture.Section).pwshlib.branch = $Fixture.branch
      }
    } Catch {
      # Rethrow any exceptions from the above commands
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
    $YamlOutput = "---`n" + (ConvertTo-Yaml -Data $FixturesYaml)
    If ($PSCmdlet.ShouldProcess($FixturesFilePath, "Overwrite YAML with:`n`n$YamlOutput")) {
      Out-Utf8File -Path $FixturesFilePath -InputObject $YamlOutput
    }
  }

  end {}
}