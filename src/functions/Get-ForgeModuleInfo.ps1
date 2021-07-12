Function Get-ForgeModuleInfo {
  <#
  .SYNOPSIS
    Search a Puppet forge for modules with DSC Resources
  .DESCRIPTION
    Search a Puppet forge for modules with DSC Resources, returning their name,
    every release of that module, and the module's PowerShell metadata.
  .PARAMETER Name
    The name of the module to search for on the Forge
  .PARAMETER ForgeUri
    The URI to the forge api for retrieving modules; by default, the public
    Puppet forge (v3).
  .PARAMETER ForgeNameSpace
    The namespace on the Forge to search inside; by default, 'dsc'.
  .EXAMPLE
    Get-ForgeModuleInfo -Name powershellget
    Search the DSC namespace of the Puppet Forge for the powershellget module,
    returning it (if it exists) with the list of releases and the metadata for
    the PowerShell module it was built from.
  .INPUTS
    None.
  .OUTPUTS
    [PSCustomObject[]] One or more objects with the name, releases, and the
    PowerShellModuleInfo properties.
  #>

  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string[]]
    $Name,
    $ForgeUri = 'https://forgeapi.puppet.com/v3/modules',
    $ForgeNameSpace = 'dsc'
  )

  Begin {
    $UriBase = "$ForgeUri/$ForgeNameSpace-"

    $ModuleSearchParameters = @{
      Method          = 'Get'
      UseBasicParsing = $True
    }
  }
  Process {
    foreach ($Module in $Name) {
      $ModuleSearchParameters.Uri = "${UriBase}$(Get-PuppetizedModuleName $Module)"
      $Result = Invoke-RestMethod @ModuleSearchParameters

      [PSCustomObject]@{
        Name                 = $Result.name
        Releases             = $Result.releases.version
        PowerShellModuleInfo = $Result.current_release.metadata.dsc_module_metadata
      }
    }
  }
  End { }
}