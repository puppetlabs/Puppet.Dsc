Describe 'Test-DscResourcePropertyParameterStatus' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      Function New-DscParameter {
        Param (
          [string]$Name = 'foo',
          [string]$ReferenceClassName
        )
        [pscustomobject]@{
          Name               = $Name
          ReferenceClassName = $ReferenceClassName
        }
      }
    }

    It 'A parameter which is not in the known parameter list or a credential returns false' {
      Test-DscResourcePropertyParameterStatus -Property (New-DscParameter) | Should -Be $false
    }
    It 'A parameter whose name is in the known parameter list returns true' {
      Test-DscResourcePropertyParameterStatus -Property (New-DscParameter -Name 'Force') | Should -Be $true
      Test-DscResourcePropertyParameterStatus -Property (New-DscParameter -Name 'Purge') | Should -Be $true
      Test-DscResourcePropertyParameterStatus -Property (New-DscParameter -Name 'Validate') | Should -Be $true
    }
    It 'A parameter whose reference class is a credential returns true' {
      Test-DscResourcePropertyParameterStatus -Property (New-DscParameter -ReferenceClassName 'MSFT_Credential') | Should -Be $true
    }
  }
}
