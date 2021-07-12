Describe 'ConvertTo-VersionBuild' -Tag 'Unit' {
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      $ValidPuppetVersion = '1.2.3-4-5'
      $Expected = [PSCustomObject]@{
        Version = '1.2.3-4'
        Build   = '5'
      }
    }
    It 'Turns a Puppet DSC Module Version string into a VersionBuild object' {
      $Result = ConvertTo-VersionBuild -Version $ValidPuppetVersion
      $Result | Should -BeOfType 'PSCustomObject'
      $Result.Version | Should -Be $Expected.Version
      $Result.Build | Should -Be $Expected.Build
    }
    It 'Takes input from the pipeline' -Pending {
      $Result = $ValidVersionAndBuild | ConvertTo-VersionBuild
      $Result | Should -BeOfType 'PSCustomObject'
      $Result.Version | Should -Be $Expected.Version
      $Result.Build | Should -Be $Expected.Build
    }
  }
}