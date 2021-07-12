Function Set-PuppetModuleVersion {
  <#
  .SYNOPSIS
    Set the version of a Puppet module
  .DESCRIPTION
    Set the version of a Puppet module by modifying its metadata
  .PARAMETER PuppetModuleFolderPath
    The path, relative or absolute, to the folder containing the Puppet module
  .PARAMETER Version
    The version string to set the Puppet module's metadata version to
  .EXAMPLE
    Set-PuppetModuleVersion -PuppetModuleFolderPath ./import/foo -Version 1.2.3-0-0
    This will set the module in ./import/foo to version '1.2.3-0-0'
  .INPUTS
    None.
  .OUTPUTS
    None.
  #>
  [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PuppetModuleFolderPath,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Version
  )

  Begin {
    Try {
      $ErrorActionPreference = 'Stop'
      $PuppetMetadataJsonPath = Join-Path -Path $PuppetModuleFolderPath -ChildPath 'metadata.json' |
        Resolve-Path |
        Select-Object -ExpandProperty Path
      $PuppetMetadata = Get-Content -Path $PuppetMetadataJsonPath -Raw |
        ConvertFrom-Json
    } Catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }

  Process {
    Try {
      $ErrorActionPreference = 'Stop'
      $PuppetMetadata.version = $Version
      $PuppetMetadataJson = ConvertTo-UnescapedJson -InputObject $PuppetMetadata -Depth 10
      If ($PSCmdlet.ShouldProcess($PuppetMetadataJsonPath, "Overwriting Puppet module metadata version to '$Version'")) {
        Out-Utf8File -Path $PuppetMetadataJsonPath -InputObject $PuppetMetadataJson
      }
    } Catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }

  End { }
}