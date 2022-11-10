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
  .PARAMETER Repository
    The PowerShell repository to search; defaults to the PowerShell Gallery
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
    [string[]]$Name,
    [string]$Repository = 'PSGallery'
  )

  Begin { }
  Process {
    If ($null -eq $Name) {
      Write-PSFMessage -Level Verbose -Message "Searching the $Repository for all modules with DSC Resources"
      $Name = Find-Module -Repository $Repository -DscResource * -Name * |
        Select-Object -ExpandProperty Name
    }

    ForEach ($NameToSearch in $Name) {
      try {
        Write-PSFMessage -Level Verbose -Message "Searching the $Repository for all versions of the $NameToSearch module with DSC Resources"
        $Response = Find-Module -Repository $Repository -DscResource * -Name $NameToSearch -AllVersions -ErrorAction Stop
        [PSCustomObject]@{
          Name     = $NameToSearch
          Releases = $Response.Version
        }
      } catch {
        $PSCmdlet.WriteError($PSItem)
      }
    }
  }
  End { }
}