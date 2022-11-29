Describe 'Add-PuppetReferenceDocumentation' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  InModuleScope Puppet.Dsc {
    BeforeAll {
      Mock Test-Path { return $False }
      Mock New-Item {}
      Mock Invoke-PdkCommand {}
      Mock Resolve-Path { $Path }
    }
    Context 'Basic verification' {
      It 'Uses the PDK to generate the REFERENCE.md file' {
        { Add-PuppetReferenceDocumentation -PuppetModuleFolderPath 'TestDrive:\foo' } | Should -Not -Throw
        Should -Invoke Invoke-PdkCommand -Times 1 -Scope It -ParameterFilter { $Command -match 'bundle exec puppet strings generate --format markdown --out REFERENCE.md' }
      }
      It 'Rethrows the exception if the PDK command is unsuccessful' {
        Mock Invoke-PdkCommand { Throw 'foo' }
        { Add-PuppetReferenceDocumentation -PuppetModuleFolderPath 'TestDrive:\foo' } | Should -Throw 'foo'
      }
      It 'Rethrows the exception if the PuppetModuleFolder does not exist' {
        Mock Join-Path { Throw 'does not exist' }
        { Add-PuppetReferenceDocumentation -PuppetModuleFolderPath 'TestDrive:\foo' } | Should -Throw 'does not exist'
      }
    }
  }
}
