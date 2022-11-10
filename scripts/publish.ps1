[CmdletBinding()]
Param(
  [switch]$Publish
)

Begin {
  $WorkspaceRoot = Split-Path -Parent $PSscriptRoot
  $BuildFolder = Join-Path -Path $WorkspaceRoot -ChildPath 'Puppet.Dsc'
  $SourceFolder = Join-Path -Path $WorkspaceRoot -ChildPath 'src/Puppet.Dsc'
  $MarkdownDocsFolder = Join-Path -Path $WorkspaceRoot -ChildPath 'docs'

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
