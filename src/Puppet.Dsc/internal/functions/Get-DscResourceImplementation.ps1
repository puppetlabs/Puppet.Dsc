Function Get-DscResourceImplementation {
  <#
    .SYNOPSIS
      Determine the granular implementation of a DSC Resource

    .DESCRIPTION
      This function leverages the Get-DscResource command and a generative scriptblock to determine
      whether a DSC Resource with an `ImplementedAs` value of `PowerShell` is class-based or mof-based
      and, for other values of `ImplementedAs`, returns those values directly. If the `ModifyResource`
      switch is passed, this function returns the full DSC Resource info object with a new note property,
      `ResourceImplementation`, which is the value normally returned from this function.

    .PARAMETER DscResource
      The DscResourceInfo object to introspect; can be passed via the pipeline, normally retrieved
      via calling Get-DscResource.

    .PARAMETER Name
      If not passing a full object, specify the name of the DSC Resource to retrieve and introspect.

    .PARAMETER Module
      If not passing a full object, specify the module name of the the DSC Resource to retrieve and introspect.
      Can be either a string or a hash containing the keys ModuleName and ModuleVersion.

    .PARAMETER ModifyResource
      If this switch is specified the function adds the implementation type as the `ResourceImplementation`
      note property to the DSC Resource info object being inspected.

    .EXAMPLE
      Get-DscResource -Name PSRepository | Get-DscResourceImplementation

      Return the implementation for PSRepository as a string

    .EXAMPLE
      Get-DscResource -Name PSRepository | Get-DscResourceImplementation

      Return the DSC Resource info object for PSRepository with the `ResourceImplementation`
      note property added to it.

    .EXAMPLE
      Get-DscResourceImplementation -DscResourceName PSRepository

      Return the implementation for PSRepository as a string, retrieving the DSC Resource info via
      `Get-DscResource`. Will ONLY find the resource if it is in the PSModulePath.

    .NOTES
      This function currently takes EITHER:

      1. A DscResource Object, as passed by Get-DSCResource
      2. A combo of name/module to retrieve DSC Resources from
  #>
  [CmdletBinding(
    DefaultParameterSetName = 'ByObject'
  )]
  [OutputType([String], [String[]])]
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
    [object]$Module,
    [switch]$ModifyResource
  )

  Begin { }

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
    ForEach ($Resource in $DscResourceToProcess) {
      If ($Resource.ImplementedAs -eq 'PowerShell') {
        $Module = Resolve-Path -Path $Resource.Path
        $ScriptBlock = [ScriptBlock]::Create("
          using module '$Module'
          Try {
            `$ErrorActionPreference = 'Stop'
            `$null = [$($Resource.Name)]
            'Class'
          } Catch {
            'MOF'
          }
          # If ('$($Resource.Name)' -as [type]) {
          #   'Class'
          # } Else {
          #   'MOF'
          # }
        ")
        $ClassTestJob = Start-Job -ScriptBlock $ScriptBlock | Wait-Job

        $DscResourceImplementation = $ClassTestJob.ChildJobs[0].Output
      } Else {
        $DscResourceImplementation = $Resource.ImplementedAs
      }
      If ($ModifyResource) {
        $Parameters = @{
          MemberType = 'NoteProperty'
          Name       = 'ResourceImplementation'
          Value      = $DscResourceImplementation
          PassThru   = $True
        }
        $Resource | Add-Member @Parameters
      } Else {
        [string]$DscResourceImplementation
      }
    }
  }

  End {}
}