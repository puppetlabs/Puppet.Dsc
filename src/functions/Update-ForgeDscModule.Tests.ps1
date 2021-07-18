Describe 'Update-ForgeDscModule' -Tag 'Unit' {
  BeforeDiscovery {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
  }

  InModuleScope puppet.dsc {
    Context 'Basic verification' {
      BeforeAll {
        $ForgeModules = @(
          [PSCustomObject]@{
            Name                 = 'foo'
            Releases             = @('1.2.3-0-1', '1.2.3-0-0', '1.2.0-0-0', '1.1.0-0-0')
            PowerShellModuleInfo = @{ Name = 'Foo' }
          }
          [PSCustomObject]@{
            Name                 = 'bar'
            Releases             = @('2.1.0-0-0', '2.0.0-0-0', '1.2.0-0-0', '1.1.0-0-0')
            PowerShellModuleInfo = @{ Name = 'Bar' }
          }
          [PSCustomObject]@{
            Name                 = 'baz'
            Releases             = @('2.1.0-0-0', '2.0.0-0-0', '1.0.0-0-0', '0.1.0-0-0')
            PowerShellModuleInfo = @{ Name = 'Baz' }
          }
        )
        Mock Get-ForgeModuleInfo { return $ForgeModules }
        Mock Get-ForgeModuleInfo -ParameterFilter { ![string]::IsNullOrEmpty($Name) } {
          If ($ForgeModules.Count -gt 1) {
            return $ForgeModules | Where-Object -FilterScript { $_.Name -in $Name }
          } Else {
            return $ForgeModules | Where-Object -FilterScript { $_.Name -eq $Name }
          }
        }
        Mock Get-ForgeModuleInfo -ParameterFilter { $ForgeNameSpace -eq 'EmptyNameSpace' } {}
        # Pester equivalent of mock-and-call-original
        Mock ConvertTo-StandardizedVersionString {
          $GetLatestBuildFunction = Get-Command ConvertTo-StandardizedVersionString -CommandType Function
          return & $GetLatestBuildFunction -Version $Version
        }
        # Pester equivalent of mock-and-call-original
        Mock Get-LatestBuild {
          $GetLatestBuildFunction = Get-Command Get-LatestBuild -CommandType Function
          return & $GetLatestBuildFunction -Version $Version
        }
        Mock New-PuppetDscModule {
          return [PSCustomObject]@{ FullName = "TestDrive:\import\$(Get-PuppetizedModuleName -Name $PowerShellModuleName)\" }
        }
        Mock Set-PuppetModuleVersion
        Mock Publish-PuppetModule
        Mock Write-PSFMessage
        Mock Stop-PSFFunction
        Mock Start-Sleep
        Update-ForgeDscModule -ForgeNameSpace 'foo'
      }

      It 'requires the ForgeNameSpace parameter' {
        $Command = Get-Command Update-ForgeDscModule
        $Command.Parameters.ForgeNameSpace.Attributes |
          Where-Object -FilterScript { $_.TypeId.Name -eq 'ParameterAttribute' } |
          Select-Object -ExpandProperty Mandatory -Unique | Should -Be $true
      }

      It 'searches the specified Forge namespace for released modules' {
        Should -Invoke Get-ForgeModuleInfo -Scope Context -Times 1 -ParameterFilter { $ForgeNameSpace -eq 'foo' }
      }

      It 'puppetizes each released version only once' {
        Should -Invoke New-PuppetDscModule -Scope Context -Times 3 -ParameterFilter { $PowerShellModuleName -eq 'Foo' }
        Should -Invoke New-PuppetDscModule -Scope Context -Times 11
      }

      It 'builds and puppetizes each released version with the updated build number' {
        Should -Invoke Set-PuppetModuleVersion -Scope Context -Times 1 -ParameterFilter { $Version -match '-2$' }
        Should -Invoke Set-PuppetModuleVersion -Scope Context -Times 10 -ParameterFilter { $Version -match '-1$' }
      }

      Context 'when something goes wrong' {
        BeforeAll {
          Mock Get-ForgeModuleInfo -ParameterFilter { $ForgeNameSpace -eq 'will_error' } {
            return [PSCustomObject]@{
              Name                 = 'will_error'
              Releases             = @('1.2.3-0-0')
              PowerShellModuleInfo = @{ Name = 'WillError' }
            }
          }
          Mock New-PuppetDscModule -ParameterFilter { $PowerShellModuleName -eq 'WillError' } {
            Throw 'Error! Here are some details.'
          }
        }

        It 'calls Stop-PSFunction for error-handling' {
          Update-ForgeDscModule -ForgeNameSpace 'will_error'
          Should -Invoke Stop-PSFFunction -ParameterFilter {
            $Message -match 'will_error' -and $Message -match '1.2.3-0'
          }
        }

        It 'calls Stop-PSFunction with EnableException if ErrorAction is "Stop"' {
          Update-ForgeDscModule -ForgeNameSpace 'will_error' -ErrorAction Stop
          Should -Invoke Stop-PSFFunction -ParameterFilter {
            $EnableException -eq $True
          }
        }

        Context 'when the SleepAfterFailure parameter is specified' {
          It 'sleeps for the specified duration before the next iteration' {
            Update-ForgeDscModule -ForgeNameSpace 'will_error' -SleepAfterFailure 5
            Should -Invoke Start-Sleep -ParameterFilter {
              $Seconds -eq 5
            }
          }
        }
      }

      Context 'when the Name parameter is specified' {
        It 'searches for modules to update by Name' {
          Update-ForgeDscModule -ForgeNameSpace 'foo' -Name 'foo'
          Should -Invoke Get-ForgeModuleInfo -Times 1 -ParameterFilter { $Name -eq 'foo' }
        }
      }

      Context 'when the Version parameter is specified' {
        It 'requires exactly one Name to be passed' {
          { Update-ForgeDscModule -ForgeNameSpace 'foo' -Name 'foo', 'bar' -Version '1.2.3' } | Should -Throw 'Specified a Version with multiple Names*'
          Should -Invoke New-PuppetDscModule -Times 0
        }
        It 'filters the list of ReleasesToRebuild to match only the specified Version' {
          Update-ForgeDscModule -ForgeNameSpace 'foo' -Name 'foo' -Version '1.2.3'
          Should -Invoke New-PuppetDscModule -Times 1 -ParameterFilter { $PowerShellModuleVersion -eq '1.2.3.0' }
          Should -Invoke New-PuppetDscModule -Times 0 -ParameterFilter { $PowerShellModuleVersion -ne '1.2.3.0' }
        }
      }

      Context 'when the ForgeApiUri parameter is specified' -Tag 'api' {
        BeforeAll {
          $TestForgeApiUri = 'https://myforge.acme.inc/v3'
          Update-ForgeDscModule -ForgeNameSpace 'foo' -ForgeApiUri $TestForgeApiUri
        }

        It 'passes the specified URI for search' {
          Should -Invoke Get-ForgeModuleInfo -Scope Context -Times 1 -ParameterFilter { $ForgeSearchUri -eq "$TestForgeApiUri/modules" }
        }

        It 'passes the specified URI for publish' {
          Should -Invoke Publish-PuppetModule -Scope Context -Times 1 -ParameterFilter { $ForgeUploadUrl -eq "$TestForgeApiUri/releases" }
        }
      }

      Context 'when the ForgeToken parameter is specified' {
        BeforeAll {
          Update-ForgeDscModule -ForgeNameSpace 'foo' -ForgeToken 'MyToken' -Verbose
        }

        It 'passes the token to Publish-PuppetModule' {
          Should -Invoke Publish-PuppetModule -Scope Context -Times 1 -ParameterFilter { $ForgeToken -eq 'MyToken' }
        }

        It 'does not leak the token in logging' {
          Should -Invoke Write-PSFMessage -Scope Context
          Should -Invoke Write-PSFMessage -Scope Context -Times 0 -ParameterFilter { $Message -match 'MyToken' }
        }
      }

      Context 'when the BuildFolderPath parameter is specified' {
        BeforeAll {
          Update-ForgeDscModule -ForgeNameSpace 'foo' -BuildFolder 'TestDrive:\import'
        }

        It 'passes the path as the OutputDirectory to New-PuppetDscModule' {
          Should -Invoke New-PuppetDscModule -Scope Context -ParameterFilter { $OutputDirectory -eq 'TestDrive:\import' }
        }

        It 'leverages the path for Publish-PuppetModule' {
          Should -Invoke Publish-PuppetModule -Scope Context -ParameterFilter { $PuppetModuleFolderPath -match '^TestDrive:\\import' }
        }
      }

      Context 'when the PackageFolderPath parameter is specified' {
        It 'passes the path as the ExportFolderPath to Publish-PuppetModule' {
          Update-ForgeDscModule -ForgeNameSpace 'foo' -PackageFolderPath 'TestDrive:\packages'
          Should -Invoke Publish-PuppetModule -ParameterFilter { $ExportFolderPath -eq 'TestDrive:\packages' }
        }
      }

      Context 'when the LatestMajorVersionOnly parameter is specified' {
        It 'only updates module releases for the latest major version' {
          Update-ForgeDscModule -ForgeNameSpace 'foo' -LatestMajorVersionOnly
          Should -Invoke New-PuppetDscModule -Times 2 -ParameterFilter { $PowerShellModuleName -eq 'Bar' -and $PowerShellModuleVersion -match '^2\.' }
          Should -Invoke New-PuppetDscModule -Times 0 -ParameterFilter { $PowerShellModuleName -eq 'Bar' -and $PowerShellModuleVersion -notmatch '^2\.' }
        }
      }

      Context 'when the MaximumVersionCountToRebuild parameter is specified' {
        It 'only updates up to the specified number of releases for each module' {
          Update-ForgeDscModule -ForgeNameSpace 'foo' -MaximumVersionCountToRebuild 1
          Should -Invoke New-PuppetDscModule -Times 3
          Should -Invoke New-PuppetDscModule -Times 1 -ParameterFilter { $PowerShellModuleName -eq 'Foo' }
          Should -Invoke New-PuppetDscModule -Times 1 -ParameterFilter { $PowerShellModuleName -eq 'Bar' }
          Should -Invoke New-PuppetDscModule -Times 1 -ParameterFilter { $PowerShellModuleName -eq 'Baz' }
        }
      }
    }
  }
}
