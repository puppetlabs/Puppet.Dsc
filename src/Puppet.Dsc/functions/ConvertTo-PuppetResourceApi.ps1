Function ConvertTo-PuppetResourceApi {
  <#
    .SYNOPSIS
      Collate the information about a DSC resource for building a Puppet resource_api type and provider

    .DESCRIPTION
      This function takes a DSC resource and returns the representation of that resource for the Puppet
      Resource API types and providers as a PowerShell object for further use.

    .PARAMETER DscResource
      The DscResourceInfo object to convert; can be passed via the pipeline, normally retrieved
      via calling Get-DscResource.

    .PARAMETER Name
      If not passing a full object, specify the name of the DSC Resource to retrieve and convert.

    .PARAMETER Module
      If not passing a full object, specify the module name of the the DSC Resource to retrieve and convert.
      Can be either a string or a hash containing the keys ModuleName and ModuleVersion.

    .EXAMPLE
      Get-DscResource -Name PSRepository | ConvertTo-PuppetResourceApi -OutVariable Foo

      Retrieve the representation of a Puppet Resource API type and provider from a DSC Resource object.

    .EXAMPLE
      ConvertTo-PuppetResourceApi -Name PSRepository

      Retrieve the representation of a Puppet Resource API type by searching for a DSC resource object via
      Get-DscResource. Will ONLY find the resource if it is in the PSModulePath.

    .NOTES
      This function currently takes EITHER:

      1. A DscResource Object, as passed by Get-DSCResource
      2. A combo of name/module to retrieve DSC Resources from
  #>
  [CmdletBinding(
    DefaultParameterSetName = 'ByObject'
  )]
  Param(
    [Parameter(
      ValueFromPipeline,
      ParameterSetName = 'ByObject'
    )]
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]$DscResource,

    [Parameter(
      ValueFromPipelineByPropertyName,
      ParameterSetName = 'ByProperty'
    )]
    [string[]]$Name,

    [Parameter(
      ValueFromPipelineByPropertyName,
      ParameterSetName = 'ByProperty'
    )]
    [object]$Module
  )

  Begin {}

  Process {
    # Retrieve the DSC Resource information from the system unless passed directly
    If ($null -eq $DscResource) {
      if ($null -eq $Module) {
        $DscResourceToProcess = Get-DscResourceTypeInformation -Name $Name
      } else {
        $DscResourceToProcess = Get-DscResourceTypeInformation -Name $Name -Module $Module
      }
    } Else {
      $DscResourceToProcess = $DscResource
      If ($null -eq $DscResourceToProcess.ParameterInfo) { $DscResourceToProcess = Get-DscResourceTypeInformation -DscResource $DscResourceToProcess }
    }
    ForEach ($Resource in $DscResourceToProcess) {
      $PuppetizedName = "dsc_$($Resource.Name.ToLowerInvariant())"
      [PSCustomObject]@{
        Name         = $PuppetizedName
        RubyFileName = "$PuppetizedName.rb"
        Version      = [string]$Resource.Version
        Type         = Get-TypeContent -DscResource $Resource
        Provider     = Get-ProviderContent -DscResource $Resource
      }
    }
  }

  End {}
}
