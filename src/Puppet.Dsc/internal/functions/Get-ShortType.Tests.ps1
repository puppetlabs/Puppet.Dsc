Describe 'Get-ShortType' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic functionality' {
    It 'Returns data types stripped of their outer brackets' {
      Get-ShortType -PropertyType '[string]' | Should -BeExactly 'string'
      Get-ShortType -PropertyType '[string[]]' | Should -BeExactly 'string[]'
      Get-ShortType -PropertyType '[[string[]]]' | Should -BeExactly '[string[]]'
    }
  }
}
