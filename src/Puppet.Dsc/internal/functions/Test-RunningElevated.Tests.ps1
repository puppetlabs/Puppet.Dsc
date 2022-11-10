Describe 'Test-RunningElevated' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    It 'only returns true if current session has administrative privileges' -Pending {
      # Currently no known way to test this function as it relies entirely on .NET methods
    }
  }
}
