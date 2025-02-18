function Get-ProviderContent {
  <#
  .SYNOPSIS
    Return the text for a Puppet Resource API provider given a DSC Resouce.
  .DESCRIPTION
    Return the text for a Puppet Resource API provider given a DSC Resouce.
    It will return the text but _not_ directly write out the file.
  .PARAMETER DscResource
    A DSCResourceInfo object, as retrieved by Get-DscResource.
  .EXAMPLE
    Get-DscResource -Name PSRepository | Get-ProviderContent

    This will retrieve a DSC resource from the PSModulePath and return the
    representation of that DSC resource appropriate for the Puppet Resource API.
  #>
  [cmdletbinding()]
  param (
    [Parameter(ValueFromPipeline)]
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]$DscResource
  )

  Begin {}

  Process {
    ForEach ($Resource in $DscResource) {
      # Ensure the Name is lower case except for the first character to conform to puppet/ruby naming conventions;
      # Prepend with Dsc for namespacing considerations.
      $Name = 'Dsc' + (Get-Culture).TextInfo.ToTitleCase($Resource.Name)
      $Name = $Name -replace '[_]'
      New-Object -TypeName System.String @"
require_relative '../../../../../pwshlib/lib/puppet/provider/dsc_base_provider/dsc_base_provider'

# Implementation for the dsc_type type using the Resource API.
class Puppet::Provider::$Name::$Name < Puppet::Provider::DscBaseProvider
end
"@
    }
  }

  End {}

}
