Function ConvertTo-VersionBuild {
  <#
  .SYNOPSIS
    Turn a valid Puppet DSC Module version string into a VersionBuild object
  .DESCRIPTION
    Turn a valid Puppet DSC Module version string into a VersionBuild object for
    easier comparison of latest build versions.
  .EXAMPLE
    ConvertTo-VersionBuild -Version '1.2.3-4-5'
    This will return a PSCustomObject with the version property set to '1.2.3-4'
    and the Build property set to 5.
  .INPUTS
    [string[]] The Puppet DSC Module version string to convert
  .OUTPUTS
    [PSCustomObject[]] An object with the version and build properties
  #>
  [CmdletBinding()]
  param (
    [Parameter()]
    [String[]]
    $Version
  )

  Begin { }
  Process {
    $Version | ForEach-Object -Process {
      $null = $_ -match '(?<Version>\d+\.\d+\.\d+-\d+)-(?<Build>\d+$)'
      [pscustomobject]@{
        Version = [version]($Matches.Version -replace '-', '.')
        Build   = [int]($Matches.Build)
      }
    } | Sort-Object -Descending -Property Version, Build | ForEach-Object -Process {
      $_.Version = [string]($_.Version) -replace '\.(\d+)$', '-$1'
      $_
    }
  }
  End { }
}