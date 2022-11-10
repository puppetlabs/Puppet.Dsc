Describe 'Validating the module manifest' -Tag @('Manifest', 'General') {
  BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    $Manifest = ((Get-Content "$moduleRoot\puppet.dsc.psd1") -join "`n") | Invoke-Expression
  }
  BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    $Manifest = ((Get-Content "$moduleRoot\puppet.dsc.psd1") -join "`n") | Invoke-Expression
  }

  Context 'Basic resources validation' {
    BeforeAll {
      $files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object { ($_.Name -like '*.ps1') -and ($_.Name -notmatch '\.Tests\.') }
    }

    It 'Exports all functions in the public folder' {
      $functions = (Compare-Object -ReferenceObject $files.BaseName -DifferenceObject $Manifest.FunctionsToExport | Where-Object SideIndicator -Like '<=').InputObject
      $functions | Should -BeNullOrEmpty
    }
    It "Exports no function that isn't also present in the public folder" {
      $functions = (Compare-Object -ReferenceObject $files.BaseName -DifferenceObject $Manifest.FunctionsToExport | Where-Object SideIndicator -Like '=>').InputObject
      $functions | Should -BeNullOrEmpty
    }
    It 'Exports none of its internal functions' {
      $files = Get-ChildItem "$moduleRoot\internal\functions" -Recurse -File -Filter '*.ps1'
      $files | Where-Object BaseName -In $Manifest.FunctionsToExport | Should -BeNullOrEmpty
    }
  }

  Context 'Individual file validation' {
    BeforeDiscovery {
      $FormatTestCases = New-Object -TypeName System.Collections.ArrayList
      ForEach ($Format in $Manifest.FormatsToProcess) {
        $FormatTestCases.Add(@{
            Format = $Format
            Path   = "$ModuleRoot\$Format"
          })
      }

      $TypeTestCases = New-Object -TypeName System.Collections.ArrayList
      ForEach ($Type in $Manifest.TypesToProcess) {
        $TypeTestCases.Add(@{
            Type = $Type
            Path = "$ModuleRoot\$Type"
          })
      }

      $DllTestCases = New-Object -TypeName System.Collections.ArrayList
      $GacTestCases = New-Object -TypeName System.Collections.ArrayList
      ForEach ($Assembly in $Manifest.AssemblysToProcess) {
        If ($Assembly -like '*.dll') {
          $DllTestCases.Add(@{
              Assembly = $Assembly
              Path     = "$ModuleRoot\$Assembly"
            })
        } Else {
          $GacTestCases.Add(@{
              Assembly = $Assembly
            })
        }
      }

      $TagTestCases = New-Object -TypeName System.Collections.ArrayList
      ForEach ($Tag in $Manifest.PrivateData.PSData.Tags) {
        $TagTestCases.Add(@{
            Tag = $Tag
          })
      }
    }

    It 'The root module file exists' {
      Test-Path "$moduleRoot\$($Manifest.RootModule)" | Should -Be $true
    }

    It 'The file <Format> should exist' -TestCases $FormatTestCases {
      Test-Path $Path | Should -Be $true
    }

    It 'The file <Type> should exist' -TestCases $TypeTestCases {
      Test-Path $Path | Should -Be $true
    }

    It 'The file <Assembly> should exist' -TestCases $DllTestCases {
      Test-Path $Path | Should -Be $true
    }

    It 'The <Assembly> should load from the GAC' -TestCases $GacTestCases {
      { Add-Type -AssemblyName $Assembly } | Should -Not -Throw
    }

    It "The tag '<Tag>' should have no spaces in name" -TestCases $TagTestCases {
      $tag -match '\s' | Should -Be $false
    }
  }
}
