$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
# . "$here\$sut"
$script = "$here\$sut"

. .\src\internal\functions\Invoke-PdkCommand.ps1

$expected_base = '../bar/powershellget'

Remove-Item $expected_base -Force -Recurse -ErrorAction Ignore

& $script -PowerShellModuleName "PowerShellGet" -PowerShellModuleVersion "2.1.3"  -PuppetModuleAuthor 'testuser' -OutputDirectory "../bar"

# remove test instances left over from a previous run
try {
  Invoke-DscResource -Name 'PSRepository' -Method 'Set' -Property @{Name = 'foo'; Ensure = 'absent' } -ModuleName @{ModuleName = 'C:/ProgramData/PuppetLabs/code/modules/powershellget/lib/puppet_x/dsc_resources/PowerShellGet/PowerShellGet.psd1'; RequiredVersion = '2.1.3' }
}
catch {
  # ignore cleanup errors
}

# cleanup a previously installed test module before the test, ignoring any result
Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet module uninstall testuser-powershellget' -SuccessFilterScript { $true }

Describe $script {

  It "creates a module" {
    Test-Path "$expected_base\metadata.json" | Should -BeTrue
  }

  It "has a REFERENCE.md" {
    Test-Path "$expected_base\REFERENCE.md" | Should -BeTrue
  }

  It "has a type generated" {
    Test-Path "$expected_base\lib\puppet\type\dsc_psmodule.rb" | Should -BeTrue
  }

  Context "when inside the module" {
    It '`pdk validate metadata` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate metadata' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It '`pdk validate puppet` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate puppet' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It '`pdk validate tasks` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate tasks' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It '`pdk validate yaml` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate yaml' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It "is buildable" {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk build' -SuccessFilterScript {
        $_ -match "Build of testuser-powershellget has completed successfully."
      }
    }
    It "is installable" {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet module install --verbose pkg/*.tar.gz' -SuccessFilterScript {
        $_ -match "Installing -- do not interrupt"
      }
    }
    It "lists all dsc_psrepository resources" -Pending {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet resource dsc_psrepository --verbose --debug --trace' -SuccessFilterScript {
        $_ -match "dsc_psrepository {"
      }
    }
    It "shows a specific dsc_psrepository resource" {
      # PSGallery is the default repo always installed
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet resource dsc_psrepository PSGallery --verbose --debug --trace' -SuccessFilterScript {
        $_ -match "dsc_psrepository {" -and $_ -match "PSGallery"
      }
    }
    It "shows a specific dsc_psrepository resource with attributes" -Pending {
      # PSGallery is the default repo always installed
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet resource dsc_psrepository PSGallery --verbose --debug --trace' -SuccessFilterScript {
        $_ -match "dsc_psrepository {" -and $_ -match "PSGallery" -and $_ -match "dsc_installationpolicy.*=>.*'trusted'"
      }
    }
  }

  Context "when passing in invalid values" {
    It "reports the error" {
      { New-PuppetDscModule -PowerShellModuleName "____DoesNotExist____" -OutputDirectory "C:\foo" -ErrorAction Stop } | Should -Throw
    }
  }

  Context "when managing an existing repository with 'puppet apply'" {
    It "doesn't do anything" {
      # PSGallery is the default repo always installed
      Set-Content -Path "$expected_base\confirm.pp" -Value "dsc_psrepository { 'PSGallery': }`n"
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace confirm.pp' -ErrorFilterScript { $_ -match 'Notice:.*Dsc_psrepository\[PSGallery\]' }
    }
  }

  Context "when creating a new repository with 'puppet apply'" {
    It "works" {
      # create new arbitrary repo location
      $manifest = 'dsc_psrepository { "foo":
          dsc_ensure             => present,
          dsc_sourcelocation     => "c:\\program files",
          dsc_installationpolicy => untrusted,
        }'
      Set-Content -Path "$expected_base\new_repo.pp" -Value $manifest
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false new_repo.pp' -SuccessFilterScript {
        # TODO: fix this to match closer to the changes
        # ($_ -match "Dsc_psrepository\[foo\]/dsc_installationpolicy: dsc_installationpolicy changed  to 'untrusted'") -and ($_ -match "Notice: dsc_psrepository\[foo\]: Updating: Finished")
        $_ -match "Notice: dsc_psrepository\[foo\]: Updating: Finished"
      }
    }
    # remove previous testcase when enabling this
    It "works with non-canonical elements" -Pending {
      # create new arbitrary repo location with a title and non-lowercase source location
      $manifest = 'dsc_psrepository { "bar"
          dsc_name               => "foo":
          dsc_ensure             => present,
          dsc_sourcelocation     => "C:\\Program Files",
          dsc_installationpolicy => untrusted,
        }'
      Set-Content -Path "$expected_base\new_repo.pp" -Value $manifest
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false new_repo.pp' -SuccessFilterScript {
        # reminder: this -match didn't work previously, even though it should.
        ($_ -match "Dsc_psrepository\[foo\]/dsc_installationpolicy: dsc_installationpolicy changed  to 'untrusted'") -and ($_ -match "Notice: dsc_psrepository\[foo\]: Creating: Finished")
      }
    }

    It 'is idempotent' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false new_repo.pp' -ErrorFilterScript { $_ -match 'Notice:.*Dsc_psrepository\[foo\]' }
    }
  }

  Context "when a valid manifest causes a run-time error" {
    It "reports the error" {
      # re-use previous repo location, with a new name this will trip up the DSC resource
      $manifest = 'dsc_psrepository { "foo2":
          dsc_ensure             => present,
          dsc_sourcelocation     => "c:\\program files",
          dsc_installationpolicy => untrusted,
        }'
      Set-Content -Path "$expected_base\reuse_repo.pp" -Value $manifest
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false reuse_repo.pp' -SuccessFilterScript {
        $_ -match "The repository could not be registered because there exists a registered repository with Name"
      }
    }
  }

  Context "with a Sensitive value" {
    It "does not print the value in regular mode" -Pending { }
    It "does not print the value in debug mode" -Pending { }
  }
}


$expected_base = '../bar/nuget'

Remove-Item $expected_base -Force -Recurse -ErrorAction Ignore

new-item C:\nugetlocal -itemtype directory

& $script -PowerShellModuleName "NuGet" -PowerShellModuleVersion "1.3.3"  -PuppetModuleAuthor 'testuser' -OutputDirectory "../bar"

# remove test instances left over from a previous run
try {
  Invoke-DscResource -Name 'DscNuget' -Method 'Set' -Property @{Name = 'nugetlocal'; Ensure = 'absent' } -ModuleName @{ModuleName = 'C:/ProgramData/PuppetLabs/code/modules/nuget/lib/puppet_x/dsc_resources/nuget/nuget.psd1'; RequiredVersion = '1.3.3' }
}
catch {
  # ignore cleanup errors
}

# cleanup a previously installed test module before the test, ignoring any result
Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet module uninstall testuser-nuget' -SuccessFilterScript { $true }

Describe $script {

  It "creates a module" {
    Test-Path "$expected_base\metadata.json" | Should -BeTrue
  }

  It "has a REFERENCE.md" {
    Test-Path "$expected_base\REFERENCE.md" | Should -BeTrue
  }

  It "has a type generated" {
    Test-Path "$expected_base\lib\puppet\type\dsc_nuget.rb" | Should -BeTrue
  }

  Context "when inside the module" {
    It '`pdk validate metadata` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate metadata' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It '`pdk validate puppet` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate puppet' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It '`pdk validate tasks` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate tasks' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It '`pdk validate yaml` runs successfully' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk validate yaml' -SuccessFilterScript { $_ -match "Using Puppet" } -ErrorFilterScript { $_ -match "error:" }
    }
    It "is buildable" {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk build' -SuccessFilterScript {
        $_ -match "Build of testuser-nuget has completed successfully."
      }
    }
    It "is installable" {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet module install --verbose pkg/*.tar.gz' -SuccessFilterScript {
        $_ -match "Installing -- do not interrupt"
      }
    }
    It "lists all dsc_nuget resources" -Pending {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet resource dsc_nuget --verbose --debug --trace' -SuccessFilterScript {
        $_ -match "dsc_psrepository {"
      }
    }
    It "shows a specific dsc_psrepository resource" -Pending {
      No default values for local nuget repository
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet resource dsc_nuget testname --verbose --debug --trace' -SuccessFilterScript {
        $_ -match "dsc_nuget {" -and $_ -match "testname"
      }
    }
    It "shows a specific dsc_nuget resource with attributes" -Pending {
       No default values for local nuget repository
       Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet resource dsc_nuget testname --verbose --debug --trace' -SuccessFilterScript {
         $_ -match "dsc_nuget {" -and $_ -match "testname" -and $_ -match "dsc_packagesource.*=>.*'nugetlocal'"
      }
    }
  }

  Context "when passing in invalid values" {
    It "reports the error" {
      { New-PuppetDscModule -PowerShellModuleName "____DoesNotExist____" -OutputDirectory "C:\foo" -ErrorAction Stop } | Should -Throw
    }
  }

  Context "when managing an existing repository with 'puppet apply'" {
    It "doesn't do anything" -Pending {
      # No default values for local nuget repository
      Set-Content -Path "$expected_base\confirm_nuget.pp" -Value "dsc_nuget { 'testname': }`n"
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace confirm_nuget.pp' -ErrorFilterScript { $_ -match 'Notice:.*Dsc_nuget\[testname\]' }
    }
  }

  Context "Manage a module with 'puppet apply'" {
    It "works" -Pending {
      # manage a module
      $manifest = 'dsc_nuget { "nugetlocal":
      ensure                        => present,
      dsc_name                      => "nugetlocal",
      dsc_packagesource             => "c:\\nugetlocal",
      dsc_allownugetpackagepush     => false,
    }'
      Set-Content -Path "$expected_base\manage_module_nuget.pp" -Value $manifest
      # Ticket opened for the failure.https://tickets.puppetlabs.com/browse/IAC-902
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false manage_module_nuget.pp' -SuccessFilterScript {
        $_ -match "Notice: dsc_nuget\[nugetlocaltesting\]: Updating: Finished"
      }
    }
    # remove previous testcase when enabling this
    It "works with non-canonical elements" -Pending {
      # manage another module with a title and non-lowercase source location
      $manifest = 'dsc_nuget { "nugetlocaltesting":
      ensure                        => present,
      dsc_name                      => "nugetlocal",
      dsc_packagesource             => "C:\\nugetlocal",
      dsc_allownugetpackagepush     => false,
    }'
      Set-Content -Path "$expected_base\manage_module_nuget.pp" -Value $manifest
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false manage_module_nuget.pp' -SuccessFilterScript {
        ($_ -match "Dsc_nuget\[nugetlocaltesting\]/dsc_allownugetpackagepush: dsc_allownugetpackagepush changed  to false") -and ($_ -match "Notice: dsc_nuget\[nugetlocaltesting\]: Creating: Finished")
      }
    }

    It 'is idempotent' {
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false manage_module_nuget.pp' -ErrorFilterScript { $_ -match 'Notice:.*Dsc_nuget\[nugetlocaltesting\]' }
    }
  }

  Context "when a valid manifest causes a run-time error" {
    It "reports the error" -Pending {
      # re-use previous repo location, with a new name this will trip up the DSC resource
      $manifest = 'dsc_nuget { "nugetlocalnew":
      ensure                        => present,
      dsc_packagesource             => "c:\\nugetlocal",
      dsc_allownugetpackagepush     => false,
    }'
      Set-Content -Path "$expected_base\reuse_repo_nuget.pp" -Value $manifest
      Invoke-PdkCommand -Path $expected_base -Command 'pdk bundle exec puppet apply --verbose --debug --trace --color=false reuse_repo_nuget.pp' -SuccessFilterScript {
        $_ -match "The repository could not be registered because there exists a registered repository with Name"
      }
    }
  }
}
