Describe 'Out-Utf8File' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    BeforeAll {
      # Have to pass a full path to the function as it cannot see a PSDrive
      # This evaluates to `TestDrive:\Foo`
      $TestPath = Join-Path -Path (Get-PSDrive TestDrive).Root -ChildPath Foo
      Out-Utf8File -Path $TestPath -InputObject 'Bar'
    }

    It 'Creates a file' {
      $TestPath | Should -Exist
      $TestPath | Should -FileContentMatchExactly 'Bar'
    }
    It 'Encodes the file as UTF-8' {
      New-Object -TypeName System.IO.StreamReader -ArgumentList $TestPath -OutVariable Stream |
        Select-Object -ExpandProperty CurrentEncoding |
        Select-Object -ExpandProperty BodyName | Should -Be 'UTF-8'
      $Stream.Dispose()
    }
    It 'Writes a file without a BOM' {
      $ContentBytes = [System.Io.File]::ReadAllBytes($TestPath)
      $ContentBytes.Length | Should -BeGreaterThan 2
      $ContentBytes[0] -eq 0xEF -and
      $ContentBytes[1] -eq 0xBB -and
      $ContentBytes[2] -eq 0xBF | Should -Be $False
    }
  }
}
