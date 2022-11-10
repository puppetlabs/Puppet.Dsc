Describe 'ConvertTo-UnescapedJson' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }
  Context 'Basic verification' {
    It 'Converts the object to JSON without unicode escapes' {
      # We cannot effectively mock out the underlying object, so we need to retrieve a
      # well-known DSC resource at a specific version
      $ExampleObject = @{
        VersionRequirement = '>= 6.0.0 < 7.0.0'
      }

      $ExampleObject | ConvertTo-Json | Should -Not -Match '(>=|<)'
      $ExampleObject | ConvertTo-UnescapedJson | Should -Match '>= 6\.0\.0 < 7\.0\.0'
    }
  }
}
