<#
.SYNOPSIS
  Turn a .NET Version into a four-segment version string
.DESCRIPTION
  Turn a .NET Version into a four-segment version string, turning -1 into 0 if needed.
.EXAMPLE
  [version]'1.2' | ConvertTo-StandardizedVersionString
  This will take the version representation of '1.2' and turn it into '1.2.0.0'
.INPUTS
  System.Version the version to standardize
.OUTPUTS
  System.String the four-segment version string
#>
Function ConvertTo-StandardizedVersionString {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [version[]]
    $Version
  )
  Begin {}
  Process {
    ForEach ($VersionToProcess in $Version) {
      $StandardizedVersion = @{}
      ForEach ($Segment in @('Major', 'Minor', 'Build', 'Revision')) {
        If ($VersionToProcess.$Segment -ne -1) {
          $StandardizedVersion.$Segment = $VersionToProcess.$Segment
        } Else {
          $StandardizedVersion.$Segment = 0
        }
      }
      "$($StandardizedVersion.Major).$($StandardizedVersion.Minor).$($StandardizedVersion.Build).$($StandardizedVersion.Revision)"
    }
  }
  End { }
}