Function Get-UnpuppetizedDscModuleVersion {
  <#
  .SYNOPSIS
    Search for versions of a PowerShell module not released to a Puppet feed
  .DESCRIPTION
    Search a PowerShell repository and Puppet forge feed feed to discover any
    versions of one or modules which have been released to the PowerShell
    repository but not yet Puppetized and published to the Puppet Forge. If
    a module has not been Puppetized at all, returns *all* discovered versions
    of that module from the PowerShell repository.
  .PARAMETER ForgeNameSpace
    The namespace on the Forge to search for modules
  .PARAMETER Name
    The name of one or more PowerShell modules to search for. If no name is
    specified, will compare all PowerShell modules with DSC Resources in the
    specified Repository to the Forge to find unpuppetized module versions.
  .PARAMETER MinimumVersion
    The minimum version to return; any released versions equal to or newer
    than this which have been published to the PowerShell repository but not
    the Puppet Forge will be returned.
  .PARAMETER OnlyNewer
    Only return versions of the PowerShell module on the PowerShell repository
    which are newer than the highest version release of the module in the
    Puppet Forge. Use to prevent building legacy versions if not needed.
  .PARAMETER Repository
    The PowerShell repository to search; defaults to the PowerShell Gallery
  .PARAMETER ForgeSearchUri
    The Puppet Forge API URI to search; defaults to the public Puppet Forge
  .EXAMPLE
    Get-UnpuppetizedDscModuleVersion -Name foo
    This will look for all versions of the foo module published to the
    PowerShell Gallery but not to the Puppet Forge in the 'dsc' namespace,
    including versions older than any currently Puppetized.
  .EXAMPLE
    Get-UnpuppetizedDscModuleVersion -Name foo -MinimumVersion 1.0
    This will look for all versions of the foo module published to the
    PowerShell Gallery but not to the Puppet Forge in the 'dsc' namespace,
    so long as they are newer than 1.0.0.0.
  .EXAMPLE
    Get-UnpuppetizedDscModuleVersion -Name foo -OnlyNewer
    This will look for all versions of the foo module published to the
    PowerShell Gallery but not to the Puppet Forge in the 'dsc' namespace,
    including only those versions newer than the latest published to the
    Puppet Forge.
  .EXAMPLE
    Get-UnpuppetizedDscModuleVersion -Name foo -Repository Internal -ForgeNameSpace my_company
    This will look for all versions of the foo module published to the
    'Internal' PowerShell repository but not to the Puppet Forge in the
    'my_company' namespace, including versions older than any currently Puppetized.
  .INPUTS
    None.
  .OUTPUTS
    [PSCustomObject] Returns an object with the Name property for the name of
    the module and Versions as an array of the module versions which have not
    been Puppetized and published to the Puppet Forge yet.
  #>

  [CmdletBinding()]
  param (
    [parameter(Mandatory)]
    [string]$ForgeNameSpace,
    [string[]]$Name,
    [string]$MinimumVersion,
    [switch]$OnlyNewer,
    [string]$Repository,
    [string]$ForgeSearchUri
  )

  Begin {
    $VersionsToReleaseFilterScript = { $_ -notin $VersionsReleasedToForge }

    If ($MinimumVersion) {
      $MinimumVersionFilterScript = { [version]$_ -ge [version](ConvertTo-StandardizedVersionString -Version $MinimumVersion) }
      $CombinedFilterScriptString = $VersionsToReleaseFilterScript.ToString(), $MinimumVersionFilterScript.ToString() -join ' -and '
      $VersionsToReleaseFilterScript = [scriptblock]::Create($CombinedFilterScriptString)
    }
    If ($OnlyNewer) {
      $OnlyNewerFilterScript = { [version]$_ -gt [version]$VersionsReleasedToForge[0] }
      $CombinedFilterScriptString = $VersionsToReleaseFilterScript.ToString(), $OnlyNewerFilterScript.ToString() -join ' -and '
      $VersionsToReleaseFilterScript = [scriptblock]::Create($CombinedFilterScriptString)
    }

    $GallerySearchParameters = @{}
    If (![string]::IsNullOrEmpty($Repository)) { $GallerySearchParameters.Repository = $Repository }
    If (![string]::IsNullOrEmpty($Name)) { $GallerySearchParameters.Name = $Name }

    $ForgeSearchParameters = @{
      ErrorAction = 'SilentlyContinue'
      ForgeNameSpace = $ForgeNameSpace
    }
    If (![string]::IsNullOrEmpty($ForgeSearchUri)) { $ForgeSearchParameters.ForgeSearchUri = $ForgeSearchUri }
  }

  Process {
    $GalleryModuleInfo = Get-PowerShellDscModule @GallerySearchParameters
    ForEach ($Module in $GalleryModuleInfo) {
      $VersionsToRelease = ConvertTo-StandardizedVersionString -Version $Module.Releases
      $ForgeSearchParameters.Name = Get-PuppetizedModuleName -Name $Module.Name
      $ForgeModuleInfo = Get-ForgeModuleInfo @ForgeSearchParameters
      If ($null -ne $ForgeModuleInfo) {
        $VersionsReleasedToForge = Get-LatestBuild $ForgeModuleInfo.Releases |
          Select-Object -ExpandProperty Version |
          ForEach-Object -Process { $_ -replace '-', '.' }
        $VersionsToRelease = $VersionsToRelease | Where-Object -FilterScript $VersionsToReleaseFilterScript
      } elseif (![string]::IsNullOrEmpty($MinimumVersion)) {
        $VersionsToRelease = $VersionsToRelease | Where-Object -FilterScript { [version]$_ -ge [version]$MinimumVersion }
      }

      If ($null -eq $VersionsToRelease) {
        Write-PSFMessage -Level Verbose -Message 'No releasable versions based on search criteria need to be published'
        continue
      }

      [PSCustomObject]@{
        Name     = $Module.Name
        Versions = $VersionsToRelease
      }
    }
  }

  End { }
}