Describe 'Get-EmbeddedCimInstance' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    BeforeAll {
      Mock Get-CimClassPropertiesList {
        @(
          [pscustomobject]@{ Qualifiers = @([pscustomobject]@{ Name = 'foo'; Value = 'bar' }) }
          [pscustomobject]@{ Qualifiers = @([pscustomobject]@{ Name = 'EmbeddedInstance'; Value = 'bar' }) }
        )
      } -ParameterFilter { $ClassName -eq 'foo' }
      Mock Get-CimClassPropertiesList {
        @(
          [pscustomobject]@{ Qualifiers = @([pscustomobject]@{ Name = 'EmbeddedInstance'; Value = 'baz' }) }
        )
      } -ParameterFilter { $ClassName -eq 'bar' }
      Mock Get-CimClassPropertiesList {
        @(
          [pscustomobject]@{ Qualifiers = @([pscustomobject]@{ Name = 'baz'; Value = 'bing' }) }
        )
      } -ParameterFilter { $ClassName -eq 'baz' }
    }
    Context 'Basic functionality' {
      It 'returns every discovered property for the CIM class' {
        $Result = Get-EmbeddedCimInstance -ClassName foo
        $Result.count | Should -Be 1
        $Result       | Should -Be 'bar'
      }
      It 'Calls Get-CimClassPropertiesList once' {
        Should -Invoke Get-CimClassPropertiesList -Times 1 -Scope Context
      }
      It 'Looks in the DSC namespace by default' {
        Should -Invoke Get-CimClassPropertiesList -Times 1 -Scope Context -ParameterFilter {
          $Namespace -eq 'root\Microsoft\Windows\DesiredStateConfiguration'
        }
      }
    }
    Context 'When run recursively' {
      It 'returns every discovered property for the CIM class and nested CIM Classes' {
        $RecursiveResult = Get-EmbeddedCimInstance -ClassName foo -Recurse
        $RecursiveResult.count | Should -Be 2
        $RecursiveResult[0]    | Should -Be 'bar'
        $RecursiveResult[1]    | Should -Be 'baz'
      }
    }
  }
}
