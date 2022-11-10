function Update-PuppetModuleReadme {
  <#
    .SYNOPSIS
      Update Puppet module readme with PowerShell Module Manifest metadata.
    .DESCRIPTION
      Update Puppet module readme with PowerShell Module Manifest metadata and useful information about the vendored modules.
    .PARAMETER PuppetModuleFolderPath
      The path to the root folder of the Puppet module.
    .PARAMETER PuppetModuleName
      The name of the Puppet module
    .PARAMETER PowerShellModuleManifestPath
      The full path to the PowerShell module's manifest file.
    .PARAMETER PowerShellModuleName
      The name of the PowerShell module
    .PARAMETER Confirm
      Prompts for confirmation before overwriting the file
    .PARAMETER WhatIf
      Shows what would happen if the function runs.
    .EXAMPLE
      Update-PuppetModuleReadme -PuppetModuleFolderPath ./import/powershellget -PowerShellModuleManifestPath ./mymodule.psd1
      This command will update `./import/powershellget/README.md` based on the metadata from `./mymodule.psd1`.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PowerShellModuleManifestPath,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PowerShellModuleName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PuppetModuleFolderPath,
    [string]$PuppetModuleName
  )

  begin {
    Try {
      $PuppetReadmeFilePath = Resolve-Path (Join-Path $PuppetModuleFolderPath 'README.md') -ErrorAction Stop
      $PowerShellModuleManifestPath = Resolve-Path -Path $PowerShellModuleManifestPath -ErrorAction Stop
      $PowerShellMetadata = Import-PSFPowerShellDataFile -Path $PowerShellModuleManifestPath -ErrorAction Stop
    } Catch {
      # Rethrow any exceptions from the above commands
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }

    If ([string]::IsNullOrEmpty($PuppetModuleName)) {
      $PuppetModuleName = Get-PuppetizedModuleName -Name $PowerShellModuleName
    }
  }

  process {
    $ReadmeParameters = @{
      PowerShellModuleName        = $PowerShellModuleName
      PowerShellModuleDescription = $PowerShellMetadata.Description
      PowerShellModuleGalleryUri  = "https://www.powershellgallery.com/packages/$PowerShellModuleName/$($PowerShellMetadata.ModuleVersion)"
      PowerShellModuleProjectUri  = $PowerShellMetadata.PrivateData.PSData.ProjectUri
      PowerShellModuleVersion     = $PowerShellMetadata.ModuleVersion
      PuppetModuleName            = $PuppetModuleName
    }
    $ReadmeContent = Get-ReadmeContent @ReadmeParameters
    If ($PSCmdlet.ShouldProcess($PuppetModuleMetadataFilePath, 'Overwrite Puppet Module Readme')) {
      Out-Utf8File -Path $PuppetReadmeFilePath -InputObject $ReadmeContent
    }
  }

  end {}
}