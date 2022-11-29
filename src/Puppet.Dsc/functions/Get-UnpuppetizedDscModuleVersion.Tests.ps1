Describe 'Get-UnpuppetizedDscModuleVersion' -Tag 'Unit' {
  BeforeDiscovery {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
  }

  Context 'Basic verification' {
    InModuleScope puppet.dsc {
      BeforeAll {
        $DscModules = @(
          [PSCustomObject]@{ Name = 'Foo' ; Releases = @('3.0.0', '2.1.0', '2.0.0', '1.2.3', '1.0.0') }
          [PSCustomObject]@{ Name = 'Bar' ; Releases = @('3.0.0', '2.1.0', '2.0.0', '1.2.3', '1.0.0') }
          [PSCustomObject]@{ Name = 'Baz' ; Releases = @('3.0.0', '2.1.0', '2.0.0', '1.2.3', '1.0.0') }
        )
        $ForgeModules = @(
          [PSCustomObject]@{ Name = 'Foo' ; Releases = @('2.1.0-0-0', '2.0.0-0-0', '1.2.3-0-0', '1.0.0-0-0') }
          [PSCustomObject]@{ Name = 'Bar' ; Releases = @('3.0.0-0-0', '2.1.0-0-1', '2.1.0-0-0', '2.0.0-0-0') }
        )
        Mock Get-PowerShellDscModule { return $DscModules }
        Mock Get-PowerShellDscModule -ParameterFilter { ![string]::IsNullOrEmpty($Name) } {
          return $DscModules | Where-Object -FilterScript { $_.Name -eq $Name -or $_.Name -in $Name }
        }
        Mock Get-PowerShellDscModule -ParameterFilter { ![string]::IsNullOrEmpty($Repository) } {
          return $DscModules | Where-Object -FilterScript { $_.Name -eq 'Foo' }
        }
        Mock Get-PowerShellDscModule -ParameterFilter { $Name -contains 'NoSuchModule' } {
          $Exception = New-Object System.Exception "No match was found for the specified search criteria and module name '$Name'. Try Get-PSRepository to see all available registered module repositories."
          $ErrorID = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage'
          $ErrorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
          $TargetObject = 'Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage'
          $ErrorRecord = New-Object Management.Automation.ErrorRecord $Exception, $ErrorID, $ErrorCategory, $TargetObject
          $ErrorRecord.ErrorDetails = $ErrorDetails
          $PSCmdlet.WriteError($ErrorRecord)
          return $DscModules | Where-Object -FilterScript { $_.Name -eq 'Foo' }
        }
        Mock Get-ForgeModuleInfo { return $ForgeModules | Where-Object -FilterScript { $_.Name -eq $Name } }
      }

      Context 'when only ForgeNameSpace is specified' {
        BeforeAll {
          $Result = Get-UnpuppetizedDscModuleVersion -ForgeNameSpace 'dsc'
        }
        It 'searches the PSGallery for all modules with DSC Resources' {
          Should -Invoke Get-PowerShellDscModule -Times 1 -Scope Context
        }
        It 'searches the forge for each discovered PowerShell module' {
          Should -Invoke Get-ForgeModuleInfo -Times 3 -Scope Context -ParameterFilter { $ForgeNameSpace -eq 'dsc' }
        }
        It 'returns the list of all versions of the modules which are not on the Forge' {
          $Result.Count | Should -Be 3
          $Result[0].Name | Should -Be 'Foo'
          $Result[0].Versions | Sort-Object -Descending | Should -Be @('3.0.0.0')
          $Result[1].Name | Should -Be 'Bar'
          $Result[1].Versions | Sort-Object -Descending | Should -Be @('1.2.3.0', '1.0.0.0')
          $Result[2].Name | Should -Be 'Baz'
          $Result[2].Versions | Sort-Object -Descending | Should -Be @('3.0.0.0', '2.1.0.0', '2.0.0.0', '1.2.3.0', '1.0.0.0')
        }
      }
      Context 'with the Name parameter' {
        It 'searches the PSGallery by name' {
          { Get-UnpuppetizedDscModuleVersion -ForgeNameSpace 'dsc' -Name 'Foo' } | Should -Not -Throw
          Should -Invoke Get-PowerShellDscModule -Times 1 -ParameterFilter { $Name -eq 'Foo' }
        }
        It 'can search for multiple modules at once' -Tag 'Me' {
          { Get-UnpuppetizedDscModuleVersion -ForgeNameSpace 'dsc' -Name 'Foo', 'Bar' } | Should -Not -Throw
          Should -Invoke Get-PowerShellDscModule -Times 1 -ParameterFilter { ($Name -join '') -eq 'FooBar' }
        }
        It 'errors if a named module cannot be found in the PSGallery without stopping processing' {
          $Result = Get-UnpuppetizedDscModuleVersion -ForgeNameSpace 'dsc' -Name 'Foo', 'NoSuchModule' -ErrorAction SilentlyContinue -ErrorVariable TestError
          $Result.Name | Should -Be 'Foo'
          $TestError[0].Exception.Message | Should -BeLike 'No match was found for the specified search criteria*'
        }
      }
      Context 'with the Repository parameter' {
        It 'searches the specified repository' {
          Get-UnpuppetizedDscModuleVersion -Repository 'MyRepository' -ForgeNameSpace 'dsc'
          Should -Invoke Get-PowerShellDscModule -ParameterFilter { $Repository -eq 'MyRepository' }
        }
      }
      Context 'with the ForgeSearchUri parameter' {
        It 'passes the specified URI to Get-ForgeModuleInfo' {
          Get-UnpuppetizedDscModuleVersion -ForgeSearchUri 'SomeUri' -ForgeNameSpace 'dsc'
          Should -Invoke Get-ForgeModuleInfo -ParameterFilter { $ForgeSearchUri -eq 'SomeUri' }
        }
      }
      Context 'with the MinimumVersion parameter' {
        It 'returns only unpublished versions newer than the specified one across all modules' {
          $Result = Get-UnpuppetizedDscModuleVersion -ForgeNameSpace 'dsc' -MinimumVersion '2.0.0'
          $Result.Count | Should -Be 2
          $Result[0].Name | Should -Be 'Foo'
          $Result[0].Versions | Sort-Object -Descending | Should -Be @('3.0.0.0')
          $Result[1].Name | Should -Be 'Baz'
          $Result[1].Versions | Sort-Object -Descending | Should -Be @('3.0.0.0', '2.1.0.0', '2.0.0.0')
        }
      }
      Context 'with the OnlyNewer parameter' {
        It 'returns only unpublished versions newer than any existing published version on the forge' {
          $Result = Get-UnpuppetizedDscModuleVersion -ForgeNameSpace 'dsc' -OnlyNewer
          $Result.Count | Should -Be 2
          $Result[0].Name | Should -Be 'Foo'
          $Result[0].Versions | Sort-Object -Descending | Should -Be @('3.0.0.0')
          $Result[1].Name | Should -Be 'Baz'
          $Result[1].Versions | Sort-Object -Descending | Should -Be @('3.0.0.0', '2.1.0.0', '2.0.0.0', '1.2.3.0', '1.0.0.0')
        }
      }
    }
  }
}
