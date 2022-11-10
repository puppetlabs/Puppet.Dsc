function Update-PuppetModuleChangelog {
  <#
    .SYNOPSIS
      Update Puppet module changelog via the PowerShell Module
    .DESCRIPTION
      Update Puppet module changelog via PowerShell Module Manifest's release notes or changelog file.
    .PARAMETER PuppetModuleFolderPath
      The path to the root folder of the Puppet module.
    .PARAMETER PowerShellModuleManifestPath
      The full path to the PowerShell module's manifest file.
    .PARAMETER Confirm
      Prompts for confirmation before overwriting the file
    .PARAMETER WhatIf
      Shows what would happen if the function runs.
    .EXAMPLE
      Update-PuppetModulechangelog -PuppetModuleFolderPath ./import/powershellget -PowerShellModuleManifestPath ./mymodule.psd1
      This command will update `./import/powershellget/CHANGELOG.md` based on the the release notes in `./mymodule.psd1`;
      if no release notes can be found, it will look for a changelog file in the same path and use that instead;
      if neither  the changelog nor release notes can be found, the changelog will remain untouched.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param (
    [string]$PowerShellModuleManifestPath,
    [string]$PuppetModuleFolderPath
  )

  begin {
    Try {
      $PuppetChangelogFilePath = Resolve-Path (Join-Path $PuppetModuleFolderPath 'CHANGELOG.md') -ErrorAction Stop
      $PowerShellModuleManifestPath = Resolve-Path -Path $PowerShellModuleManifestPath -ErrorAction Stop
      $PowerShellModuleChangelogPath = Resolve-Path -Path (Join-Path (Split-Path -Parent $PowerShellModuleManifestPath) 'CHANGELOG.md') -ErrorAction SilentlyContinue
      $PowerShellMetadata = Import-PSFPowerShellDataFile -Path $PowerShellModuleManifestPath -ErrorAction Stop
    } Catch {
      # Rethrow any exceptions from the above commands
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }

  process {
    If ([string]::IsNullOrEmpty($PowerShellModuleChangelogPath)) {
      $ReleaseNotes = $PowerShellMetadata.PrivateData.PSData.ReleaseNotes
      If ($ReleaseNotes.length -gt 0) {
        $ChangelogContent = $ReleaseNotes
      }
    } Else {
      $ChangelogContent = Get-Content $PowerShellModuleChangelogPath
    }
    If ($ChangelogContent) {
      If ($PSCmdlet.ShouldProcess($PuppetChangelogFilePath, 'Overwrite Puppet Module Changelog')) {
        Out-Utf8File -Path $PuppetChangelogFilePath -InputObject $ChangelogContent
      }
    }
  }

  end {}
}
