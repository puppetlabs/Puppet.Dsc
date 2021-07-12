Function Get-PowerShellDscModule {
  <#
  .SYNOPSIS
    Retrieve one or more PowerShell modules with DSC Resources
  .DESCRIPTION
    Retrieve one or more PowerShell modules with DSC Resources from a PowerShell repository,
    returning their name and all released versions.
  .PARAMETER Name
    The name of one or more modules to search for. If not specified, returns all modules
    with DSC Resources.
  .EXAMPLE
    Get-PowerShellDscModule
    Searches the PowerShell Gallery for every module with DSC Resources and returns every
    released version of those modules.
  .INPUTS
    None.
  .OUTPUTS
    [PSCustomObject[]] An object with the name of each discovered module and a Releases
    property for every version released to the repository.
  #>

  [CmdletBinding()]
  param (
    [Parameter()]
    [string[]]
    $Name
  )

  Begin { }
  Process {
    If ($null -eq $Name) {
      $Name = Find-Module -DscResource * -Name * |
        Select-Object -ExpandProperty Name
    }

    ForEach ($NameToSearch in $Name) {
      $Response = Find-Module -Name $NameToSearch -AllVersions
      [PSCustomObject]@{
        Name     = $NameToSearch
        Releases = $Response.Version
      }
    }
  }
  End { }
}