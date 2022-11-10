Describe 'Get-DscResourceImplementation' -Tag 'Unit' {
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')

    # The using statement will fail without a correct module path;
    # The scriptblock in Start-Job can't see the Pester TestDrive,
    # so instead we need to point to a real module path.
    $TestModulePath = Get-Module -Name Pester | Select-Object -ExpandProperty Path

    $NonPowerShellDscResources = [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]@(
      @{ Name = 'foo' ; ImplementedAs = 'Binary' }
      @{ Name = 'bar' ; ImplementedAs = 'None' }
    )
    $PowerShellDscResources = [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]@(
      @{ Name = 'classy' ; ImplementedAs = 'PowerShell' ; Path = $TestModulePath }
      @{ Name = 'mofy' ; ImplementedAs = 'PowerShell' ; Path = $TestModulePath }
    )
  }

  Context 'when the Resource is passed explicitly' {
    BeforeEach {
      Mock Get-DscResource {}
    }

    It 'never calls Get-DscResource' {
      $null = $NonPowerShellDscResources | Get-DscResourceImplementation
      Should -Invoke Get-DscResource -Times 0 -Scope It
    }

    It 'processes once for each object in the pipeline' {
      $Result = $NonPowerShellDscResources | Get-DscResourceImplementation
      $Result.Count | Should -Be 2
    }
  }

  Context 'when the Resource is passed by name' {
    BeforeAll {
      Mock Get-DscResource {
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{ Name = $Name ; ImplementedAs = 'Binary' }
      }
    }
    It 'calls Get-DscResource by name' {
      $null = Get-DscResourceImplementation -Name 'foo'
      Should -Invoke Get-DscResource -Times 1 -Scope It
      Should -Invoke Get-DscResource -Times 1 -Scope It -ParameterFilter { $Name -eq 'foo' }
    }
  }

  Context 'when the Resource is passed by name and module' {
    BeforeAll {
      Mock Get-DscResource {
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{ Name = $Name ; ImplementedAs = 'Binary' }
      }
    }
    It 'calls Get-DscResource by name and module' {
      $null = Get-DscResourceImplementation -Name 'foo' -Module 'bar'
      Should -Invoke Get-DscResource -Times 1 -Scope It
      Should -Invoke Get-DscResource -Times 1 -Scope It -ParameterFilter { $Name -eq 'foo' -and $Module -eq 'bar' }
    }
  }

  Context "when the Resource's ImplementedAs value is not PowerShell" {
    It 'sets the resource implementation to the ImplementedAs value' {
      $Result = $NonPowerShellDscResources | Get-DscResourceImplementation
      $Result.Count | Should -Be 2
      $Result[0] | Should -Be 'Binary'
      $Result[1] | Should -Be 'None'
    }
  }

  Context "when the Resource's ImplementedAs value is PowerShell" {
    It 'starts and waits for a job once per resource' {
      $JobOutput = 'ScriptBlock Output'
      Mock Start-Job {
        [PSCustomObject]@{ID = 0 }
      }
      Mock Wait-Job {
        return @{
          ChildJobs = [System.Collections.ArrayList]@(
            @{ Output = $JobOutput }
          )
        }
      }

      $null = $PowerShellDscResources | Get-DscResourceImplementation
      Should -Invoke -CommandName 'Start-Job' -Times 2 -Scope It -ParameterFilter {
        $ScriptBlock.ToString() -match [Regex]::Escape("using module '$TestModulePath'")
        $ScriptBlock.ToString() -match "('classy'|'mofy') -as \[type\]"
      }
      Should -Invoke -CommandName 'Wait-Job' -Times 2 -Scope It
    }

    Context 'when the Resource is class-based' {
      It "sets the resource implementation to 'Class'" {
        # We actually want to run the scriptblock, so don't mock the *Job functions
        $DscResource = [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{
          # String isn't a DSC Resource, but it works for test purposes
          Name = 'String' ; ImplementedAs = 'PowerShell' ; Path = $TestModulePath
        }
        $DscResource | Get-DscResourceImplementation | Should -Be 'Class'
      }
    }

    Context 'when the Resource is MOF-based' {
      It "sets the resource implementation to 'MOF'" {
        # We actually want to run the scriptblock, so don't mock the *Job functions
        $DscResource = [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{
          Name = 'Mofy' ; ImplementedAs = 'PowerShell' ; Path = $TestModulePath
        }
        $DscResource | Get-DscResourceImplementation | Should -Be 'MOF'
      }
    }
  }

  Context 'when the ModifyResource switch is specified' {
    It 'adds the ResourceImplementation note property to the input resource' {
      $DscResource = [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]@{
        Name = 'Foo' ; ImplementedAs = 'Binary'
      }
      $null = $DscResource | Get-DscResourceImplementation -ModifyResource
      $DscResource.Name | Should -Be 'Foo'
      $DscResource.ResourceImplementation | Should -Be 'Binary'
    }
  }
}

