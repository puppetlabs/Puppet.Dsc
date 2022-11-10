Describe 'Get-ReadmeContent' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    Context 'Basic verification' {
      BeforeAll {
        $Parameters = @{
          PowerShellModuleName        = 'Foo.Bar'
          PowerShellModuleDescription = 'Foo and bar and baz!'
          PowerShellModuleGalleryUri  = 'https://powershellgallery.com/Foo.Bar/1.0.0'
          PowerShellModuleProjectUri  = 'https://github.com/Baz/Foo.Bar'
          PowerShellModuleVersion     = '1.0.0'
          PuppetModuleName            = 'foo_bar'
        }
        $Result = Get-ReadmeContent @Parameters
      }
      It 'Has the puppet module name as the title' {
        $Result | Should -MatchExactly "# $($Parameters.PuppetModuleName)"
      }
      It 'Includes the link to the builder, the upstream module, and the module version in the first para' {
        $Result | Should -MatchExactly '\[Puppet DSC Builder\]\(.+\)'
        $Result | Should -MatchExactly "\[$($Parameters.PowerShellModuleName)\]\($($Parameters.PowerShellModuleGalleryUri)\)"
        $Result | Should -MatchExactly "v$([Regex]::Escape($Parameters.PowerShellModuleVersion))"
      }
      It 'Includes the module description as a quote' {
        $Result | Should -MatchExactly "> _$($Parameters.PowerShellModuleDescription)_"
      }
      It 'Links to the Resource API and pwshlib dependencies' {
        $Result | Should -MatchExactly '\[Puppet Resource API\]\(.+\)'
        $Result | Should -MatchExactly '\[puppetlabs/pwshlib\]\(.+\)'
      }
      It 'Links to the base provider on github' {
        $Result | Should -MatchExactly '\(https://github.com/.+/dsc_base_provider.rb\)'
      }
      It 'Links to further narrative documentation' {
        $Result | Should -MatchExactly '\[narrative documentation\]\(.+\)'
      }
      It 'Links to the issues page for the builder, the pwslib module, and the upstream module' {
        $Result | Should -MatchExactly '\[file an issue\]\(.+puppetlabs/Puppet.Dsc/issues/new/choose\)'
        $Result | Should -MatchExactly '\[file an issue\]\(.+puppetlabs/ruby-pwsh/issues/new/choose\)'
        $Result | Should -MatchExactly "\[file an issue\]\($($Parameters.PowerShellModuleProjectUri)\)"
      }
    }
    Context 'Parameter handling' {
      It 'Marks the PowerShellModuleName parameter as mandatory' {
        (Get-Command -Name Get-ReadmeContent).Parameters['PowerShellModuleName'].Attributes |
          Where-Object -FilterScript { $_ -is [parameter] } |
          Select-Object -ExpandProperty Mandatory | Should -Be $true
      }
      It 'Marks the PuppetModuleName parameter as mandatory' {
        (Get-Command -Name Get-ReadmeContent).Parameters['PuppetModuleName'].Attributes |
          Where-Object -FilterScript { $_ -is [parameter] } |
          Select-Object -ExpandProperty Mandatory | Should -Be $true
      }
      It 'Errors if the PowerShellModuleName is specified as an empty string' {
        $Parameters = @{
          PowerShellModuleName        = ''
          PowerShellModuleDescription = 'Foo and bar and baz!'
          PowerShellModuleGalleryUri  = 'https://powershellgallery.com/Foo.Bar/1.0.0'
          PowerShellModuleProjectUri  = 'https://github.com/Baz/Foo.Bar'
          PowerShellModuleVersion     = '1.0.0'
          PuppetModuleName            = 'foo_bar'
        }
        { Get-ReadmeContent @Parameters } | Should -Throw "Cannot validate argument on parameter 'PowerShellModuleName'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
      }
      It 'Errors if the PowerShellModuleDescription is specified as an empty string' {
        $Parameters = @{
          PowerShellModuleName        = 'Foo.Bar'
          PowerShellModuleDescription = ''
          PowerShellModuleGalleryUri  = 'https://powershellgallery.com/Foo.Bar/1.0.0'
          PowerShellModuleProjectUri  = 'https://github.com/Baz/Foo.Bar'
          PowerShellModuleVersion     = '1.0.0'
          PuppetModuleName            = 'foo_bar'
        }
        { Get-ReadmeContent @Parameters } | Should -Throw "Cannot validate argument on parameter 'PowerShellModuleDescription'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
      }
      It 'Errors if the PowerShellModuleGalleryUri is specified as an empty string' {
        $Parameters = @{
          PowerShellModuleName        = 'Foo.Bar'
          PowerShellModuleDescription = 'Foo and bar and baz!'
          PowerShellModuleGalleryUri  = ''
          PowerShellModuleProjectUri  = 'https://github.com/Baz/Foo.Bar'
          PowerShellModuleVersion     = '1.0.0'
          PuppetModuleName            = 'foo_bar'
        }
        { Get-ReadmeContent @Parameters } | Should -Throw "Cannot validate argument on parameter 'PowerShellModuleGalleryUri'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
      }
      It 'Uses the PowerShellModuleGalleryUri for the PowerShellModuleProjectUri if the PowerShellModuleProjectUri is specified as an empty string' {
        $Parameters = @{
          PowerShellModuleName        = 'Foo.Bar'
          PowerShellModuleDescription = 'Foo and bar and baz!'
          PowerShellModuleGalleryUri  = 'https://powershellgallery.com/Foo.Bar/1.0.0'
          PowerShellModuleProjectUri  = ''
          PowerShellModuleVersion     = '1.0.0'
          PuppetModuleName            = 'foo_bar'
        }
        $Result = Get-ReadmeContent @Parameters
        $Result | Should -MatchExactly "\[file an issue\]\($($Parameters.PowerShellModuleGalleryUri)\)"
      }
      It 'Errors if the PowerShellModuleVersion is specified as an empty string' {
        $Parameters = @{
          PowerShellModuleName        = 'Foo.Bar'
          PowerShellModuleDescription = 'Foo and bar and baz!'
          PowerShellModuleGalleryUri  = 'https://powershellgallery.com/Foo.Bar/1.0.0'
          PowerShellModuleProjectUri  = 'https://github.com/Baz/Foo.Bar'
          PowerShellModuleVersion     = ''
          PuppetModuleName            = 'foo_bar'
        }
        { Get-ReadmeContent @Parameters } | Should -Throw "Cannot validate argument on parameter 'PowerShellModuleVersion'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
      }
      It 'Errors if the PuppetModuleName is specified as an empty string' {
        $Parameters = @{
          PowerShellModuleName        = 'Foo.Bar'
          PowerShellModuleDescription = 'Foo and bar and baz!'
          PowerShellModuleGalleryUri  = 'https://powershellgallery.com/Foo.Bar/1.0.0'
          PowerShellModuleProjectUri  = 'https://github.com/Baz/Foo.Bar'
          PowerShellModuleVersion     = '1.0.0'
          PuppetModuleName            = ''
        }
        { Get-ReadmeContent @Parameters } | Should -Throw "Cannot validate argument on parameter 'PuppetModuleName'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
      }
    }
  }
}
