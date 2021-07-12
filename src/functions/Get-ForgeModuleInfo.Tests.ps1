Describe 'Get-ForgeModuleInfo' -Tag 'Unit' {
  BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')

    Function New-ModuleInfo {
      Param(
        [string]$Name,
        [string[]]$Releases
      )

      [PSCustomObject]@{
        name            = $Name.ToLowerInvariant()
        releases        = $Releases | ForEach-Object -Process { @{ version = $_ } }
        current_release = @{
          metadata = @{
            dsc_module_metadata = "SomeMetadata for $Name"
          }
        }
      }
    }

    Function New-ForgeResponse {
      Param(
        [PSCustomObject[]]$Results,
        $NextPagination = 'more'
      )

      [PSCustomObject]@{
        results    = $Results
        Pagination = @{ Next = $NextPagination }
      }
    }
  }

  Context 'Basic verification' {
    Context 'when the Name parameter is specified' {
      BeforeAll {
        $FooModuleInfo = New-ModuleInfo -Name 'Foo' -Releases '1.2.3-0-1', '1.2.3-0-0', '1.2.2-0-0'

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
          $PSCmdlet.WriteError($ErrorRecord)
        }
      }
      It 'searches for the specified module on the forge' {
        $Result = Get-ForgeModuleInfo -Name 'Foo'
        $Result.Name | Should -Be 'foo'
        $Result.Releases | Should -Be @('1.2.3-0-1', '1.2.3-0-0', '1.2.2-0-0')
        $Result.PowerShellModuleInfo | Should -Be 'SomeMetadata for Foo'
        Should -Invoke Invoke-RestMethod -ParameterFilter { $Uri -match 'dsc-foo' } -Times 1
      }
      It 'errors if the module cannot be found' {
        { Get-ForgeModuleInfo -Name 'Bar' -ErrorAction Stop } | Should -Throw
      }
    }
    Context 'when the Name parameter is not specified' {
      BeforeAll {
        Mock Invoke-RestMethod -ParameterFilter { $Body.offset -eq 0 } {
          $Module = New-ModuleInfo -Name 'Foo' -Releases '1.2.3-0-1', '1.2.3-0-0', '1.2.2-0-0'
          return New-ForgeResponse -Results @($Module)
        }
        Mock Invoke-RestMethod -ParameterFilter { $Body.offset -eq 1 } {
          $Module = New-ModuleInfo -Name 'Bar' -Releases '1.2.3-0-1'
          return New-ForgeResponse -Results @($Module)
        }
        Mock Invoke-RestMethod -ParameterFilter { $Body.offset -eq 2 } {
          $Module = New-ModuleInfo -Name 'Baz' -Releases '1.2.3-0-1'
          return New-ForgeResponse -Results @($Module) -NextPagination $null
        }
      }

      It 'searches the namespace for all modules' -Pending {
        $Result = Get-ForgeModuleInfo -PaginationBump 1
        $Result.Count | Should -Be 3
        $Result[0].Name | Should -Be 'foo'
        $Result[0].Releases | Should -Be @('1.2.3-0-1', '1.2.3-0-0', '1.2.2-0-0')
        $Result[0].PowerShellModuleInfo | Should -Be 'SomeMetadata for Foo'
        Should -Invoke Invoke-RestMethod -ParameterFilter { $Body.owner -eq 'dsc' } -Times 3
      }
    }
  }
}
