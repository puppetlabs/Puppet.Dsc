Describe 'Publish-NewDscModuleVersion' -Tag 'Unit' {
  BeforeDiscovery {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
  }

  InModuleScope puppet.dsc {
    Context 'Basic verification' {
      BeforeAll {
        $UnpuppetizedModuleVersions = @(
          [PSCustomObject]@{ Name = 'Foo' ; Versions = @('1.2.3.0', '1.2.0.0', '1.1.0.0', '1.0.0.0') }
          [PSCustomObject]@{ Name = 'Bar' ; Versions = @('2.1.0.0', '2.0.0.0', '1.1.0.0', '0.1.0.0') }
          [PSCustomObject]@{ Name = 'Baz' ; Versions = @('2.0.0.0', '1.0.0.0', '0.1.0.0') }
        )
        $UnpuppetizedModuleVersionsNewerOnly = @(
          [PSCustomObject]@{ Name = 'Foo' ; Versions = @('1.2.3.0', '1.2.0.0', '1.1.0.0', '1.0.0.0') }
          [PSCustomObject]@{ Name = 'Bar' ; Versions = @('2.1.0.0', '2.0.0.0') }
          [PSCustomObject]@{ Name = 'Baz' ; Versions = @('2.0.0.0') }
        )
        Mock Get-UnpuppetizedDscModuleVersion { return $UnpuppetizedModuleVersions }
        Mock Get-UnpuppetizedDscModuleVersion -ParameterFilter { $OnlyNewer.IsPresent } {
          return $UnpuppetizedModuleVersionsNewerOnly
        }
        Mock Get-UnpuppetizedDscModuleVersion -ParameterFilter { $MinimumVersion -match '^2\.0$' } {
          return @(
            [PSCustomObject]@{ Name = 'Bar' ; Versions = @('2.1.0.0', '2.0.0.0') }
            [PSCustomObject]@{ Name = 'Baz' ; Versions = @('2.0.0.0') }
          )
        }
        Mock Get-UnpuppetizedDscModuleVersion -ParameterFilter { ![string]::IsNullOrEmpty($Name) } {
          If ($Name.Count -gt 1) {
            return $ForgeModules | Where-Object -FilterScript { $_.Name -in $Name }
          } Else {
            return $ForgeModules | Where-Object -FilterScript { $_.Name -eq $Name }
          }
        }
        Mock Get-UnpuppetizedDscModuleVersion -ParameterFilter { $ForgeNameSpace -eq 'EmptyNameSpace' } {}
        # Pester equivalent of mock-and-call-original
        Mock Get-PuppetizedModuleName {
          $GetPuppetizedModuleNameFunction = Get-Command Get-PuppetizedModuleName -CommandType Function
          return & $GetPuppetizedModuleNameFunction -Name $Name
        }
        Mock New-PuppetDscModule {
          return [PSCustomObject]@{ FullName = "TestDrive:\import\$(Get-PuppetizedModuleName -Name $PowerShellModuleName)\" }
        }
        Mock Get-Content { @{ version = '1.2.3-0-0' } | ConvertTo-Json }
        Mock Publish-PuppetModule
        Mock Write-PSFMessage
        Mock Stop-PSFFunction

        Publish-NewDscModuleVersion -ForgeNameSpace 'foo'
      }

      It 'requires the ForgeNameSpace parameter' {
        $Command = Get-Command Publish-NewDscModuleVersion
        $Command.Parameters.ForgeNameSpace.Attributes |
          Where-Object -FilterScript { $_.TypeId.Name -eq 'ParameterAttribute' } |
          Select-Object -ExpandProperty Mandatory -Unique | Should -Be $true
      }

      It 'searches for unpuppetized DSC Modules' {
        Should -Invoke Get-UnpuppetizedDscModuleVersion -Scope Context -Times 1 -ParameterFilter { $ForgeNameSpace -eq 'foo' }
      }

      It 'puppetizes each unreleased version only once' {
        Should -Invoke New-PuppetDscModule -Scope Context -Times 4 -ParameterFilter { $PowerShellModuleName -eq 'Foo' }
        Should -Invoke New-PuppetDscModule -Scope Context -Times 11
      }

      It 'builds and publishes each unreleased version' {
        Should -Invoke Publish-PuppetModule -Scope Context -Times 4 -ParameterFilter { $PuppetModuleFolderPath -match 'foo' }
        Should -Invoke Publish-PuppetModule -Scope Context -Times 11
      }

      Context 'when something goes wrong' {
        BeforeAll {
          Mock Get-UnpuppetizedDscModuleVersion -ParameterFilter { $ForgeNameSpace -eq 'will_error' } {
            return [PSCustomObject]@{
              Name     = 'WillError'
              Versions = @('1.2.3.0')
            }
          }
          Mock New-PuppetDscModule -ParameterFilter { $PowerShellModuleName -eq 'WillError' } {
            Throw 'Error! Here are some details.'
          }
        }

        It 'calls Stop-PSFunction for error-handling' {
          Publish-NewDscModuleVersion -ForgeNameSpace 'will_error'
          Should -Invoke Stop-PSFFunction -ParameterFilter {
            $Message -match 'WillError' -and
            $Message -match '1.2.3.0' -and
            $ErrorRecord -match 'Error!'
          }
        }

        It 'calls Stop-PSFunction with EnableException if ErrorAction is "Stop"' {
          Publish-NewDscModuleVersion -ForgeNameSpace 'will_error' -ErrorAction Stop
          Should -Invoke Stop-PSFFunction -ParameterFilter {
            $EnableException -eq $True
          }
        }
      }

      Context 'when the Name parameter is specified' {
        It 'searches for modules to update by Name' {
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -Name 'foo'
          Should -Invoke Get-UnpuppetizedDscModuleVersion -Times 1 -ParameterFilter { $Name -eq 'foo' }
        }
      }

      Context 'when the ForgeApiUri parameter is specified' -Tag 'api' {
        BeforeAll {
          $TestForgeApiUri = 'https://myforge.acme.inc/v3'
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -ForgeApiUri $TestForgeApiUri
        }

        It 'passes the specified URI for search' {
          Should -Invoke Get-UnpuppetizedDscModuleVersion -Scope Context -Times 1 -ParameterFilter { $ForgeSearchUri -eq "$TestForgeApiUri/modules" }
        }

        It 'passes the specified URI for publish' {
          Should -Invoke Publish-PuppetModule -Scope Context -Times 1 -ParameterFilter { $ForgeUploadUrl -eq "$TestForgeApiUri/releases" }
        }
      }

      Context 'when the ForgeToken parameter is specified' {
        BeforeAll {
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -ForgeToken 'MyToken' -Verbose
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
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -BuildFolder 'TestDrive:\import'
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
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -PackageFolderPath 'TestDrive:\packages'
          Should -Invoke Publish-PuppetModule -ParameterFilter { $ExportFolderPath -eq 'TestDrive:\packages' }
        }
      }

      Context 'when the OnlyNewer parameter is specified' {
        It 'only puppetizes and releases versions newer than any published to the Forge' {
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -OnlyNewer
          Should -Invoke Get-UnpuppetizedDscModuleVersion -ParameterFilter { $OnlyNewer.IsPresent -eq $true }
        }
      }

      Context 'when the MinimumVersion parameter is specified' {
        It 'only puppetizes and releases versions greater than or equal to the value specified' {
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -MinimumVersion '1.0.0'
          Should -Invoke Get-UnpuppetizedDscModuleVersion -ParameterFilter { $MinimumVersion -eq '1.0.0' }
        }
      }

      Context 'when the MaxBuildCount parameter is specified' {
        It 'only puppetizes and releases a number of modules up to the specified value' {
          Publish-NewDscModuleVersion -ForgeNameSpace 'foo' -MaxBuildCount 5
          Should -Invoke Get-UnpuppetizedDscModuleVersion -Times 1
          Should -Invoke New-PuppetDscModule -Times 5
          Should -Invoke Publish-PuppetModule -Times 5
        }
      }
    }
  }
}
