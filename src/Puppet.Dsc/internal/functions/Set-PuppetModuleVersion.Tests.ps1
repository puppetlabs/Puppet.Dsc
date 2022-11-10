Describe 'Update-PuppetModuleMetadata' -Tag 'Unit' {
  BeforeDiscovery {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
  }
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'Basic Verification' {
      BeforeAll {
        Mock Resolve-Path { return [PSCustomObject]@{ Path = $Path } }
        Mock Get-Content {
          If ($Path.count -eq 1) {
            $null = $Path[0] -match 'TestDrive:\\(?<ModuleName>\w+)\\metadata\.json'
          } else {
            $null = $Path -match 'TestDrive:\\(?<ModuleName>\w+)\\metadata\.json'
          }
          $ModuleName = $Matches.ModuleName
          return "{`"version`":`"1.2.3-0-0`",`"name`":`"$ModuleName`"}"
        }
        Mock ConvertFrom-Json {
          $null = $InputObject -match '"version":"(?<Version>\S+)","name":"(?<ModuleName>\w+)"'
          return [PSCustomObject]@{ name = $Matches.ModuleName ; version = $Matches.Version }
        }
        Mock ConvertTo-UnescapedJson { return $InputObject }
        Mock Out-Utf8File { return $InputObject }
      }

      It 'does not throw if a valid path to a Puppet module folder is passed' {
        { Set-PuppetModuleVersion -PuppetModuleFolderPath 'TestDrive:\foo' -Version '1.2.3-0-1' } | Should -Not -Throw
      }

      It 'retrieves metadata for the Puppet module in the specified folder' {
        Should -Invoke Resolve-Path -Scope Context -ParameterFilter { $Path -eq 'TestDrive:\foo\metadata.json' }
        Should -Invoke Get-Content -Scope Context -Times 1
        Should -Invoke ConvertFrom-Json -Scope Context -Times 1
      }

      It "sets the version in the Puppet module's metadata" {
        Should -Invoke ConvertTo-UnescapedJson -Scope Context -ParameterFilter { $InputObject.version -eq '1.2.3-0-1' }
      }

      It 'writes the updated metadata to disk' {
        Should -Invoke Out-Utf8File -Scope Context -ParameterFilter {
          $Path -eq 'TestDrive:\foo\metadata.json' -and
          $InputObject.version -eq '1.2.3-0-1'
        }
      }

      Context 'when the module metadata cannot be found' {
        BeforeAll {
          Mock Resolve-Path -ParameterFilter { $Path -match 'DoesNotExist' } {
            Throw "Cannot find path '$Path' because it does not exist."
          }
        }

        It 'throws an error on unresolvable path' {
          { Set-PuppetModuleVersion -PuppetModuleFolderPath 'TestDrive:\DoesNotExist' -Version '1.2.3-0-1' } |
            Should -Throw "Cannot find path 'TestDrive:\DoesNotExist\metadata.json'*"
        }
      }

      Context 'when the module metadata cannot be parsed' {
        BeforeAll {
          Mock ConvertFrom-Json -ParameterFilter { $InputObject -match 'UnparseableJson' } {
            Throw 'Unparseable!'
          }
        }

        It 'throws an error on unparseable JSON' -tag 'fuck' {
          { Set-PuppetModuleVersion -PuppetModuleFolderPath 'TestDrive:\UnparseableJson' -Version '1.2.3-0-1' } |
            Should -Throw 'Unparseable!'
        }
      }
    }
  }
}