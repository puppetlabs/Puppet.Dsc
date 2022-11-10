Describe 'Get-CimClassPropertiesList' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      Mock Get-CimClass {
        [pscustomobject]@{
          CimClassProperties = @('foo', 'bar', 'baz')
        }
      }
    }
    It 'returns every discovered property for the CIM class' {
      $Result = Get-CimClassPropertiesList -ClassName Example
      $Result.count | Should -Be 3
      $Result[0]    | Should -Be 'foo'
    }
    It 'Calls Get-CimClass once' {
      Should -Invoke -CommandName Get-CimClass -Times 1 -Scope Context
    }
    It 'looks in the DSC namespace by default' {
      Should -Invoke -CommandName Get-CimClass -Times 1 -Scope Context -ParameterFilter {
        $Namespace -eq 'root\Microsoft\Windows\DesiredStateConfiguration'
      }
    }
  }
}
