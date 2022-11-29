Describe 'Get-DscResourceParameterInfo' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'When the AST can be parsed for functions' {
    It 'returns the full set of expected parameter info if the resource can be parsed fully' {
      InModuleScope Puppet.Dsc {
        # We cannot effectively mock out the underlying object, so we need to retrieve a
        # well-known DSC resource at a specific version
        $FullyParseableResource = Get-DscResource -Name Archive -Module @{
          ModuleName    = 'PSDscResources'
          ModuleVersion = '2.12.0.0'
        }
        $ParameterToInspect = Get-DscResourceParameterInfo -DscResource $FullyParseableResource |
          Select-Object -Last 1
        $ParameterToInspect.Name | Should -BeExactly 'validate'
        $ParameterToInspect.DefaultValue | Should -BeExactly '$false'
        $ParameterToInspect.Type | Should -BeExactly 'Optional[Boolean]'
        $ParameterToInspect.Help | Should -MatchExactly '^Specifies whether or not'
        $ParameterToInspect.is_parameter      | Should -Be $true
        $ParameterToInspect.is_namevar        | Should -BeExactly 'false'
        $ParameterToInspect.mandatory_for_get | Should -BeExactly 'false'
        $ParameterToInspect.mandatory_for_set | Should -BeExactly 'false'
        $ParameterToInspect.mof_is_embedded | Should -BeExactly 'false'
        $ParameterToInspect.mof_type | Should -BeExactly 'bool'
      }
    }
  }
  Context 'When the AST cannot be parsed for functions' {
    It 'returns only the set of values retrievable from the DscResourceInfo object' {
      InModuleScope Puppet.Dsc {
        # We cannot effectively mock out the underlying object, so we need to retrieve a
        # well-known DSC resource at a specific version
        $BinaryResource = Get-DscResource -Name File
        $ParameterToInspect = Get-DscResourceParameterInfo -DscResource $BinaryResource |
          Select-Object -First 1
        $ParameterToInspect.Name | Should -BeExactly 'destinationpath'
        # The default value for a parameter can only be discovered via the AST
        $ParameterToInspect.DefaultValue | Should -BeNullOrEmpty
        $ParameterToInspect.Type | Should -BeExactly 'String'
        # The help info for a parameter can only be discovered via the AST
        $ParameterToInspect.Help | Should -BeNullOrEmpty
        $ParameterToInspect.is_parameter      | Should -Be $false
        $ParameterToInspect.is_namevar        | Should -BeExactly 'true'
        $ParameterToInspect.mandatory_for_get | Should -BeExactly 'true'
        $ParameterToInspect.mandatory_for_set | Should -BeExactly 'true'
        $ParameterToInspect.mof_is_embedded | Should -BeExactly 'false'
        $ParameterToInspect.mof_type | Should -BeExactly 'string'
      }
    }
  }
}
