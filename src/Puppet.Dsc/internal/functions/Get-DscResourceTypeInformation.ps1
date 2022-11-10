Function Get-DscResourceTypeInformation {
  <#
    .SYNOPSIS
      Collate the information about a DSC resource for building a Puppet resource_api type.

    .DESCRIPTION
      This function leverages the Get-DscResource command and the AST for DSC Resources implemented
      in PowerShell to return additional information about the DSC Resource for building a Puppet
      resource_api compliant Type, including retrieving help info, default values, and mandatory status.

    .PARAMETER DscResource
      The DscResourceInfo object to introspect; can be passed via the pipeline, normally retrieved
      via calling Get-DscResource.

    .PARAMETER Name
      If not passing a full object, specify the name of the DSC Resource to retrieve and introspect.

    .PARAMETER Module
      If not passing a full object, specify the module name of the the DSC Resource to retrieve and introspect.
      Can be either a string or a hash containing the keys ModuleName and ModuleVersion.

    .EXAMPLE
      Get-DscResource -Name PSRepository | Get-DscResourceTypeInformation

      Retrieve the information necessary for generating a Puppet Resource API type from a DSC Resource object.

    .EXAMPLE
      Get-DscResourceTypeInformation -DscResourceName PSRepository

      Retrieve the information necessary for generating a Puppet Resource API type by searching for a DSC
      resource object via Get-DscResource. Will ONLY find the resource if it is in the PSModulePath.

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

  Begin {
    $RunningElevated = Test-RunningElevated
  }

  Process {
    # Retrieve the DSC Resource information from the system unless passed directly
    If ($null -eq $DscResource) {
      if ($null -eq $Module) {
        $DscResourceToProcess = Get-DscResource -Name $Name -ErrorAction Stop
      } else {
        $DscResourceToProcess = Get-DscResource -Name $Name -Module $Module -ErrorAction Stop
      }
    } Else {
      $DscResourceToProcess = $DscResource
    }

    # Ensure we know the DSC Resource Type; unfortunately, DSC does not distinguish
    # between MOF-based DSC Resources and Class-based DSC Resources, they are both
    # designated ImplementedAs 'PowerShell' - updating the resource in place here
    # can happen regardless of PowerShell version or administrative privileges.
    $null = $DscResourceToProcess | Get-DscResourceImplementation -ModifyResource

    ForEach ($Resource in $DscResourceToProcess) {
      $Value = If ($RunningElevated -and ($Resource.ImplementedAs -ne 'Composite')) {
        Get-DscResourceParameterInfoByCimClass -DscResource $Resource
      } Else {
        Get-DscResourceParameterInfo -DscResource $Resource
      }
      $Parameters = @{
        MemberType = 'NoteProperty'
        Name       = 'ParameterInfo'
        Value      = $Value
        PassThru   = $True
      }
      $Resource | Add-Member @Parameters
    }
  }

  End {}
}