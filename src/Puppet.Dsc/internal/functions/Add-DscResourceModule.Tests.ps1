Describe 'Add-DscResourceModule' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')

    Mock New-Item -Verifiable
    Mock Save-Module -Verifiable
    Mock Test-Path { $false } -ParameterFilter { $path -eq 'TestDrive:\target\' }
    Mock Test-Path { $false } -ParameterFilter { $path -eq 'TestDrive:\target_tmp' }
    Mock Get-Module
    Mock Get-ChildItem
    Mock Move-Item
    Mock Remove-Item
    Mock Copy-Item
    $SharedParameters = @{
      Name            = 'SomeDSCModule'
      Path            = 'TestDrive:\target\'
      RequiredVersion = '1.0.0'
      Repository      = 'PSGallery'
    }
  }
  Context 'Without AllowPrerelease specified' {
    It 'downloads the latest stable version of the module' {
      { Add-DscResourceModule @SharedParameters } | Should -Not -Throw
      Should -InvokeVerifiable
      Should -Invoke New-Item -Times 1 -Scope It -ParameterFilter { ($path -eq 'TestDrive:\target\') -and ($ItemType -eq 'Directory') }
      Should -Invoke New-Item -Times 1 -Scope It -ParameterFilter { ($path -eq 'TestDrive:\target_tmp') -and ($ItemType -eq 'Directory') }
      Should -Invoke Save-Module -Times 1 -Scope It -ParameterFilter {
        ($Name -eq 'SomeDSCModule') `
          -and ($path -eq 'TestDrive:\target_tmp') `
          -and ($RequiredVersion -eq '1.0.0') `
          -and ($Repository -eq 'PSGallery')
      }
      Should -Invoke Remove-Item -Times 1 -Scope It -ParameterFilter { $path -eq 'TestDrive:\target_tmp' }
    }
  }
  Context 'With AllowPrerelease specified' {
    It 'downloads the absolute latest version of the module' {
      { Add-DscResourceModule @SharedParameters -AllowPrerelease } | Should -Not -Throw
      Should -Invoke Save-Module -Times 1 -Scope It -ParameterFilter {
        ($Name -eq 'SomeDSCModule') `
          -and ($path -eq 'TestDrive:\target_tmp') `
          -and ($RequiredVersion -eq '1.0.0') `
          -and ($Repository -eq 'PSGallery') `
          -and ($AllowPrerelease -eq $true)
      }
    }
  }
  Context 'When a required module is found in the repository' {
    BeforeAll {
      Mock Test-Path { $true } -ParameterFilter { $path -match 'foo' }
      Mock Get-Module { @{ RequiredModules = @('foo') } } -ParameterFilter { $Name -match 'SomeDscModule' }
    }
    It 'sees that the required module is vendored' {
      { Add-DscResourceModule @SharedParameters } | Should -Not -Throw
      Should -Invoke Test-Path -Times 1 -Scope It -ParameterFilter { $Path -match 'foo' }
      Should -Invoke Get-Module -Times 0 -Scope It -ParameterFilter { $Name -eq 'foo' }
      Should -Invoke Copy-Item -Times 0 -Scope It
    }
  }
  Context 'When a required module is not found in the repository' {
    BeforeAll {
      Mock Test-Path { $false } -ParameterFilter { $path -match 'foo' }
      Mock Get-Module { @{ RequiredModules = @('foo') } } -ParameterFilter { $Name -match 'SomeDscModule' }
      Mock Get-Module { @{ Path = 'TestDrive:\target_tmp\foo\foo.psd1' } } -ParameterFilter { $Name -match 'foo' }
    }
    It 'Copies the module from the local system when available' {
      { Add-DscResourceModule @SharedParameters } | Should -Not -Throw
      Should -Invoke Test-Path -Times 1 -Scope It -ParameterFilter { $Path -match 'foo' }
      Should -Invoke Get-Module -Times 1 -Scope It -ParameterFilter { $Name -eq 'foo' }
      Should -Invoke Copy-Item -Times 1 -Scope It -ParameterFilter {
        ($Path -match 'foo') `
          -and ($Destination -eq 'TestDrive:\target_tmp') `
          -and ($Container -eq $true) `
          -and ($Recurse -eq $true)
      }
    }
  }
}
