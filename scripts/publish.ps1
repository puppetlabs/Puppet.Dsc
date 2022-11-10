[CmdletBinding()]
Param(
  [switch]$Publish
)

Begin {
  $BuildFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Puppet.Dsc'
  $SourceFolder = Join-Path -Path $PSScriptRoot -ChildPath 'src'
  $MarkdownDocsFolder = Join-Path -Path $PSScriptRoot -ChildPath 'docs'

  $FoldersToCopy = @(
  (Join-Path -Path $SourceFolder -ChildPath 'en-us')
  (Join-Path -Path $SourceFolder -ChildPath 'functions')
  (Join-Path -Path $SourceFolder -ChildPath 'internal')
  (Join-Path -Path $SourceFolder -ChildPath 'xml')
  )
  $FilesToCopy = @(
    (Join-Path -Path $SourceFolder -ChildPath 'Puppet.Dsc.psd1')
    (Join-Path -Path $SourceFolder -ChildPath 'Puppet.Dsc.psm1')
    (Join-Path -Path $SourceFolder -ChildPath 'readme.md')
  )
}

Process {
  $ErrorActionPreference = 'Stop'
  Try {
    # Clean and scaffold build folder
    If (Test-Path -Path $BuildFolder) {
      Remove-Item -Path $BuildFolder -Recurse -Force
    }
    New-Item -Path $BuildFolder -ItemType Directory | Out-Null

    # Copy source files
    Copy-Item -Path $FoldersToCopy -Destination $BuildFolder -Recurse
    Copy-Item -Path $FilesToCopy -Destination $BuildFolder

    # Convert and write documentation
    Import-Module "$BuildFolder\Puppet.Dsc.psd1" -Force
    New-MarkdownHelp -Module 'Puppet.Dsc' -OutputFolder $MarkdownDocsFolder -Force
    New-ExternalHelp -Path $MarkdownDocsFolder -OutputPath "$BuildFolder\en-us\"

    # Publish the module and tag if desired
    If ($Publish) {
      Publish-Module -Path $BuildFolder -NugetAPIKey $Env:GALLERY_TOKEN
    } Else {
      Publish-Module -Path $BuildFolder -NugetAPIKey $Env:GALLERY_TOKEN -WhatIf -Verbose
    }
  } Catch {
    $PSCmdlet.ThrowTerminatingError($PSItem)
  }
}

End {}
