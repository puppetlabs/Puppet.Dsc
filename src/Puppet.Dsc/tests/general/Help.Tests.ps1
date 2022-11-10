Describe 'Validating function help' -Tag @('Help', 'General') {
  BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    $CommandPath = @("$ModuleRoot\functions", "$ModuleRoot\internal\functions")
    $ModuleName = 'Puppet.Dsc'
    $Module = Get-Module -ListAvailable -Name "$ModuleRoot\src\$ModuleName.psd1"

    $ExceptionsFile = "$(Split-Path -Parent $PSCommandPath)\Help.Exceptions.ps1"
    . $ExceptionsFile

    $includedNames = Get-ChildItem $CommandPath -Recurse -File |
      Where-Object Name -Like '*.ps1' |
      Select-Object -ExpandProperty BaseName
    $CommandsToValidate = New-Object -TypeName System.Collections.ArrayList
    $null = Get-Command -Module $Module -CommandType Cmdlet, Function |
      Where-Object Name -In $includedNames |
      ForEach-Object -Process {
        $CommandsToValidate.Add(@{
            Name   = $PSItem.Name
            Object = $PSItem
          })
      }
  }

  Context 'Validating help for <Name>' -Foreach $CommandsToValidate {
    BeforeDiscovery {
      $Help = Get-Help $Name -ErrorAction SilentlyContinue
    }
    BeforeAll {
      $Help = Get-Help $Name -ErrorAction SilentlyContinue
    }

    It 'is not auto-generated' {
      $Help.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
    }
    It 'has a description' {
      $Help.Description | Should -Not -BeNullOrEmpty
    }
    It 'has example code' {
      ($Help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
    }
    It 'has example text' {
      ($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should -Not -BeNullOrEmpty
    }
    Context 'Test parameter help for <Name>' {
      BeforeDiscovery {
        $Common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer', 'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable', 'Confirm', 'WhatIf'
        $ParametersToValidate = New-Object -TypeName System.Collections.ArrayList
        $HelpParameterNames = $Help.Parameters.Parameter.Name | Sort-Object -Unique
        $Parameters = $Object.ParameterSets.Parameters | Sort-Object -Property Name -Unique | Where-Object Name -NotIn $common
        $null = $Parameters | ForEach-Object {
          $ParametersToValidate.Add(@{
              ParameterName = $PSItem.Name
              ParameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $PSItem.Name
            })
        }

      }

      Context 'Validating <ParameterName>' -ForEach $ParametersToValidate {
        It 'gets help for parameter: <ParameterName>' {
          $ParameterHelp.Description.Text | Should -Not -BeNullOrEmpty
        }
      }
    }
  }
}
