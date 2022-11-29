Describe 'Test-EmbeddedInstance' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    It 'returns false if in the known base types list' {
      Test-EmbeddedInstance -PropertyType 'String' | Should -BeFalse
    }
    It 'returns true if not in the known base types list' {
      Test-EmbeddedInstance -PropertyType 'foo' | Should -BeTrue
    }
    It 'strips square brackets when checking' {
      Test-EmbeddedInstance -PropertyType 'String[]' | Should -BeFalse
    }
  }
}
