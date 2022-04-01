Describe 'Update-PuppetModuleFixture' -Tag 'Unit' {
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
        Mock Out-Utf8File { return $InputObject }
        # Create a Mock fixtures File
        New-Item -Path TestDrive:\.fixtures.yml -Value @'
---
fixtures:
  forge_modules:
'@
      }

      It 'Errors if the file cannot be found' {
        # NB: This test may only work on English language test nodes?
        { Update-PuppetModuleFixture -PuppetModuleFolderPath TestDrive:\foo\bar } | Should -Throw "Cannot find path 'TestDrive:\foo\bar\.fixtures.yml' because it does not exist."
      }
      It 'Writes a Yaml File' {
        $Result = Update-PuppetModuleFixture -PuppetModuleFolderPath TestDrive:\
        # Must start with yaml indicator for Puppet to be happy
        $Result | Should -Match '^---'
        # Must include all needed dependencies
        $Result | Should -Match 'pwshlib:'
        $Result | Should -Match 'repo: puppetlabs/pwshlib'
      }
      It 'Throws if either Section or Repo are left unspecified' {
        { Update-PuppetModuleFixture -PuppetModuleFolderPath TestDrive:\ -Fixture @{
            Section = 'forge_modules'
          } } | Should -Throw 'Passed fixture is missing a mandatory key*'
      }
      It 'Throws if the specified Section is invalid' {
        { Update-PuppetModuleFixture -PuppetModuleFolderPath TestDrive:\ -Fixture @{
            Section = 'Incorrect'
            Repo    = 'puppetlabs/pwshlib'
          } } | Should -Throw 'Invalid fixture section passed*'
      }
      It 'Throws if the Repo key is null or an empty string' {
        { Update-PuppetModuleFixture -PuppetModuleFolderPath TestDrive:\ -Fixture @{
            Section = 'repositories'
            Repo    = ''
          } } | Should -Throw 'Fixture repo cannot be null or empty*'
      }
      It 'Writes a reference for the fixture if specified' {
        $Result = Update-PuppetModuleFixture -PuppetModuleFolderPath TestDrive:\ -Fixture @{
          Section = 'forge_modules'
          Repo    = 'puppetlabs/pwshlib'
          Ref     = '0.7.4'
        }
        $Result | Should -Match 'repo: puppetlabs/pwshlib'
        $Result | Should -Match 'ref: 0.7.4'
      }
      It 'Writes a branch for the fixture if specified' {
        $Result = Update-PuppetModuleFixture -PuppetModuleFolderPath TestDrive:\ -Fixture @{
          Section = 'repositories'
          Repo    = 'https://github.com/puppetlabs/ruby-pwsh.git'
          Branch  = 'maint/main/test-branch'
        }
        $Result | Should -Match 'repo: https://github.com/puppetlabs/ruby-pwsh.git'
        $Result | Should -Match 'branch: maint/main/test-branch'
      }
    }
  }
}
