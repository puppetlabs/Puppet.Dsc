function Initialize-PuppetModule {
  <#
    .SYNOPSIS
      Scafold a Puppet module
    .DESCRIPTION
      Scaffold a Puppet module and copy over static files.
    .PARAMETER OutputFolderPath
      The path, relative or literal, to the Puppet module's root folder.
    .PARAMETER PuppetModuleName
      The name of the Puppet module to create.
    .PARAMETER PDKTemplateRef
      Specifies the template git branch or tag to use when creating new moudles or classes.
    .PARAMETER Confirm
      Prompts for confirmation before overwriting the file
    .PARAMETER WhatIf
      Shows what would happen if the function runs.
    .EXAMPLE
      Update-PuppetModuleFixture -PuppetModuleFolderPath ./import/powershellget
      This command will update `./import/powershellget/.fixtures.yml`, adding a
      key to the Forge Modules fixture for puppetlabs/pwshlib.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param (
    [Parameter(Mandatory = $True)]
    [string]$OutputFolderPath,
    [Parameter(Mandatory = $True)]
    [string]$PuppetModuleName,
    [Parameter(Mandatory = $False)]
    [string]$PDKTemplateRef
  )

  begin {
    $Command = "pdk new module $PuppetModuleName --skip-interview --template-url https://github.com/puppetlabs/pdk-templates --template-ref 3.0.0"
    if ($PSBoundParameters.ContainsKey('PDKTemplateRef')) {
      $Command = "$Command --template-ref 3.0.0"
    }

    $ModuleFolderPath = Join-Path -Path $OutputFolderPath -ChildPath $PuppetModuleName
    $TemplateFolder = Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Module.Path -Parent) -ChildPath 'internal/templates/static'
  }

  process {
    Try {
      $ErrorActionPreference = 'Stop'
      # Handle folder scaffolding
      If (!(Test-Path $OutputFolderPath)) {
        $null = New-Item -Path $OutputFolderPath -ItemType Directory -Force
      }
      # Clean previously scaffolded folder
      If (Test-Path $ModuleFolderPath) {
        If ($PSCmdlet.ShouldProcess($ModuleFolderPath, 'Remove existing Puppet Module Folder')) {
          Remove-Item -Path $ModuleFolderPath -Force -Recurse
        }
      }
      Write-Output "Debugging... Command: $($Command)"
      Invoke-PdkCommand -Path $OutputFolderPath -Command $Command -SuccessFilterScript {
        $_ -match "Module '$PuppetModuleName' generated at path"
      }
      # Copy static template files
      Copy-Item -Path "$TemplateFolder/*" -Destination $ModuleFolderPath -Recurse -Force
    } Catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }

  end {}
}
