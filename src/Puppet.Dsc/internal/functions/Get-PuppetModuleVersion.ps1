Function Get-PuppetModuleVersion {
  <#
    .SYNOPSIS
      Get a valid Puppet module version from a PowerShell version object
    .DESCRIPTION
      Get a valid Puppet module version from a PowerShell version object, writing a string which
      adds prerelease text for the revision version (if any), and a fifth digit representing the
      build version, starting at 0.
    .PARAMETER Version
      The PowerShell version to base the Puppet version on.
    .PARAMETER BuildNumber
      The build number for the generated module.
    .EXAMPLE
      Get-PuppetModuleVersion -Version 1.2.3

      This will return '1.2.3-0-0' as the valid Puppet module version mapping to the specified PowerShell.
    .EXAMPLE
      Get-PuppetModuleVersion -Version 1.2.3.4

      This will return '1.2.3-4-0' as the valid Puppet module version mapping to the specified PowerShell.
    .EXAMPLE
      Get-PuppetModuleVersion -Version 1.2.3 -BuildNumber 3

      This will return '1.2.3-0-3' as the valid Puppet module version mapping to the specified PowerShell.
  #>
  [cmdletbinding()]
  [OutputType([String])]
  Param (
    [version]$Version,
    [int]$BuildNumber = 0
  )
  $PuppetVersion = [PSCustomObject]@{
    Major    = $Version.Major
    Minor    = $Version.Minor
    Build    = $Version.Build
    Revision = $Version.Revision
  }
  If ($PuppetVersion.Minor -lt 0) { $PuppetVersion.Minor = 0 }
  If ($PuppetVersion.Major -lt 0) { $PuppetVersion.Major = 0 }
  If ($PuppetVersion.Build -lt 0) { $PuppetVersion.Build = 0 }
  If ($PuppetVersion.Revision -lt 0) { $PuppetVersion.Revision = 0 }
  "$($PuppetVersion.Major).$($PuppetVersion.Minor).$($PuppetVersion.Build)-$($PuppetVersion.Revision)-$BuildNumber"
}
