Function ConvertFrom-VersionBuild {
  <#
  .SYNOPSIS
    Turn a VersionBuild object into a Puppet DSC Module version string
  .DESCRIPTION
    Turn a VersionBuild object into a Puppet DSC Module version string
  .EXAMPLE
    ConvertFrom-VersionBuild -VersionBuild [PSCustomObject]@{Version = '1.2.3-0' ; Build = 3}
    This will turn the input object into the string '1.2.3-0-3'
  .INPUTS
    [PSCustomObject[]] One or more VersionBuild objects to convert
  .OUTPUTS
    [String[]] The converted Puppet DSC Module version strings
  #>
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [object[]]
    $VersionBuild
  )

  Begin { }
  Process {
    $VersionBuild | ForEach-Object -Process {
      "$($_.Version)-$($_.Build)"
    }
  }
  End { }
}