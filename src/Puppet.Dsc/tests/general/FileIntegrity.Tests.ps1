Describe 'Verifying integrity of module files' -Tag @('FileIntegrity', 'General') {
  BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
  }
  BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRoot/Puppet.Dsc.psd1"

    . "$PSScriptRoot\FileIntegrity.Exceptions.ps1"

    function Get-FileEncoding {
      <#
        .SYNOPSIS
          Tests a file for encoding.

        .DESCRIPTION
          Tests a file for encoding.

        .PARAMETER Path
          The file to test
      #>
      [CmdletBinding()]
      Param (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('FullName')]
        [string]
        $Path
      )

      if ($PSVersionTable.PSVersion.Major -lt 6) {
        [byte[]]$byte = Get-Content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
      } else {
        [byte[]]$byte = Get-Content -AsByteStream -ReadCount 4 -TotalCount 4 -Path $Path
      }

      if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf) { 'UTF8 BOM' }
      elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff) { 'Unicode' }
      elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff) { 'UTF32' }
      elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76) { 'UTF7' }
      else {
        New-Object -TypeName System.IO.StreamReader -ArgumentList $Path -OutVariable Stream |
          Select-Object -ExpandProperty CurrentEncoding |
          Select-Object -ExpandProperty BodyName
        $Stream.Dispose()
      }
    }
  }
  Context 'Validating PS1 Script files' {
    BeforeDiscovery {
      $ScriptFileInfo = Get-ChildItem -Path $moduleRoot -Recurse |
        Where-Object Name -Like '*.ps1' |
        Where-Object FullName -NotLike "$moduleRoot\tests\*" |
        ForEach-Object -Process {
          @{
            ShortName  = $PSItem.FullName.Replace("$moduleRoot\", '')
            FullName   = $PSItem.FullName
            FileHandle = $PSItem
          }
        }
    }

    Context 'Validating <ShortName>' -ForEach $ScriptFileInfo {
      BeforeAll {
        $Tokens = $null
        $ParseErrors = $null
        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($FullName, [ref]$tokens, [ref]$parseErrors)
      }
      It 'should have UTF8 encoding without a Byte Order Mark' {
        # Temporary hack as all the files are UTF8 but the tests don't support that yet
        Get-FileEncoding -Path $FullName | Should -Be 'UTF-8'
      }

      It 'should have no trailing space' {
        ($FileHandle | Select-String '\s$' | Where-Object { $_.Line.Trim().Length -gt 0 }).LineNumber | Should -BeNullOrEmpty
      }

      It 'should have no syntax errors' {
        $parseErrors | Should -Be $Null
      }

      It 'should not use banned commands' {
        ForEach ($Command in $Global:BannedCommands) {
          If ($global:MayContainCommand["$Command"] -notcontains $FileHandle.Name) {
            $tokens | Where-Object Text -EQ $Command | Should -BeNullOrEmpty
          }
        }
      }
    }
  }

  Context 'Validating help.txt help files' {
    BeforeDiscovery {
      $HelpFileInfo = Get-ChildItem -Path $moduleRoot -Recurse |
        Where-Object Name -Like '*.help.txt' |
        Where-Object FullName -NotLike "$moduleRoot\tests\*" |
        ForEach-Object -Process {
          @{
            ShortName  = $PSItem.FullName.Replace("$moduleRoot\", '')
            FullName   = $PSItem.FullName
            FileHandle = $PSItem
          }
        }
    }

    Context 'Validating <ShortName>' -ForEach $HelpFileInfo {
      It 'should have UTF8 encoding without a Byte Order Mark' {
        # Temporary hack as all the files are UTF8 but the tests don't support that yet
        Get-FileEncoding -Path $FullName | Should -Be 'UTF-8'
      }

      It 'should have no trailing space' {
        ($FileHandle | Select-String '\s$' | Where-Object { $_.Line.Trim().Length -gt 0 }).LineNumber | Should -BeNullOrEmpty
      }
    }
  }
}
