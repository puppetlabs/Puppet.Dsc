Describe 'Set-PSModulePath' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      $BackupPath = $Env:PSModulePath
    }

    AfterEach {
      $Env:PSModulePath = $BackupPath
    }

    It 'Updates the PSModulePath' {
      Set-PSModulePath -Path 'foo'
      $Env:PSModulePath | Should -BeExactly 'foo'
    }
    It 'Concatenates multiple paths' {
      Set-PSModulePath -Path @('foo', 'bar')
      $Env:PSModulePath | Should -BeExactly 'foo;bar'
    }
    It 'Only returns the initial path if specified' {
      Set-PSModulePath -Path 'foo' -ReturnInitialPath | Should -BeExactly $BackupPath
      Set-PSModulePath -Path 'bar' | Should -BeNullOrEmpty
    }
  }
}
