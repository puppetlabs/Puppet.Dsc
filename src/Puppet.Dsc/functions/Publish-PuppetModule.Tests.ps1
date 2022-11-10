Describe 'Publish-PuppetModule' -Tag 'Unit' {
  BeforeDiscovery {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
  }

  InModuleScope puppet.dsc {
    Context 'Basic verification' {
      BeforeAll {
        Mock Export-PuppetModule
        Mock Invoke-PdkCommand
        Mock Write-PSFMessage
        Mock Resolve-Path { return [pscustomobject]@{ Path = $Path } }
        Mock Resolve-Path -ParameterFilter { $Path -match 'DoesNotExist' } {
          Throw "Cannot find path '$Path' because it does not exist."
        }

        $TokenlessPublishParameters = @{
          Publish                = $true
          PuppetModuleFolderPath = 'TestDrive:\foo'
        }
        $MinimalPublishParameters = @{
          Publish                = $true
          PuppetModuleFolderPath = 'TestDrive:\foo'
          ForgeToken             = 'MyVeryValidToken'
        }
        $MinimalBuildParameters = @{
          Build                  = $true
          PuppetModuleFolderPath = 'TestDrive:\foo'
        }
      }
      It 'throws if the PuppetModuleFolderPath is not resolvable' {
        { Publish-PuppetModule -PuppetModuleFolderPath 'TestDrive:\DoesNotExist' } | Should -Throw 'Cannot find path*'
      }
      Context 'when neither the Build nor Publish switches are passed' {
        It 'does nothing' {
          Publish-PuppetModule -PuppetModuleFolderPath 'TestDrive\foo' | Should -BeNullOrEmpty
        }
      }
      Context 'when the Publish switch is passed' {
        It 'throws if the ForgeToken is null or empty' {
          {
            $env:FORGE_TOKEN = ''
            Publish-PuppetModule @TokenlessPublishParameters
          } | Should -Throw 'No Puppet Forge Token specified*'
        }
        It 'uses the PDK to publish the module' {
          Publish-PuppetModule @MinimalPublishParameters
          Should -Invoke Invoke-PdkCommand -ParameterFilter {
            $Path -eq 'TestDrive:\foo' -and
            $Command -eq 'pdk release publish --forge-token MyVeryValidToken'
          }
        }
        It 'passes ``--force`` if the Force switch is passed' {
          Publish-PuppetModule @MinimalPublishParameters -Force
          Should -Invoke Invoke-PdkCommand -ParameterFilter {
            $Command -match '--force'
          }
        }
        It 'passes ``--forge-upload-url `<URL`>`` if ForgeUploadUrl is specified' {
          Publish-PuppetModule @MinimalPublishParameters -ForgeUploadUrl 'FooBarBaz'
          Should -Invoke Invoke-PdkCommand -ParameterFilter {
            $Command -match '--forge-upload-url FooBarBaz'
          }
        }
        It 'passes ``--file `<FILEPATH`>`` if PackagedModulePath is specified' {
          Publish-PuppetModule @MinimalPublishParameters -PackagedModulePath 'TestDrive:\bar\module.tar.gz'
          Should -Invoke Invoke-PdkCommand -ParameterFilter {
            $Command -match [regex]::Escape('--file TestDrive:\bar\module.tar.gz')
          }
        }
        Context 'when the Build switch is not passed' {
          It 'does not call Export-Module' {
            Publish-PuppetModule @MinimalPublishParameters
            Should -Invoke Export-PuppetModule -Times 0
          }
        }
        Context 'when the Build switch is passed' {
          It 'calls Export-PuppetModule' {
            Publish-PuppetModule @MinimalPublishParameters -Build
            Should -Invoke Export-PuppetModule -ParameterFilter {
              $PuppetModuleFolderPath -eq 'TestDrive:\foo'
            }
          }
          It 'passes the Force switch to Export-PuppetModule if specified' {
            Publish-PuppetModule @MinimalPublishParameters -Build -Force
            Should -Invoke Export-PuppetModule -ParameterFilter {
              $Force -eq $true
            }
          }
          Context 'when ExportFolderPath is specified' {
            BeforeAll {
              Mock Get-Item {
                @(
                  [PSCustomObject]@{ FullName = 'TestDrive:\bar\testuser-foo-1.2.3-0-0.tar.gz' ; LastWriteTime = 0 }
                  [PSCustomObject]@{ FullName = 'TestDrive:\bar\testuser-foo-1.2.3-0-1.tar.gz' ; LastWriteTime = 1 }
                  [PSCustomObject]@{ FullName = 'TestDrive:\bar\testuser-foo-1.2.3-0-2.tar.gz' ; LastWriteTime = 2 }
                )
              }
            }

            It 'passes the specified path to Export-PuppetModule' {
              Publish-PuppetModule @MinimalPublishParameters -Build -ExportFolderPath 'TestDrive:\bar'
              Should -Invoke Export-PuppetModule -ParameterFilter {
                $ExportFolderPath -eq 'TestDrive:\bar'
              }
            }

            It 'passes the latest-built module via the ``--file`` PDK parameter' {
              Publish-PuppetModule @MinimalPublishParameters -Build -ExportFolderPath 'TestDrive:\bar'
              Should -Invoke Invoke-PdkCommand -ParameterFilter {
                $Command -match [regex]::Escape('--file TestDrive:\bar\testuser-foo-1.2.3-0-2.tar.gz')
              }
            }
          }
        }
      }
      Context 'when the Build switch is passed without Publish' {
        It 'calls Export-PuppetModule' {
          Publish-PuppetModule @MinimalBuildParameters
          Should -Invoke Export-PuppetModule -ParameterFilter {
            $PuppetModuleFolderPath -eq 'TestDrive:\foo'
          }
        }
        It 'does not call Invoke-PdkCommand directly' {
          Publish-PuppetModule @MinimalBuildParameters
          Should -Invoke Invoke-PdkCommand -Times 0
        }
        It 'errors on invalid syntax if PackagedModulePath is specified' {
          { Publish-PuppetModule @MinimalBuildParameters -PackagedModulePath 'foo' } |
            Should -Throw '*cannot be resolved using the specified named parameters*'
        }
      }
    }
  }
}