Function Test-SymLinkedItem {
  <#
    .SYNOPSIS
      Determine if a specified path is a symlink
    .DESCRIPTION
      Determine if a specified path is a symlink or, if recursing, if that path is itself
      inside a symlink further up the path.
    .PARAMETER Path
      The path to introspect to learn whether or not it is a symlink.
    .PARAMETER Recurse
      If this switch is specified the command will look at each parent node in the path
      to see if the specified path is itself inside a symlinked folder.
    .EXAMPLE
      Test-SymLinkedItem -Path C:/foo/bar/baz -Recurse

      This command will first check to see if `baz` is a symlinked item, and, if it is,
      return True. If it is *not*, it will then check the parent folder, `bar`, and if
      that folder is not symlinked, check `foo`, and then `C:/`. If no part of the path
      is a symlink it will return False, otherwise it will immediately return True when
      it discovers part of the path is symlinked.
  #>
  [cmdletbinding()]
  [OutputType([Boolean])]
  Param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$Recurse
  )

  $SymLinkedItem = Get-Item -Path $Path -Force -ErrorAction SilentlyContinue |
    Where-Object -FilterScript { ![string]::IsNullOrEmpty($_.LinkType) }
  If ($null -ne $SymLinkedItem) {
    return $true
  } ElseIf ($Recurse) {
    $ParentPath = Split-Path -Path $Path -Parent
    if ([string]::IsNullOrEmpty($ParentPath)) {
      return $false
    } else {
      return (Test-SymLinkedItem -Path $ParentPath -Recurse)
    }
  } Else {
    return $false
  }
}
