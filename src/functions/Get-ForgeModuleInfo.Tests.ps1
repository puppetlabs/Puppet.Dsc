Describe 'Get-ForgeModuleInfo' -Tag 'Unit' {
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      $FooModuleInfo = @(
        [PSCustomObject]@{
          name            = 'foo'
          releases        = @(
            @{Version = '1.2.3-0-1' }
            @{Version = '1.2.3-0-0' }
            @{Version = '1.2.2-0-0' }
          )
          current_release = @{
            metadata = @{
              dsc_module_metadata = 'SomeMetadata'
            }
          }
        }
      )
      Mock Invoke-RestMethod -ParameterFilter { $Uri -match 'dsc-foo' } {
        return $FooModuleInfo
      }
      Mock Invoke-RestMethod -ParameterFilter { $Name -match 'dsc-bar' } {
        $Exception = New-Object System.Net.WebException 'The remote server returned an error: (404) Not Found.'
        $ErrorID = 'WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeRestMethodCommand'
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
        $TargetObject = 'System.Net.HttpWebRequest'
        $ErrorRecord = New-Object Management.Automation.ErrorRecord $Exception, $ErrorID, $ErrorCategory, $TargetObject
        $ErrorRecord.ErrorDetails = $ErrorDetails
        Write-Error $ErrorRecord
      }
    }
    It 'searches for the specified module on the forge' {
      $Result = Get-ForgeModuleInfo -Name 'Foo'
      $Result.Name | Should -Be 'foo'
      $Result.Releases | Should -Be @('1.2.3-0-1', '1.2.3-0-0', '1.2.2-0-0')
      $Result.PowerShellModuleInfo | Should -Be 'SomeMetadata'
      Assert-MockCalled Invoke-RestMethod -ParameterFilter { $Uri -match 'dsc-foo' } -Times 1
    }
    It 'errors if the module cannot be found' {
      { Get-ForgeModuleInfo -Name 'Bar' -ErrorAction Stop } | Should -Throw
    }
  }
}
