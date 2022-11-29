Describe 'Get-TypeParameterContent' -Tag 'Unit' {
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
        $ExampleParameterInfo = [PSCustomObject[]]@(
          @{
            Name              = 'apple'
            DefaultValue      = $null
            Type              = 'Optional[Boolean]'
            Help              = "Some string of help content`nSplit on a new line"
            is_namevar        = 'false'
            mandatory_for_get = 'false'
            mandatory_for_set = 'false'
            mof_is_embedded   = 'false'
            mof_type          = 'bool'
          },
          @{
            Name              = 'banana'
            DefaultValue      = 'foo'
            Type              = "Enum['foo', 'bar']"
            Help              = $null
            is_namevar        = 'true'
            mandatory_for_get = 'true'
            mandatory_for_set = 'true'
            mof_is_embedded   = 'false'
            mof_type          = 'string'
          },
          @{
            Name              = 'cookie'
            DefaultValue      = 'foo'
            Type              = 'String'
            Help              = $null
            is_namevar        = 'false'
            mandatory_for_get = 'true'
            mandatory_for_set = 'true'
            mof_is_embedded   = 'false'
            mof_type          = 'string'
          }
        )
      }
      It 'Returns an appropriate representation of a Puppet Resource API type attribute' {
        $Result = Get-TypeParameterContent -ParameterInfo $ExampleParameterInfo
        $Result[0] | Should -MatchExactly 'dsc_apple: {'
        $Result[0] | Should -MatchExactly 'Some string of help content'
        $Result[0] | Should -MatchExactly 'mandatory_for_get: false,'
        $Result[0] | Should -MatchExactly 'mandatory_for_set: false,'
        $Result[0] | Should -MatchExactly "mof_type: 'bool',"
        $Result[0] | Should -MatchExactly 'mof_is_embedded: false,'
        $Result[1] | Should -MatchExactly 'dsc_banana: {'
        $Result[1] | Should -MatchExactly "desc: ' ',"
        $Result[1] | Should -MatchExactly 'behaviour: :namevar,'
        $Result[1] | Should -MatchExactly 'mandatory_for_get: true,'
        $Result[1] | Should -MatchExactly 'mandatory_for_set: true,'
        $Result[1] | Should -MatchExactly "mof_type: 'string',"
        $Result[1] | Should -MatchExactly 'mof_is_embedded: false,'
        $Result[2] | Should -MatchExactly 'dsc_cookie: {'
        $Result[2] | Should -MatchExactly "desc: ' ',"
        $Result[2] | Should -MatchExactly 'mandatory_for_get: true,'
        $Result[2] | Should -MatchExactly 'mandatory_for_set: true,'
        $Result[2] | Should -MatchExactly "mof_type: 'string',"
        $Result[2] | Should -MatchExactly 'mof_is_embedded: false,'
      }
    }
  }
}
