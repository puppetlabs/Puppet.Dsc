Describe 'Initialize-PuppetModule' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'Basic verification' {
      BeforeAll {
        Mock Test-Path { return $False }
        Mock New-Item {}
        Mock Invoke-PdkCommand {}
        Mock Copy-Item {}
        $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $ActualTemplateFolder = Join-Path -Path $ModuleRoot -ChildPath 'internal/templates/static'

        Initialize-PuppetModule -OutputFolderPath TestDrive:\Output -PuppetModuleName Foo
      }

      It 'Creates the output folder if needed' {
        Should -Invoke New-Item -ParameterFilter { $Path -eq 'TestDrive:\Output' } -Times 1 -Scope Context
      }
      It 'Uses the PDK to scaffold a Puppet module' {
        Should -Invoke Invoke-PdkCommand -ParameterFilter { $Command -match 'pdk new module' } -Times 1 -Scope Context
      }
      It 'Copies the static files over' {
        Should -Invoke Copy-Item -ParameterFilter { $Path -eq "$ActualTemplateFolder/*" } -Times 1 -Scope Context
      }
    }
    Context 'When the module has already been scaffolded' {
      BeforeAll {
        Mock Test-Path { return $True }
        Mock New-Item {}
        Mock Remove-Item {}
        Mock Invoke-PdkCommand {}
        Mock Copy-Item {}
        $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $ActualTemplateFolder = Join-Path -Path $ModuleRoot -ChildPath 'internal/templates/static'

        Initialize-PuppetModule -OutputFolderPath TestDrive:\ -PuppetModuleName Foo
      }

      It 'Does not recreate the output folder' {
        Should -Invoke New-Item -Times 0 -Scope Context
      }
      It 'Removes the existing module' {
        Should -Invoke Remove-Item -Times 1 -Scope Context
      }
      It 'Uses the PDK to scaffold a Puppet module' {
        Should -Invoke Invoke-PdkCommand -ParameterFilter { $Command -match 'pdk new module' } -Times 1 -Scope Context
      }
      It 'Copies the static files over' {
        Should -Invoke Copy-Item -ParameterFilter { $Path -eq "$ActualTemplateFolder/*" } -Times 1 -Scope Context
      }
    }
    Context 'When the PDK command is unsuccessful' {
      BeforeAll {
        Mock Test-Path { return $True }
        Mock New-Item {}
        Mock Remove-Item {}
        Mock Invoke-PdkCommand { Throw 'foo' }
        Mock Copy-Item {}
      }
      It 'Rethrows the exception' {
        { Initialize-PuppetModule -OutputFolderPath TestDrive:\ -PuppetModuleName Bar } | Should -Throw 'foo'
        Should -Invoke Copy-Item -Times 0 -Scope Context
      }
    }
  }
}
