Function Test-RunningElevated {
  <#
  .SYNOPSIS
    Returns whether or not the current session is running with elevated privileges
  .DESCRIPTION
    Returns whether or not the current session is running with elevated privileges
  #>
  [cmdletbinding()]
  [OutputType([Boolean])]
  Param()
  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}
