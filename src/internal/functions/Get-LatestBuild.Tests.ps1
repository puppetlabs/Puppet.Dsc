Describe 'Get-LatestBuild' -Tag 'Unit' {
  BeforeDiscovery {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
  }

  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    Context 'Basic verification' {
      BeforeAll {
        $Versions = @('1.2.3-0-0', '1.2.3-0-1', '1.2.4-0-0', '1.2.2-5-0')
        $VersionAndBuilds = @(
          [PSCustomObject]@{Version = '1.2.3-0' ; Build = '0' }
          [PSCustomObject]@{Version = '1.2.3-0' ; Build = '1' }
          [PSCustomObject]@{Version = '1.2.3-0' ; Build = '2' }
          [PSCustomObject]@{Version = '1.2.3-0' ; Build = '3' }
        )
        $Expected = @(
          [PSCustomObject]@{Version = '1.2.3-0' ; Build = '3' }
        )
        Mock ConvertTo-VersionBuild { return $VersionAndBuilds }
      }
      It 'Returns a VersionBuild object representing the latest build' {
        $Result = Get-LatestBuild -Version $Versions
        $Result | Should -BeOfType 'PSCustomObject'
        $Result.Version | Should -Be $Expected.Version
        $Result.Build | Should -Be $Expected.Build
        Assert-MockCalled -CommandName ConvertTo-VersionBuild -Times 1 -Scope It
      }
      It 'Takes input from the pipeline' -Pending {
        $Result = $Version | Get-LatestBuild
        $Result | Should -BeOfType 'PSCustomObject'
        $Result.Version | Should -Be $Expected.Version
        $Result.Build | Should -Be $Expected.Build
        Assert-MockCalled -CommandName ConvertTo-VersionBuild -Times 1 -Scope It
      }
    }
  }
}