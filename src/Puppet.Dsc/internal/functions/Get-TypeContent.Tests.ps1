Describe 'Get-TypeContent' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    Context 'Basic Verification' {
      BeforeAll {
        # We cannot effectively mock out the underlying object, so we need to retrieve a
        # well-known DSC resource at a specific version
        $ExampleResource = Get-DscResource -Name Archive -Module @{
          ModuleName    = 'PSDscResources'
          ModuleVersion = '2.12.0.0'
        }

        Mock Get-TypeParameterContent {}
      }

      It 'Returns an appropriate representation of a Puppet Resource API type' {
        $Result = Get-TypeContent -DscResource $ExampleResource
        $Result | Should -MatchExactly "name: 'dsc_archive'"
        $Result | Should -MatchExactly "dscmeta_resource_friendly_name: 'Archive'"
        $Result | Should -MatchExactly "dscmeta_resource_name: 'MSFT_Archive'"
        $Result | Should -MatchExactly "dscmeta_resource_implementation: 'MOF'"
        $Result | Should -MatchExactly "dscmeta_module_name: 'PSDscResources'"
        $Result | Should -MatchExactly "dscmeta_module_version: '2.12.0.0'"
        $Result | Should -MatchExactly 'The DSC Archive resource type.'
        $Result | Should -MatchExactly 'Automatically generated from version 2.12.0.0'
        $Result | Should -MatchExactly "features: \['simple_get_filter', 'canonicalize', 'custom_insync'\]"
        $Result | Should -MatchExactly 'validation_mode:'
      }
      It 'Attempts to interpolate the parameter information once' {
        Should -Invoke Get-TypeParameterContent -Times 1 -Scope Context
      }
    }
  }
}
