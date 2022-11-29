Function Get-CimClassPropertiesList {
  <#
    .SYNOPSIS
      Retrieve an iterable list of CIM Class properties
    .DESCRIPTION
      Retrieve an iterable list of CIM Class properties, by default from the
      DSC namespace, for introspecting to define as a Puppet Type.
    .PARAMETER ClassName
      The CIM Class name to look up; for DSC Resources, usually the ResourceType
      for that DSC resource, as surfaced by Get-DscResource.
    .PARAMETER Namespace
      The CIM namespace to look in; by default, the root DSC namespace.
    .EXAMPLE
      Get-CimClassPropertiesList -ClassName NTFSAccessEntry

      This command will look in the DSC namespace for the NTFSAccessEntry CIM
      Class and, if loaded, return its properties as an iterable array.
  #>
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ClassName,
    [string]$Namespace = 'root\Microsoft\Windows\DesiredStateConfiguration'
  )

  Begin {}

  Process {
    # For some reason, the base list is not iterable, so make it an iterable variable
    Get-CimClass -ClassName $ClassName -Namespace $Namespace |
      Select-Object -ExpandProperty CimClassProperties |
      ForEach-Object { $_ }
  }

  End {}
}
