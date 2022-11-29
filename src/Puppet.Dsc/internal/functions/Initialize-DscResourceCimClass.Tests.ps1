Describe 'Initialize-DscResourceCimClass' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'basic functionality' {
    BeforeAll {
      Mock Invoke-DscResource {
        Throw 'invalid attempt'
      } -ParameterFilter { $Name -eq 'foo' }
      Mock Invoke-DscResource {
        Throw "Resource $Name was not found"
      } -ParameterFilter { $Name -ne 'foo' }
    }

    It 'does not throw an error if the specified resource is found' {
      { Initialize-DscResourceCimClass -Name 'foo' -ModuleName 'baz' -ModuleVersion '1.2.3' } |
        Should -Not -Throw
    }
    It 'Calls Invoke-DscResource once' {
      $null = Initialize-DscResourceCimClass -Name 'foo' -ModuleName 'baz' -ModuleVersion '1.2.3'
      Should -Invoke Invoke-DscResource -Times 1 -Scope It
    }
    It 'throws an error if the specified resource cannot be found' {
      { Initialize-DscResourceCimClass -Name 'bar' -ModuleName 'baz' -ModuleVersion '1.2.3' } |
        Should -Throw
    }
  }
}
