Function Get-EmbeddedCimInstance {
  <#
    .SYNOPSIS
      Retrieve CIM instances discovered in a CIM Class's definition
    .DESCRIPTION
      Retrieve CIM instances discovered in a CIM Class's definition,
      returning their class names. Optionally, recurse through the
      list of CIM instances to discover more deeply nested classes.
    .PARAMETER ClassName
      The CIM Class name to look up; for DSC Resources, usually the ResourceType
      for that DSC resource, as surfaced by Get-DscResource.
    .PARAMETER Namespace
      The CIM namespace to look in; by default, the root DSC namespace.
    .PARAMETER Recurse
      If specified, will recursively search discovered embedded instances for
      any embedded instances they may contain, and so on.
    .EXAMPLE
      Get-EmbeddedCimInstance -ClassName NTFSAccessEntry -Recurse
      This command will look in the DSC namespace for the NTFSAccessEntry CIM
      Class and, if loaded, search through it for propereties which are CIM
      instances, then recursively search those classes for their own embedded
      instances, returning the full list of discovered CIM classes which were
      found to be embedded.
  #>
  param(
    [Parameter(Mandatory = $true)]
    [string]$ClassName,
    [string]$Namespace = 'root\Microsoft\Windows\DesiredStateConfiguration',
    [switch]$Recurse
  )

  Begin {}

  Process {
    [string[]]$EmbeddedInstanceTypes = Get-CimClassPropertiesList -ClassName $ClassName -Namespace $Namespace |
      Select-Object -ExpandProperty Qualifiers |
      Where-Object -FilterScript { $_.Name -eq 'EmbeddedInstance' } |
      Select-Object -ExpandProperty Value
    If ($Recurse) {
      ForEach ($EmbeddedInstanceType in $EmbeddedInstanceTypes) {
        $EmbeddedInstanceTypes += Get-EmbeddedCimInstance -ClassName $EmbeddedInstanceType -Namespace $Namespace -Recurse
      }
    }
    # Sometimes a null gets added to the list for some reason, but only in testing; discard null values
    $EmbeddedInstanceTypes | Where-Object { ![string]::IsNullOrEmpty($_) }
  }

  End {}
}
