Function Get-LatestBuild {
  <#
  .SYNOPSIS
    Get latest builds in a collection of Puppet DSC Module versions
  .DESCRIPTION
    Get latest builds in a collection of Puppet DSC Module versions. Converts
    a list of Puppet DSC Module versions from strings (e.g. '1.2.3-0-0') into
    VersionBuild objects, only returning the latest build for each version.
  .EXAMPLE
    Get-LatestBuild -Version '1.2.3-0-0', '1.2.3-0-1'
    This will return a VersionBuild object with the version property set to
    '1.2.3-0' and the build property set to 1.
  .INPUTS
    [string[]] One or more valid Puppet DSC Module string versions with dot-
    separated major/minor/patch versions, dash separated revision, and dash-
    separated build version, like '1.2.3-0-0'
  .OUTPUTS
    [PSCustomObject[]] One or more VersionBuild objects representing the latest
    builds for each input version specified.
  #>
  [CmdletBinding()]
  param (
    [Parameter()]
    [String[]]
    $Version
  )
  Begin { }
  Process {
    $VersionAndBuild = ConvertTo-VersionBuild -Version $Version
    $VersionAndBuild.version |
      Select-Object -Unique |
      ForEach-Object -Process {
        $VersionAndBuild |
          Where-Object -Property Version -EQ $_ |
          Sort-Object -Property Build -Descending |
          Select-Object -First 1
        }
  }
  End { }
}