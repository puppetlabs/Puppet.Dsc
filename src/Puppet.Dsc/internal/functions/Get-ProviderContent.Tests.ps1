Describe 'Get-ProviderContent' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    Context 'Basic Verification' {
      It 'Returns a valid Puppet Resource API type attribute' {
        $ExampleDscResource = New-Object -TypeName Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo -Property @{Name = 'FooBar_Baz' }
        $ExpectedClassDeclaration = 'class Puppet::Provider::DscFoobarBaz::DscFoobarBaz < Puppet::Provider::DscBaseProvider'
        $ActualClassDeclaration = (Get-ProviderContent -DscResource $ExampleDscResource) -Split "`r`n"
        $ActualClassDeclaration -match $ExpectedClassDeclaration | Should -Be $true
      }
    }
  }
}
