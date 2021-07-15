Function Get-ForgeModuleInfo {
  <#
  .SYNOPSIS
    Search a Puppet forge for modules with DSC Resources
  .DESCRIPTION
    Search a Puppet forge for modules with DSC Resources, returning their name,
    every release of that module, and the module's PowerShell metadata.
  .PARAMETER Name
    The name of the module to search for on the Forge. If left unspecified, will
    search the entire namespace for modules.
  .PARAMETER ForgeUri
    The URI to the forge api for retrieving modules; by default, the public
    Puppet forge (v3).
  .PARAMETER ForgeNameSpace
    The namespace on the Forge to search inside; by default, 'dsc'.
  .PARAMETER PaginationBump
    If searching a namespace for modules, indicates the number of modules to return
    in a single result set, continuing to search until no more modules are discovered.
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

  [CmdletBinding(DefaultParameterSetName = 'ByNameSpace')]
  [OutputType([System.Object[]])]
  param (
    [Parameter(ParameterSetName = 'ByName')]
    [string[]]$Name,
    [Parameter(ParameterSetName = 'ByName')]
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [string]$ForgeUri = 'https://forgeapi.puppet.com/v3/modules',
    [Parameter(ParameterSetName = 'ByName')]
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [string]$ForgeNameSpace = 'dsc',
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [int]$PaginationBump = 5
  )

  Begin {
    $ForgeSearchParameters = @{
      Method          = 'Get'
      UseBasicParsing = $True
    }
  }

  Process {
    if ([string]::IsNullOrEmpty($Name)) {
      # Retrieve all modules in the Forge NameSpace
      $ForgeSearchParameters.Uri = $ForgeUri
      $ForgeSearchParameters.Body = @{
        owner  = $ForgeNameSpace
        limit  = $PaginationBump
        offset = 0
      }
      [System.Collections.Generic.List[PSCustomObject]]$Results = @()

      do {
        $Response = Invoke-RestMethod @ForgeSearchParameters
        ForEach ($Result in $Response.results) {
          $null = $Results.Add([PSCustomObject]@{
              Name                 = $Result.name
              Releases             = $Result.releases.version
              PowerShellModuleInfo = $Result.current_release.metadata.dsc_module_metadata
            })
        }
        $ForgeSearchParameters.body.offset += $PaginationBump
      } until ($null -eq $Response.Pagination.Next)

      $Results
    } else {
      # Return only specified modules in the forge namespace
      $UriBase = "$ForgeUri/$ForgeNameSpace-"
      foreach ($Module in $Name) {
        try {
          $ForgeSearchParameters.Uri = "${UriBase}$(Get-PuppetizedModuleName $Module)"
          Write-PSFMessage -Level Verbose -Message "Searching the forge with the following parameters:`n$($ForgeSearchParameters | ConvertTo-Json -Depth 5)"
          $Result = Invoke-RestMethod @ForgeSearchParameters -ErrorAction Stop

          [PSCustomObject]@{
            Name                 = $Result.name
            Releases             = $Result.releases.version
            PowerShellModuleInfo = $Result.current_release.metadata.dsc_module_metadata
          }
        } catch {
          $PSCmdlet.WriteError($PSItem)
        }
      }
    }
  }

  End { }
}