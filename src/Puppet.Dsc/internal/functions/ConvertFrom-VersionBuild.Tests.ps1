Describe 'ConvertFrom-VersionBuild' -Tag 'Unit' {
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      $ValidVersionAndBuild = [PSCustomObject]@{
        Version = '1.2.3-4'
        Build   = '5'
      }
    }
    It 'Turns a VersionBuild object into a Puppet DSC Module Version String' {
      ConvertFrom-VersionBuild -VersionBuild $ValidVersionAndBuild |
        Should -Be '1.2.3-4-5'
    }
    It 'Takes input from the pipeline' {
      $ValidVersionAndBuild | ConvertFrom-VersionBuild |
        Should -Be '1.2.3-4-5'
    }
  }
}
