function Get-PuppetizedModuleName {
  <#
  .SYNOPSIS
    Get a valid puppet module name from a PowerShell Module name
  .DESCRIPTION
    Get a valid puppet module name from a PowerShell Module name
  .PARAMETER Name
    The name of the PowerShell module you want to puppetize
  .EXAMPLE
    Get-PuppetizedModuleName -Name Azure.Something.Or.Other

    This will return 'azure_something_or_other', which is a valid
    Puppet module name.
  #>
  [cmdletbinding()]
  [OutputType([String])]
  param (
    [string]$Name
  )

  Begin {}

  Process {
    # Puppet module names must be lowercase:
    $PuppetizedName = $Name.ToLowerInvariant()
    # Puppet module names may only include lowercase letters, digits, and underscores
    $PuppetizedName = $PuppetizedName -replace '[^a-z0-9_]', '_'
    If ($PuppetizedName -match '^\d') {
      # This is a... not good compromise, but it works
      "a$PuppetizedName"
    } Else {
      $PuppetizedName
    }
  }

  End {}
}
