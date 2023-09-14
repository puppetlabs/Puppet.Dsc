Describe 'New-PuppetDscModule' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope puppet.dsc {
    Context 'Basic Functionality' {
      BeforeAll {
        Mock Get-PuppetizedModuleName { $Name.ToLowerInvariant() }
        Mock ConvertTo-CanonicalPuppetAuthorName { $AuthorName }
        Mock Initialize-PuppetModule {}
        Mock Write-PSFMessage {}
        Mock Test-WSMan {}
        Mock Test-RunningElevated { return $true }
        Mock Test-SymLinkedItem { return $false }
        Mock Add-DscResourceModule {}
        Mock Resolve-Path { $Path }
        Mock Update-PuppetModuleMetadata {}
        Mock Update-PuppetModuleFixture {}
        Mock Update-PuppetModuleReadme {}
        Mock Update-PuppetModuleChangelog {}
        Mock Set-PSModulePath {}
        Mock Get-DscResource {
          [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]@(
            @{Name = 'FooResource' }
            @{Name = 'BarResource' }
          )
        }
        Mock ConvertTo-PuppetResourceApi {
          $Name = $DscResource.Name.toLower()
          [pscustomobject]@{
            Name         = $Name
            RubyFileName = "$Name.rb"
            Type         = "$Name type"
            Provider     = "$Name provider"
          }
        }
        Mock Test-Path { $true }
        Mock Out-Utf8File {}
        Mock Invoke-BundleInstall {}
        Mock Add-PuppetReferenceDocumentation {}
        Mock Get-Item {}

        $ExpectedOutputDirectory = Join-Path -Path (Get-Location) -ChildPath 'import'
      }
      Context 'Elevated' {
        It 'does not throw' {
          { New-PuppetDscModule -PowerShellModuleName Foo } | Should -Not -Throw
        }

        It 'Does not canonicalize the author name because none was specified' {
          Should -Invoke ConvertTo-CanonicalPuppetAuthorName -Times 0 -Scope Context
        }
        It 'Scaffolds the initial Puppet module' {
          Should -Invoke Initialize-PuppetModule -ParameterFilter {
            $OutputFolderPath -eq $ExpectedOutputDirectory -and
            $PuppetModuleName -ceq 'foo'
          } -Times 1 -Scope Context
        }
        It 'Vendors the PowerShell module' {
          Should -Invoke Add-DscResourceModule -ParameterFilter {
            $Name -ceq 'Foo' -and
            $Path -match 'import(/|\\)foo' -and
            $Repository -match 'PSGallery'
          } -Times 1 -Scope Context
        }
        It 'Updates the Puppet metadata based on the PowerShell metadata' {
          Should -Invoke Update-PuppetModuleMetadata -ParameterFilter {
            $PuppetModuleFolderPath -match 'import(/|\\)foo' -and
            $PowerShellModuleManifestPath -match 'import(/|\\)foo\S+(/|\\)foo(/|\\)foo.psd1'
          } -Scope Context
        }
        It 'Updates the fixture file with the necessary dependencies' {
          Should -Invoke Update-PuppetModuleFixture -ParameterFilter {
            $PuppetModuleFolderPath -match 'import(/|\\)foo'
          } -Times 1 -Scope Context
        }
        It 'Updates the Puppet README based on the PowerShell metadata' {
          Should -Invoke Update-PuppetModuleReadme -ParameterFilter {
            $PuppetModuleName -match 'foo' -and
            $PowerShellModuleName -match 'Foo' -and
            $PuppetModuleFolderPath -match 'import(/|\\)foo' -and
            $PowerShellModuleManifestPath -match 'import(/|\\)foo\S+(/|\\)foo(/|\\)foo.psd1'
          } -Scope Context
        }
        It 'Updates the Puppet CHANGELOG based on the PowerShell metadata' {
          Should -Invoke Update-PuppetModuleChangelog -ParameterFilter {
            $PuppetModuleFolderPath -match 'import(/|\\)foo' -and
            $PowerShellModuleManifestPath -match 'import(/|\\)foo\S+(/|\\)foo(/|\\)foo.psd1'
          } -Scope Context
        }
        It 'Temporarily sets the PSModulePath' {
          Should -Invoke Set-PSModulePath -ParameterFilter {
            $Path -match 'import(/|\\)foo\S*dsc_resources$'
          } -Times 1 -Scope Context
        }
        It 'Retrieves the DSC resources for processing' {
          Should -Invoke Get-DscResource -ParameterFilter {
            $Module -ceq 'Foo'
          } -Times 1 -Scope Context
        }
        It 'Converts the DSC resources to the Puppet Resource API representations' {
          Should -Invoke ConvertTo-PuppetResourceApi -Times 1 -Scope Context
        }
        It 'Writes a type and provider file for each discovered DSC resource' {
          Should -Invoke Out-Utf8File -Times 4 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $InputObject -match 'type$'
          } -Times 2 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $InputObject -match 'provider$'
          } -Times 2 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $Path -cmatch 'fooresource\.rb$'
          } -Times 2 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $Path -cmatch 'barresource\.rb$'
          } -Times 2 -Scope Context
        }
        It 'Generates the REFERENCE.md file' {
          Should -Invoke Add-PuppetReferenceDocumentation -ParameterFilter {
            $PuppetModuleFolderPath -match 'import(/|\\)foo'
          } -Times 1 -Scope Context
        }
        It 'Sets the PSModulePath back' {
          Should -Invoke Set-PSModulePath -ParameterFilter {
            $Path -eq $env:PSModulePath
          } -Times 1 -Scope Context
        }
      }
      Context 'Unelevated' {
        BeforeAll {
          Mock Test-RunningElevated { return $false }
          Mock Test-SymLinkedItem {}
          Mock Test-Path { $true }
        }

        It 'does not throw' {
          { New-PuppetDscModule -PowerShellModuleName Foo -PuppetModuleAuthor 'foobar' } | Should -Not -Throw
        }

        It 'Warns that the function is running in an unelevated context' {
          Should -Invoke Write-PSFMessage -ParameterFilter { $Message -match '^Running un-elevated' } -Times 1 -Scope Context
        }
        It 'Canonicalizes the author name' {
          Should -Invoke ConvertTo-CanonicalPuppetAuthorName -Times 1 -Scope Context
        }
        It 'Scaffolds the initial Puppet module' {
          Should -Invoke Initialize-PuppetModule -ParameterFilter {
            $OutputFolderPath -eq $ExpectedOutputDirectory -and
            $PuppetModuleName -ceq 'foo'
          } -Times 1 -Scope Context
        }
        It 'Vendors the PowerShell module' {
          Should -Invoke Add-DscResourceModule -ParameterFilter {
            $Name -ceq 'Foo' -and
            $Path -match 'import(/|\\)foo' -and
            $Repository -match 'PSGallery'
          } -Times 1 -Scope Context
        }
        It 'Updates the Puppet metadata based on the PowerShell metadata' {
          Should -Invoke Update-PuppetModuleMetadata -ParameterFilter {
            $PuppetModuleFolderPath -match 'import(/|\\)foo' -and
            $PowerShellModuleManifestPath -match 'import(/|\\)foo\S+(/|\\)foo(/|\\)foo.psd1'
          } -Scope Context
        }
        It 'Updates the fixture file with the necessary dependencies' {
          Should -Invoke Update-PuppetModuleFixture -ParameterFilter {
            $PuppetModuleFolderPath -match 'import(/|\\)foo'
          } -Times 1 -Scope Context
        }
        It 'Temporarily sets the PSModulePath' {
          Should -Invoke Set-PSModulePath -ParameterFilter {
            $Path -match 'import(/|\\)foo\S*dsc_resources$'
          } -Times 1 -Scope Context
        }
        It 'Retrieves the DSC resources for processing' {
          Should -Invoke Get-DscResource -ParameterFilter {
            $Module -ceq 'Foo'
          } -Times 1 -Scope Context
        }
        It 'Converts the DSC resources to the Puppet Resource API representations' {
          Should -Invoke ConvertTo-PuppetResourceApi -Times 1 -Scope Context
        }
        It 'Writes a type and provider file for each discovered DSC resource' {
          Should -Invoke Out-Utf8File -Times 4 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $InputObject -match 'type$'
          } -Times 2 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $InputObject -match 'provider$'
          } -Times 2 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $Path -cmatch 'fooresource\.rb$'
          } -Times 2 -Scope Context
          Should -Invoke Out-Utf8File -ParameterFilter {
            $Path -cmatch 'barresource\.rb$'
          } -Times 2 -Scope Context
        }
        It 'Generates the REFERENCE.md file' {
          Should -Invoke Add-PuppetReferenceDocumentation -ParameterFilter {
            $PuppetModuleFolderPath -match 'import(/|\\)foo'
          } -Times 1 -Scope Context
        }
        It 'Sets the PSModulePath back' {
          Should -Invoke Set-PSModulePath -ParameterFilter {
            $Path -eq $env:PSModulePath
          } -Times 1 -Scope Context
        }
      }
      Context 'Parameter Validation' {
        Context 'Output Directory' {
          BeforeAll {
            Mock New-Item { $Path }
            Mock Resolve-Path { $Path }
            Mock Get-DscResource {}
            Mock ConvertTo-PuppetResourceApi {}
            New-PuppetDscModule -PowerShellModuleName Foo -OutputDirectory TestDrive:\Bar -Repository FooRepo
          }

          It 'Respects the specified path' {
            Should -Invoke Initialize-PuppetModule -ParameterFilter {
              $OutputFolderPath -eq 'TestDrive:\Bar' -and
              $PuppetModuleName -ceq 'foo'
            } -Times 1 -Scope Context
            Should -Invoke Add-DscResourceModule -ParameterFilter {
              $Name -ceq 'Foo' -and
              $Path -match 'bar(/|\\)foo' -and
              $Repository -match 'FooRepo'
            } -Times 1 -Scope Context
            Should -Invoke Update-PuppetModuleMetadata -ParameterFilter {
              $PuppetModuleFolderPath -match 'bar(/|\\)foo' -and
              $PowerShellModuleManifestPath -match 'bar(/|\\)foo\S+(/|\\)foo(/|\\)foo.psd1'
            } -Scope Context
            Should -Invoke Update-PuppetModuleFixture -ParameterFilter {
              $PuppetModuleFolderPath -match 'bar(/|\\)foo'
            } -Times 1 -Scope Context
            Should -Invoke Set-PSModulePath -ParameterFilter {
              $Path -match 'bar(/|\\)foo\S*dsc_resources$'
            } -Times 1 -Scope Context
            Should -Invoke Add-PuppetReferenceDocumentation -ParameterFilter {
              $PuppetModuleFolderPath -eq 'TestDrive:\Bar\foo'
            } -Times 1 -Scope Context
          }
        }
        Context 'Puppet Module Fixture' {
          BeforeAll {
            Mock New-Item { $Path }
            Mock Resolve-Path { $Path }
            Mock Get-DscResource {}
            Mock ConvertTo-PuppetResourceApi {}
            $FixtureHash = @{
              Section = 'repositories'
              Repo    = 'https://github.com/puppetlabs/ruby-pwsh.git'
            }
            New-PuppetDscModule -PowerShellModuleName Foo -PuppetModuleFixture $FixtureHash
          }

          It 'Passes the fixture reference to Update-PuppetModuleFixture' {
            Should -Invoke Update-PuppetModuleFixture -ParameterFilter {
              $Fixture -eq $FixtureHash
            } -Times 1 -Scope Context
          }
        }
        Context 'Puppet Module Name' {
          Context 'Output Directory' {
            BeforeAll {
              Mock Resolve-Path { $Path }
              Mock Get-DscResource {}
              Mock ConvertTo-PuppetResourceApi {}

              New-PuppetDscModule -PowerShellModuleName Foo -OutputDirectory TestDrive:\Bar
            }

            It 'Respects the specified path' {
              # Need to find the actual path since the mock won't see the test drive alias
              $TestDrivePath = Get-ChildItem TestDrive:\ -Filter 'Bar' | Select-Object -ExpandProperty FullName
              $TestDrivePath | Should -Not -BeNullOrEmpty
              Should -Invoke Initialize-PuppetModule -ParameterFilter {
                $OutputFolderPath -eq $TestDrivePath -and
                $PuppetModuleName -ceq 'foo'
              } -Times 1 -Scope Context
              Should -Invoke Add-DscResourceModule -ParameterFilter {
                $Name -ceq 'Foo' -and
                $Path -match 'bar(/|\\)foo' -and
                $Repository -match 'PSGallery'
              } -Times 1 -Scope Context
              Should -Invoke Update-PuppetModuleMetadata -ParameterFilter {
                $PuppetModuleFolderPath -match 'bar(/|\\)foo' -and
                $PowerShellModuleManifestPath -match 'bar(/|\\)foo\S+(/|\\)foo(/|\\)foo.psd1'
              } -Scope Context
              Should -Invoke Update-PuppetModuleFixture -ParameterFilter {
                $PuppetModuleFolderPath -match 'bar(/|\\)foo'
              } -Times 1 -Scope Context
              Should -Invoke Set-PSModulePath -ParameterFilter {
                $Path -match 'bar(/|\\)foo\S*dsc_resources$'
              } -Times 1 -Scope Context
            }
          }

        }
        Context 'Function Output' {
          BeforeAll {
            Mock Get-DscResource {}
            Mock ConvertTo-PuppetResourceApi {}
            Mock New-Item { 'TestDrive:\OutputDirectory' }
            Mock Get-Item { 'Output' }
          }

          It 'Only returns output if PassThru is specified' {
            $ExpectNoOutputResult = New-PuppetDscModule -PowerShellModuleName Foo
            $ExpectOutputResult = New-PuppetDscModule -PowerShellModuleName Foo -PassThru
            Should -Invoke Get-Item -Times 1 -Scope It
            $ExpectNoOutputResult | Should -BeNullOrEmpty
            $ExpectOutputResult   | Should -Be 'Output'
          }
        }
        Context 'Puppet Module Naming' {
          BeforeAll {
            Mock Get-DscResource {}
            Mock ConvertTo-PuppetResourceApi {}
            Mock Get-Item { $Path }

            $UnspecifiedResult = New-PuppetDscModule -PowerShellModuleName Foo -PassThru
            $SpecifiedResult = New-PuppetDscModule -PowerShellModuleName Foo -PassThru -PuppetModuleName bar_baz
          }

          It 'Puppetizes the PowerShell module name if a Puppet module name is not specified' {
            Should -Invoke Initialize-PuppetModule -ParameterFilter {
              $PuppetModuleName -ceq 'foo'
            } -Times 1 -Scope Context
            Should -Invoke Add-DscResourceModule -ParameterFilter {
              $Path -match 'import(/|\\)foo' -and
              $Repository -match 'PSGallery'
            } -Times 1 -Scope Context
            Should -Invoke Update-PuppetModuleMetadata -ParameterFilter {
              $PuppetModuleFolderPath -match 'import(/|\\)foo' -and
              $PowerShellModuleManifestPath -match 'import(/|\\)foo\S+(/|\\)foo(/|\\)foo.psd1'
            } -Scope Context
            Should -Invoke Update-PuppetModuleFixture -ParameterFilter {
              $PuppetModuleFolderPath -match 'import(/|\\)foo'
            } -Times 1 -Scope Context
            Should -Invoke Set-PSModulePath -ParameterFilter {
              $Path -match 'import(/|\\)foo\S*dsc_resources$'
            } -Times 1 -Scope Context
          }
          It 'Uses the Puppet module name if specified' {
            Should -Invoke Initialize-PuppetModule -ParameterFilter {
              $PuppetModuleName -ceq 'bar_baz'
            } -Times 1 -Scope Context
            Should -Invoke Add-DscResourceModule -ParameterFilter {
              $Path -match 'import(/|\\)bar_baz' -and
              $Repository -match 'PSGallery'
            } -Times 1 -Scope Context
            Should -Invoke Update-PuppetModuleMetadata -ParameterFilter {
              $PuppetModuleFolderPath -match 'import(/|\\)bar_baz' -and
              $PowerShellModuleManifestPath -match 'import(/|\\)bar_baz\S+(/|\\)foo(/|\\)foo.psd1'
            } -Scope Context
            Should -Invoke Update-PuppetModuleFixture -ParameterFilter {
              $PuppetModuleFolderPath -match 'import(/|\\)bar_baz'
            } -Times 1 -Scope Context
            Should -Invoke Set-PSModulePath -ParameterFilter {
              $Path -match 'import(/|\\)bar_baz\S*dsc_resources$'
            } -Times 1 -Scope Context
          }
        }
      }
      Context 'Error Handling' {
        Context 'When an intermediate step fails' {
          BeforeAll {
            Mock Initialize-PuppetModule { Throw 'Failure!' }
            $UncalledFunctions = @(
              'Add-DscResourceModule'
              'Update-PuppetModuleMetadata'
              'Update-PuppetModuleFixture'
              'Get-DscResource'
              'ConvertTo-PuppetResourceApi'
              'Test-Path'
              'Out-Utf8File'
              'Add-PuppetReferenceDocumentation'
              'Get-Item'
            )
            ForEach ($Function in $UncalledFunctions) {
              Mock -CommandName $Function {}
            }
          }

          It 'surfaces the underlying error and stops executing' {
            { New-PuppetDscModule -PowerShellModuleName Foo } | Should -Throw 'Failure!'
            ForEach ($Function in $UncalledFunctions) {
              Should -Invoke -CommandName $Function -Times 0 -Scope It
            }
            # Cleanup always runs
            Should -Invoke Set-PSModulePath -ParameterFilter {
              $Path -eq $Env:PSModulePath
            } -Times 1 -Scope It
          }
        }
        Context 'When running elevated and the output folder is in a symlinked path' {
          BeforeAll {
            Mock Test-SymLinkedItem { return $true }
          }

          It 'throws an explanatory exception' {
            { New-PuppetDscModule -PowerShellModuleName Foo } |
              Should -Throw -PassThru |
              Select-Object -ExpandProperty Exception |
              Should -Match "The specified output folder '.+' has a symlink in the path; CIM class parsing will not work in a symlinked folder, specify another path"
          }
        }
        Context 'When running elevated and PSRemoting is disabled' {
          BeforeAll {
            Mock Test-WSMan { Throw 'Oops' }
          }

          It 'throws an explanatory exception' {
            { New-PuppetDscModule -PowerShellModuleName Foo } |
              Should -Throw -PassThru |
              Select-Object -ExpandProperty Exception |
              Should -Match 'PSRemoting does not appear to be enabled'
          }
        }
      }
    }
  }
}
