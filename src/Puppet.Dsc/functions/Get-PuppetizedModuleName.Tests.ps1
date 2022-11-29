Describe 'Get-PuppetizedModuleName' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'Basic verification' {
      It 'lower-cases module names' {
        Get-PuppetizedModuleName 'xDSCSomething' | Should -MatchExactly 'xdscsomething'
      }
      It 'replaces invalid characters' {
        Get-PuppetizedModuleName 'xDSC::Something' | Should -MatchExactly 'xdsc__something'
      }
      It 'deals with prefixed numbers' {
        Get-PuppetizedModuleName '7zip' | Should -MatchExactly 'a7zip'
      }
    }
  }
}
