Function Get-ShortType {
  <#
    .SYNOPSIS
      Strip a type of it's brackets
    .DESCRIPTION
      Strip a PowerShell type of the brackets, turning [string] and [string[]] into string and string[]
      This makes inserting the type back into PowerShell a little easier.
    .PARAMETER PropertyType
      THe property type of a DSC resource property
    .EXAMPLE
      Get-ShortType -PropertyType $DscResource.Properties[0].PropertyType

      This will return a string representing the property type stripped of its outer brackets
  #>
  [cmdletbinding()]
  [OutputType([String])]
  Param (
    [string]$PropertyType
  )
  if ($PropertyType.StartsWith('[') -and $PropertyType.EndsWith(']')) {
    $ShortType = $PropertyType.Substring(1, $PropertyType.Length - 2)
  } else {
    $ShortType = $PropertyType
  }
  $ShortType
}
