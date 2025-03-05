Describe 'Get-PuppetDataType' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    BeforeAll {
      Function New-DscParameter {
        Param (
          [string]$Name = 'foo',
          [string]$PropertyType = '[string]',
          [string[]]$Values = @(),
          [switch]$IsMandatory
        )
        [pscustomobject]@{
          Name         = $Name
          PropertyType = $PropertyType
          IsMandatory  = $IsMandatory
          Values       = $Values
        }
      }
    }
    Context 'Basic Functionality' {
      It 'Distinguishes between optional and mandatory parameters' {
        Get-PuppetDataType -DscResourceProperty (New-DscParameter) | Should -BeExactly 'Optional[String]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -IsMandatory) | Should -BeExactly 'String'
      }
      It 'Handles arrays' {
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[string[]]') | Should -BeExactly 'Optional[Array[String]]'
      }
      It 'Handles embedded instances' {
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType 'foo') | Should -BeExactly 'Optional[Hash]'
      }
      It 'Handles Enums' {
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -Values @('Foo', 'Bar', 'Baz')) | Should -BeExactly "Optional[Enum['Foo', 'foo', 'Bar', 'bar', 'Baz', 'baz']]"
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -Values @('Yes')) | Should -BeExactly "Optional[Enum['Yes', 'yes']]"
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -Values @('No')) | Should -BeExactly "Optional[Enum['No', 'no']]"
      }
      It 'Handles well-known types' {
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[Bool]') | Should -BeExactly 'Optional[Boolean]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[Byte]') | Should -BeExactly 'Optional[Integer[0, 255]]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[int]') | Should -BeExactly 'Optional[Integer[-2147483648, 2147483647]]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[PSCredential]') | Should -BeExactly 'Optional[Struct[{ user => String[1], password => Variant[String[1], Sensitive[String[1]]] }]]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[SecureString]') | Should -BeExactly 'Optional[Variant[String, Sensitive[String]]]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[DateTime]') | Should -BeExactly 'Optional[Timestamp]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[HashTable]') | Should -BeExactly 'Optional[Hash]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[Char]') | Should -BeExactly 'Optional[String[1,1]]'
        Get-PuppetDataType -DscResourceProperty (New-DscParameter -PropertyType '[Object]') | Should -BeExactly 'Optional[Any]'
      }
    }
  }
}
