$RunningElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')

Describe 'Get-DscResourceParameterInfoByCimClass' -Skip:(!$RunningElevated) -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    Context 'basic functionality' {
      It 'returns parameter info for resources without embedded CIM instances' {
        # We cannot effectively mock out the underlying object, so we need to retrieve a
        # well-known DSC resource at a specific version
        $CimlessDscResource = Get-DscResource -Name Archive -Module @{
          ModuleName    = 'PSDscResources'
          ModuleVersion = '2.12.0.0'
        }
        $CimlessParameterToInspect = Get-DscResourceParameterInfoByCimClass -DscResource $CimlessDscResource |
          Sort-Object -Property Name |
          Select-Object -Last 1
        $CimlessParameterToInspect.Name              | Should -BeExactly 'validate'
        # This function currently cannot discover default values
        $CimlessParameterToInspect.DefaultValue      | Should -BeNullOrEmpty
        $CimlessParameterToInspect.Type              | Should -BeExactly 'Optional[Boolean]'
        $CimlessParameterToInspect.Help              | Should -MatchExactly '^Specifies whether or not'
        $CimlessParameterToInspect.is_parameter      | Should -BeExactly $true
        $CimlessParameterToInspect.is_namevar        | Should -BeExactly 'false'
        $CimlessParameterToInspect.mandatory_for_get | Should -BeExactly 'false'
        $CimlessParameterToInspect.mandatory_for_set | Should -BeExactly 'false'
        $CimlessParameterToInspect.mof_is_embedded   | Should -BeExactly 'false'
        # This surface is different from Get-DscResourceParameterInfo, but only used for embedded instances
        # which this property is not.
        # $CimlessParameterToInspect.mof_type | Should -BeExactly 'bool'
        $CimlessParameterToInspect.mof_type          | Should -BeExactly 'Boolean'
      }
      It 'returns parameter info for resources with embedded CIM instances' {
        # We cannot effectively mock out the underlying object, so we need to retrieve a
        # well-known DSC resource at a specific version
        $CimfulDscResource = Get-DscResource -Name NTFSAccessEntry -Module @{
          ModuleName    = 'AccessControlList'
          ModuleVersion = '1.4.0.0'
        }
        $CimfulParametersToInspect = Get-DscResourceParameterInfoByCimClass -DscResource $CimfulDscResource |
          Sort-Object -Property Name
        $AclProperty = $CimfulParametersToInspect | Where-Object -FilterScript { $_.Name -eq 'AccessControlList' }
        $PathProperty = $CimfulParametersToInspect | Where-Object -FilterScript { $_.Name -eq 'Path' }
        $AclProperty.Name              | Should -BeExactly 'accesscontrollist'
        # This function currently cannot discover default values
        $AclProperty.DefaultValue      | Should -BeNullOrEmpty
        $AclProperty.Type              | Should -MatchExactly ([Regex]::Escape('Array[Struct[{'))
        $AclProperty.Type              | Should -MatchExactly ([Regex]::Escape("cim_instance_type => Enum['NTFSAccessControlEntry']"))
        $AclProperty.Help              | Should -MatchExactly '^Indicates the access control information'
        $AclProperty.is_parameter      | Should -Be $false
        $AclProperty.is_namevar        | Should -BeExactly 'false'
        $AclProperty.mandatory_for_get | Should -BeExactly 'true'
        $AclProperty.mandatory_for_set | Should -BeExactly 'true'
        $AclProperty.mof_is_embedded   | Should -BeExactly 'true'
        $AclProperty.mof_type          | Should -BeExactly 'NTFSAccessControlList[]'
        # It should also be able to tell if something is mandatory & a namevar
        $PathProperty.is_namevar       | Should -BeExactly 'true'
      }
    }
    Context "When the resource can't be found" {
      Mock Initialize-DscResourceCimClass { Throw 'foo' }
      $DscResource = Get-DscResource -Name Archive -Module @{
        ModuleName    = 'PSDscResources'
        ModuleVersion = '2.12.0.0'
      }
      It 'stops processing' {
        { Get-DscResourceParameterInfoByCimClass -DscResource $DscResource } | Should -Throw
      }
    }
  }
}
