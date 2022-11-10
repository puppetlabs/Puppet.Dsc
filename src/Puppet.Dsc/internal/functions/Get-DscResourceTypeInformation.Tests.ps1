Describe 'Get-DscResourceTypeInformation' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'When running <ElevationStatus>' -ForEach @(
      @{
        ElevationStatus = 'elevated'
        TestResult      = $true
        QueryFunction   = 'Get-DscResourceParameterInfoByCimClass'
      }
      @{
        ElevationStatus = 'unelevated'
        TestResult      = $false
        QueryFunction   = 'Get-DscResourceParameterInfo'
      }
    ) {
      BeforeAll {
        Mock Test-RunningElevated { return $TestResult }
        Mock Get-DscResourceParameterInfoByCimClass { return $DscResource.Name }
        Mock Get-DscResourceParameterInfo { return $DscResource.Name }
        Mock Get-DscResourceImplementation { }
      }
      Context 'When passed a DSCResourceInfo object' {
        BeforeAll {
          Mock Get-DscResource {}
        }

        BeforeEach {
          $DscResources = [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]@(
            @{Name = 'foo' }
            @{Name = 'bar' }
          )
        }

        It 'does not throw' {
          { $DscResources | Get-DscResourceTypeInformation } | Should -Not -Throw
        }
        It 'processes once for each object in the pipeline' -TestCases $TestCase {
          $Result = $DscResources | Get-DscResourceTypeInformation
          Should -Invoke $QueryFunction -Times 2 -Scope It
          Should -Invoke Get-DscResourceImplementation -Times 2 -Scope It
          $Result[0].ParameterInfo | Should -Be $Result[0].Name
        }
        It 'never calls Get-DscResource' {
          $null = $DscResources | Get-DscResourceTypeInformation
          Should -Invoke Get-DscResource -Times 0 -Scope It
        }
      }
      Context 'When specifying properties' {
        BeforeAll {
          Mock Get-DscResource {
            [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{
              Name = $Name
            }
          }
        }
        Context 'by name only' {
          It 'calls Get-DscResource only once' {
            $Result = Get-DscResourceTypeInformation -Name foo, bar, baz
            $Result[0].ParameterInfo | Should -Be $Result[0].Name
            Should -Invoke Get-DscResource -Times 1 -Scope It
          }
        }

        Context 'by name and module' {
          BeforeAll {
            Mock Get-DscResource {
              [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{
                Name = $Module
              }
            } -ParameterFilter { $null -ne $Module }
          }

          It 'only searches by module if specified' {
            $Result = Get-DscResourceTypeInformation -Name bar -Module foo
            $Result.ParameterInfo | Should -Be 'foo'
            Should -Invoke Get-DscResource -Times 1 -Scope It
            Should -Invoke Get-DscResource -Times 1 -Scope It -ParameterFilter {
              $Module -eq 'foo'
            }
          }
        }

        Context 'via the pipeline' {
          BeforeAll {
            Mock Get-DscResource {
              [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{
                Name = $Name
              }
            } -ParameterFilter { $Name -eq 'foo' }
            Mock Get-DscResource {
              [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{
                Name = $Module
              }
            } -ParameterFilter { $Module -eq 'baz' }
          }

          It 'handles pipeline input by property name' {
            # Objects with name and module properties to pass to the function
            $NameOnly = [PSCustomObject]@{ Name = 'foo' }
            $NameAndModule = [PSCustomObject]@{
              Name   = 'bar'
              Module = 'baz'
            }
            $Results = $NameOnly, $NameAndModule | Get-DscResourceTypeInformation
            $Results.Count | Should -Be 2
            $Results[0].Name | Should -Be 'foo'
            $Results[1].Name | Should -Be 'baz'
          }
          It 'processes once for each resource found' {
            Should -Invoke Get-DscResource -Times 2 -Scope Context
            Should -Invoke $QueryFunction -Times 2 -Scope Context
            Should -Invoke Get-DscResourceImplementation -Times 2 -Scope Context
          }
        }
      }
    }
  }
}
