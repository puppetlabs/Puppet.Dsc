Describe 'UpdatePuppetModuleChangelog' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    Context 'Basic Verification' {
      BeforeAll {
        # Setup fixtures
        $PuppetFolderPath = 'TestDrive:\puppet_module'
        New-Item -Path "$PuppetFolderPath/Changelog.md" -Force
        $ModuleRootPath = Split-Path -Parent $PSCommandPath |
          Split-Path -Parent |
          Split-Path -Parent
        $ManifestFixtureFile = Resolve-Path -Path "$ModuleRootPath/tests/fixtures/PowerShellGet.psd1"
        $ManifestFilePath = 'TestDrive:\PowerShellGet.psd1'
        Copy-Item -Path $ManifestFixtureFile -Destination $ManifestFilePath
        # Import from the Manifest Fixture
        $ManifestData = Import-PSFPowerShellDataFile -Path $ManifestFixtureFile
        $ManifestDataNoReleaseNotes = Import-PSFPowerShellDataFile -Path $ManifestFixtureFile
        $ManifestDataNoReleaseNotes.PrivateData.PSData.Remove('ReleaseNotes')
      }

      Context 'Parameter handling' {
        BeforeAll {
          Mock Import-PSFPowerShellDataFile { return $ManifestData }
          Mock Out-Utf8File { }
        }

        It 'Errors if the specified Puppet changelog file cannot be found' {
          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PuppetModuleFolderPath       = 'TestDrive:\foo\bar'
          }
          # NB: This test may only work on English language test nodes?
          { Update-PuppetModuleChangelog @Parameters } | Should -Throw "Cannot find path 'TestDrive:\foo\bar\CHANGELOG.md' because it does not exist."
        }
        It 'Errors if the specified PowerShell module manifest cannot be found' {
          $Parameters = @{
            PowerShellModuleManifestPath = 'TestDrive:\foo\bar'
            PuppetModuleFolderPath       = $PuppetFolderPath
          }
          { Update-PuppetModuleChangelog @Parameters } | Should -Throw "Cannot find path 'TestDrive:\foo\bar' because it does not exist."
        }
      }
      Context 'When Release Notes exist' {
        BeforeAll {
          Mock Import-PSFPowerShellDataFile { return $ManifestData }
          Mock Out-Utf8File { return $InputObject }

          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PuppetModuleFolderPath       = $PuppetFolderPath
          }
        }

        It 'Writes the file once with the ReleaseNotes as the content' {
          $Result = Update-PuppetModuleChangelog @Parameters
          Should -Invoke Out-Utf8File -Times 1
          $Result | Should -Be $ManifestData.PrivateData.PSData.ReleaseNotes
        }
      }
      Context 'When neither Release Notes nor a changelog exist' {
        BeforeAll {
          Mock Import-PSFPowerShellDataFile { return $ManifestDataNoReleaseNotes }
          Mock Out-Utf8File { return $InputObject }

          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PuppetModuleFolderPath       = $PuppetFolderPath
          }
        }

        It 'Does not write to the file' {
          Update-PuppetModuleChangelog @Parameters
          Should -Invoke Out-Utf8File -Times 0
        }
      }
      Context 'When Release Notes do not exist but a changelog does' {
        BeforeAll {
          New-Item -Path 'TestDrive:\CHANGELOG.md' -Value 'foo'
          Mock Import-PSFPowerShellDataFile { return $ManifestDataNoReleaseNotes }
          Mock Out-Utf8File { return $InputObject }

          $Parameters = @{
            PowerShellModuleManifestPath = $ManifestFilePath
            PuppetModuleFolderPath       = $PuppetFolderPath
          }
        }

        It 'Writes the file once with the CHANGELOG as the content' {
          $Result = Update-PuppetModuleChangelog @Parameters
          $Result | Should -Be 'foo'
          Should -Invoke Out-Utf8File -Times 1
        }
      }
    }
  }
}
