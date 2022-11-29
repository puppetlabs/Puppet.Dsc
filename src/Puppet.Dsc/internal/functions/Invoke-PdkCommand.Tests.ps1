Describe 'Invoke-PdkCommand' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'Basic verification' {
      BeforeAll {
        $Command = 'foo'
        $SuccessOutput = "Module 'Foo' generated at path"
        Mock Start-Job {
          [PSCustomObject]@{ID = 0 }
        }
        Mock Wait-Job {
          # Create a version of the job output that has only what we need for a "good" job
          return @{
            ChildJobs = [System.Collections.ArrayList]@(
              @{ Output = $SuccessOutput }
            )
          }
        }
      }
      It 'Throws if the path to call the PDK from cannot be resolved' {
        { Invoke-PdkCommand -Path TestDrive:\Foo -Command $Command -SuccessFilterScript { $_ -eq $SuccessOutput } } |
          Should -Throw "Cannot find path 'TestDrive:\Foo' because it does not exist."
      }
      It 'Throws the last error if the success filter script matches none of the PDK messages in Output' {
        Mock Wait-Job {
          # Create a version of the job output that has only what we need for a "bad" job with multiple messages
          return @{
            ChildJobs = [System.Collections.ArrayList]@(
              @{ Output = "Foo`nBar`nBaz`n" }
            )
          }
        }

        { Invoke-PdkCommand -Path TestDrive:\ -Command $Command -SuccessFilterScript { $_ -eq $SuccessOutput } } |
          Should -Throw -PassThru |
          Select-Object -ExpandProperty Exception | Should -Match 'Baz'
      }
      It 'Starts and waits for a job' {
        $null = Invoke-PdkCommand -Command $Command -SuccessFilterScript { $_ -eq $SuccessOutput }
        Should -Invoke -CommandName 'Start-Job'
        Should -Invoke -CommandName 'Wait-Job'
      }

      It 'Returns data if specified' {
        Invoke-PdkCommand -Command $Command -SuccessFilterScript { $_ -eq $SuccessOutput } | Should -BeNullOrEmpty
        Invoke-PdkCommand -Command $Command -SuccessFilterScript { $_ -eq $SuccessOutput } -PassThru | Should -Be $SuccessOutput
      }
    }
  }
}
