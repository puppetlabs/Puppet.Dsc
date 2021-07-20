Describe 'Export-PuppetModule' -Tag 'Unit' {
  BeforeDiscovery {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
  }

  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'Basic verification' {
      BeforeAll {
        Mock Invoke-PdkCommand
        Mock Invoke-PdkCommand -ParameterFilter { $PassThru -eq $true } {
          'PDK Output'
        }
        Mock Resolve-Path { return [PSCustomObject]@{ Path = "TestDrive:\$Path" } }
        Mock Resolve-Path -ParameterFilter { $Path -match 'bar' } {
          Throw "Cannot find path '$PWD\foo' because it does not exist."
        }
      }

      It 'calls pdk build in the specified PuppetModuleFolderPath' {
        Export-PuppetModule -PuppetModuleFolderPath 'foo'
        Should -Invoke Invoke-PdkCommand -ParameterFilter {
          $Path -eq 'TestDrive:\foo' -and
          $Command -eq 'pdk build'
        }
      }

      It 'passes --target-dir if ExportFolderPath is specified' {
        $ExportFolderPath = 'TestDrive:\bar'
        Export-PuppetModule -PuppetModuleFolderPath 'foo' -ExportFolderPath $ExportFolderPath
        Should -Invoke Invoke-PdkCommand -ParameterFilter {
          $Path -eq 'TestDrive:\foo' -and
          $Command -eq "pdk build --target-dir $ExportFolderPath"
        }
      }

      It 'passes --force if the Force switch is specified' {
        Export-PuppetModule -PuppetModuleFolderPath 'foo' -Force
        Should -Invoke Invoke-PdkCommand -ParameterFilter {
          $Path -eq 'TestDrive:\foo' -and
          $Command -eq 'pdk build --force'
        }
      }

      It 'returns output if the PassThru switch is specified' {
        Export-PuppetModule -PuppetModuleFolderPath 'foo' -PassThru | Should -Be 'PDK Output'
        Should -Invoke Invoke-PdkCommand -ParameterFilter {
          $Path -eq 'TestDrive:\foo' -and
          $Command -eq 'pdk build'
          $PassThru -eq $true
        }
      }

      It 'throws if the PuppetModuleFolderPath cannot be resolved' {
        { Export-PuppetModule -PuppetModuleFolderPath 'bar' } | Should -Throw
      }
    }
  }
}
