Function Set-PSModulePath {
  <#
    .SYNOPSIS
      Set the PowerShell module path
    .DESCRIPTION
      Set the PowerShell module path
    .PARAMETER Path
      The path or paths to search for PowerShell modules
    .PARAMETER ReturnInitialPath
      If specified, will return the initial PSModulePath as output
    .PARAMETER Confirm
      Prompts for confirmation before creating the Puppet module
    .PARAMETER WhatIf
      Shows what would happen if the function runs.
    .EXAMPLE
      Set-PSModulePath -Path foo -ReturnInitialPath

      This function will override the PSModule path with 'foo' and return
      the original PSModulePath as output.
  #>
  [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  Param(
    [string[]]$Path,
    [switch]$ReturnInitialPath
  )

  Process {
    If ($PSCmdlet.ShouldProcess('PSModulePath', "Overwriting the PSModulePath with $($Path -Join ';')")) {
      If ($ReturnInitialPath) { $Env:PSModulePath }
      $Env:PSModulePath = $Path -Join ';'
    }
  }
}
