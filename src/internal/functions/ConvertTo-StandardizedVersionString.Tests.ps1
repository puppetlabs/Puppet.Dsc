Describe 'ConvertTo-StandardizedVersionString' -Tag 'Unit' {
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      $Version = [version]'1.2'
      $Expected = '1.2.0.0'
    }
    It 'Turns a Version object into a four-segment version string' {
      ConvertTo-StandardizedVersionString -Version $Version |
        Should -Be $Expected
    }
    It 'Takes input from the pipeline' {
      $Result = $Version | ConvertTo-StandardizedVersionString |
        Should -Be $Expected
    }
  }
}