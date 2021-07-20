Describe 'Get-PowerShellDscModule' -Tag 'Unit' {
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      $Modules = @(
        [PSCustomObject]@{ Name = 'Foo' ; Version = [version]'1.2.3' }
        [PSCustomObject]@{ Name = 'Foo' ; Version = [version]'1.2.4' }
        [PSCustomObject]@{ Name = 'Bar' ; Version = [version]'1.0.0' }
      )
      Mock Find-Module -ParameterFilter { $Name -eq '*' } {
        return $Modules
      }
      Mock Find-Module -ParameterFilter { $Name -ne '*' } {
        return $Modules | Where-Object -FilterScript { $_.Name -eq $Name }
      }
    }
    Context 'when Name is specified' {
      It 'searches only for the specified modules' {
        $Result = Get-PowerShellDscModule -Name 'Bar'
        $Result.Name | Should -Be 'Bar'
        $Result.Releases | Should -Be '1.0.0'
        Assert-MockCalled Find-Module -ParameterFilter { $Name -eq '*' } -Times 0
        Assert-MockCalled Find-Module -ParameterFilter { $Name -ne '*' } -Times 1
      }
    }
    Context 'when Name is not specified' {
      It 'retrieves all modules with DSC resources' {
        $Result = Get-PowerShellDscModule
        $Result.Count | Should -Be 3
        $Result.Name | Select-Object -Unique | Sort-Object | Should -Be @('Bar', 'Foo')
        Assert-MockCalled Find-Module -ParameterFilter { $Name -eq '*' -and $DscResource -eq '*' } -Times 1
        Assert-MockCalled Find-Module -ParameterFilter { $Name -eq 'Foo' } -Times 1
        Assert-MockCalled Find-Module -ParameterFilter { $Name -eq 'Bar' } -Times 1
      }
    }
  }
}
