function Update-PuppetModuleMetadata {
  <#
    .SYNOPSIS
      Update Puppet module metadata with PowerShell Module Manifest metadata.
    .DESCRIPTION
      Update Puppet module metadata with PowerShell Module Manifest metadata.
    .PARAMETER PuppetModuleFolderPath
      The path to the root folder of the Puppet module.
    .PARAMETER PowerShellModuleManifestPath
      The full path to the PowerShell module's manifest file.
    .PARAMETER PuppetModuleAuthor
      The name of the author for the Puppet module.
    .PARAMETER Confirm
      Prompts for confirmation before overwriting the file
    .PARAMETER WhatIf
      Shows what would happen if the function runs.
    .EXAMPLE
      Update-PuppetModuleMetadata -PuppetModuleFolderPath ./import/powershellget -PowerShellModuleManifestPath ./mymodule.psd1
      This command will update `./import/powershellget/metadata.json` based on the metadata from `./mymodule.psd1`.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param (
    [string]$PuppetModuleFolderPath,
    [string]$PowerShellModuleManifestPath,
    [string]$PuppetModuleAuthor
  )

  begin {
    Try {
      $PuppetModuleMetadataFilePath = Resolve-Path (Join-Path $PuppetModuleFolderPath 'metadata.json') -ErrorAction Stop
      $PowerShellModuleManifestPath = Resolve-Path -Path $PowerShellModuleManifestPath -ErrorAction Stop
      $PuppetMetadata = Get-Content -Path $PuppetModuleMetadataFilePath | ConvertFrom-Json -ErrorAction Stop
      $PowerShellMetadata = Import-PSFPowerShellDataFile -Path $PowerShellModuleManifestPath -ErrorAction Stop
    } Catch {
      # Rethrow any exceptions from the above commands
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }

  process {
    If (![string]::IsNullOrEmpty($PuppetModuleAuthor)) {
      $PuppetMetadata.name = $PuppetMetadata.name -replace '(^\S+)-(\S+)', "$PuppetModuleAuthor-`$2"
      $PuppetMetadata.author = $PuppetModuleAuthor
    }
    $PuppetMetadata.version = Get-PuppetModuleVersion -Version $PowerShellMetadata.ModuleVersion
    $summary = ($PowerShellMetadata.Description -split "(`r`n|`n)")[0]
    $summary = $summary -Replace '"', '\"'
    # summary needs to be 144 chars or less (see https://github.com/voxpupuli/metadata-json-lint/blob/5ab67f9404ee65da0efd84a597b2ee86152d2659/lib/metadata-json-lint/schema.rb#L99 )
    if ($summary.length -gt 144) {
      $summary = $summary.substring(0, 144 - 3) + '...'
    }
    $PuppetMetadata.summary = $summary
    $PuppetMetadata.source = $PowerShellMetadata.PrivateData.PSData.ProjectUri
    if ([string]::IsNullOrEmpty($PuppetMetadata.source)) {
      $PowerShellModuleName = Get-Item $PowerShellModuleManifestPath | Select-Object -ExpandProperty BaseName
      $PuppetMetadata.source = "https://www.powershellgallery.com/packages/$PowerShellModuleName/$($PowerShellMetadata.ModuleVersion)/Content/$PowerShellModuleName.psd1"
    }
    # If we can find the issues page, link to it, otherwise default to project page.
    Switch -Regex ($PowerShellMetadata.PrivateData.PSData.ProjectUri) {
      '(github\.com|gitlab\.com|bitbucket\.com)' {
        $IssueUri = $PowerShellMetadata.PrivateData.PSData.ProjectUri + '/issues'
        Try {
          $null = Invoke-WebRequest -Uri $IssueUri -UseBasicParsing -ErrorAction Stop
          $PuppetMetadata | Add-Member -MemberType NoteProperty -Name issues_url -Value $IssueUri
        } Catch {
          $PuppetMetadata | Add-Member -MemberType NoteProperty -Name issues_url -Value $PowerShellMetadata.PrivateData.PSData.ProjectUri
        }
      }
      Default { $PuppetMetadata | Add-Member -MemberType NoteProperty -Name issues_url -Value $PowerShellMetadata.PrivateData.PSData.ProjectUri }
    }
    # If the HelpInfoURI is specified, use it, otherwise default to project page
    If ($null -ne $PowerShellMetadata.HelpInfoURI) {
      $PuppetMetadata | Add-Member -MemberType NoteProperty -Name project_page -Value $PowerShellMetadata.HelpInfoURI
    } Else {
      $PuppetMetadata | Add-Member -MemberType NoteProperty -Name project_page -Value $PowerShellMetadata.PrivateData.PSData.ProjectUri
    }
    # Update the dependencies to include the base DSC provider and PowerShell code manager
    $PuppetMetadata.dependencies = @(
      @{
        name                = 'puppetlabs/pwshlib'
        version_requirement = '>= 0.9.0 < 2.0.0'
      }
    )
    # Update the operating sytem to only support windows *for now*.
    $PuppetMetadata.operatingsystem_support = @(
      @{
        operatingsystem        = 'windows'
        operatingsystemrelease = @(
          '2012',
          '2012R2',
          '2016',
          '2019'
        )
      }
    )
    # Clarify Puppet lower bound
    $PuppetMetadata.requirements[0].version_requirement = '>= 7.0.0 < 9.0.0'
    # Tag the module as coming from the builder so that it becomes searchable on the Forge.
    $PuppetMetadata | Add-Member -MemberType NoteProperty -Name tags -Value @(
      'windows',
      'puppetdsc',
      'dsc'
    )
    # Add new metadata sections
    $PuppetMetadata | Add-Member -MemberType NoteProperty -Name dsc_module_metadata -Value @{
      name    = Get-Module -ListAvailable -Name $PowerShellModuleManifestPath | Select-Object -ExpandProperty Name
      version = $PowerShellMetadata.ModuleVersion
      author  = $PowerShellMetadata.Author
      guid    = $PowerShellMetadata.Guid
    }
    $PuppetMetadataJson = ConvertTo-UnescapedJson -InputObject $PuppetMetadata -Depth 10
    If ($PSCmdlet.ShouldProcess($PuppetModuleMetadataFilePath, "Overwrite Puppet Module metadata with:`n`n$PuppetMetadataJson")) {
      Out-Utf8File -Path $PuppetModuleMetadataFilePath -InputObject $PuppetMetadataJson
    }
  }

  end {}
}
