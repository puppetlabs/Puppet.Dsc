Describe 'Invoking PSScriptAnalyzer against commandbase' -Tag @('ScriptAnalysis', 'General') {
  BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    $RulesToTest = New-Object System.Collections.ArrayList
    $ScriptAnalyzerRules = Get-ScriptAnalyzerRule
    ForEach ($Rule in $ScriptAnalyzerRules) {
      $RulesToTest.Add(@{
          RuleName    = $Rule.RuleName
          Severity    = $Rule.Severity
          Description = $Rule.Description
          SourceName  = $Rule.SourceName
        })
    }

    $FilesToInspect = New-Object System.Collections.ArrayList
    $CommandFiles = Get-ChildItem -Path $ModuleRoot -Recurse |
      Where-Object -FilterScript { ($_.Name -like '*.ps1') -and ($_.Name -notmatch '\.(Tests|Exceptions)\.') }
    ForEach ($File in $CommandFiles) {
      $FilesToInspect.Add(@{
          Name = $File.BaseName
          Path = $File.FullName
        })
    }
  }

  BeforeAll {
    $List = New-Object System.Collections.ArrayList
  }

  AfterAll {
    $List | Out-Default
  }

  Context 'Analyzing <Name>' -Foreach $FilesToInspect {
    BeforeAll {
      $Analysis = Invoke-ScriptAnalyzer -Path $Path -ExcludeRule PSAvoidTrailingWhitespace, PSShouldProcess
    }

    It "passes '<RuleName>" -TestCases $RulesToTest {
      If ($Analysis.RuleName -contains $RuleName) {
        $Analysis |
          Where-Object RuleName -EQ $RuleName -OutVariable Failures |
          ForEach-Object {
            $List.Add($PSItem)
          }
        1 | Should -Be 0
      } Else {
        0 | Should -Be 0
      }
    }
  }
}
