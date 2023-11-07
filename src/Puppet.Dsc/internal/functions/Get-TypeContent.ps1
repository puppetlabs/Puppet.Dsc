function Get-TypeContent {
  <#
  .SYNOPSIS
    Return the text for a Puppet Resource API Type given a DSC Resouce.
  .DESCRIPTION
    Return the text for a Puppet Resource API Type given a DSC Resouce.
    It will return the text but _not_ directly write out the file.
  .PARAMETER DscResource
    A DSCResourceInfo object with the required parameter information
    retrieved - if the object does _not_ already have the updated info
    for the parameters, this function will attempt to retrieve it.
  .EXAMPLE
    Get-DscResourceTypeInformation -Name PSRepository | Get-TypeContent

    This will retrieve a DSC resource from the PSModulePath, retrieve the information
    needed to represent the DSC resource's properties as Puppet Resource API type
    attributes and then return the representation of that DSC resource appropriate
    for the Puppet Resource API.
  #>
  [cmdletbinding()]
  param (
    [OutputType([String], [String[]])]
    [Parameter(ValueFromPipeline)]
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]$DscResource
  )

  Begin {}

  Process {
    ForEach ($Resource in $DscResource) {
      If ($Null -eq $Resource.ParameterInfo) {
        $Resource = Get-DscResourceTypeInformation -DscResource $Resource
      }
      If ($Null -eq $Resource.FriendlyName) {
        $FriendlyName = $Resource.Name
      } Else {
        $FriendlyName = $Resource.FriendlyName
      }
      # We add an ensurable property to all DSC resources that don't have an ensure property
      $ResourceIsEnsurable = ($Resource.ParameterInfo | Select-Object -ExpandProperty Name).Contains('ensure')
      $NotEnsurable = [pscustomobject]@{
        Name              = 'ensurable'
        DefaultValue      = 'false'
        Type              = "Boolean['false']"
        Help              = 'Default attribute added to all dsc types without an ensure property. This resource is not ensurable.'
        mandatory_for_get = 'false'
        mandatory_for_set = 'false'
        is_parameter      = 'false'
        is_namevar        = 'false'
        mof_is_embedded   = 'false'
        mof_type          = 'String'
      }
      # We only add the ensurable property if it's not already present
      If (!$ResourceIsEnsurable) {
        $Resource.ParameterInfo += $NotEnsurable
      }
      # It is not *currently* possible to reliably programmatically retrieve
      # the description information for a DSC Resource via CIM instances or
      # Get-DscResource or Get-Help.
      $ResourceDescription = @(
        "The DSC $FriendlyName resource type."
        "Automatically generated from version $($Resource.Version)"
      ) -join "`n         "
      New-Object -TypeName System.String @"
require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'dsc_$($Resource.Name.ToLowerInvariant())',
  dscmeta_resource_friendly_name: '$FriendlyName',
  dscmeta_resource_name: '$($Resource.ResourceType)',
  dscmeta_resource_implementation: '$($Resource.ResourceImplementation)',
  dscmeta_module_name: '$($Resource.ModuleName)',
  dscmeta_module_version: '$($Resource.Version)',
  docs: $(ConvertTo-PuppetRubyString $ResourceDescription),
  features: ['simple_get_filter', 'canonicalize', 'custom_insync'],
  attributes: {
    name: {
      type:      'String',
      desc:      'Description of the purpose for this resource declaration.',
      behaviour: :namevar,
    },
    validation_mode: {
      type:      'Enum[property, resource]',
      desc:      'Whether to check if the resource is in the desired state by property (default) or using Invoke-DscResource in Test mode (resource).',
      behaviour: :parameter,
      default:   'property',
    },
$((Get-TypeParameterContent -ParameterInfo $Resource.ParameterInfo) -join "`n")
  },
)
"@
    }
  }

  End {}
}
