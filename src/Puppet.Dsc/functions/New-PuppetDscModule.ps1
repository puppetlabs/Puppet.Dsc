Function New-PuppetDscModule {
  <#
    .SYNOPSIS
      Puppetize a PowerShell module with DSC resources
    .DESCRIPTION
      This function builds a Puppet Module which wraps and calls PowerShell DSC resources
      via the Puppet resource_api. This module:

      - Includes a base resource_api provider which relies on ruby-pwsh and knows how to invoke DSC resources
      - Includes a type for each DSC resource, pulling in the appropriate metadata including help, default value
        and mandatory status, as well as whether or not it includes an embedded mof.
      - Allows for the tracking of changes on a property-by-property basis while using DSC and Puppet together
    .PARAMETER PowerShellModuleName
      The name of the PowerShell module on the gallery which has DSC resources you want to Puppetize
    .PARAMETER PowerShellModuleVersion
      The version of the PowerShell module on the gallery which has DSC resources you want to Puppetize.
      If left blank, will default to latest available.
    .PARAMETER PuppetModuleName
      The name of the Puppet module for the wrapper; if not specified, will default to the downcased name of
      the module to adhere to Puppet naming conventions.
    .PARAMETER PuppetModuleAuthor
      The name of the Puppet module author; if not specified, will default to your PDK configuration's author.
    .PARAMETER PuppetModuleFixture
      The fixture reference for the puppetlabs-pwshlib dependency, defined as a hash with the mandatory keys
      `Section` ('forge_modules' or 'repositories') and `Repo` (the name of the module on the forge, like
      'puppetlabs/pwshlib', or the git repo url) and the optional keys `Ref` (the version on the forge or the
      git ref - tag or commit sha) and `Branch` (source code repository only, identifying the branch to be
      pulled from).

      Defaults to retrieving the latest released version of pwshlib from the forge.
    .PARAMETER OutputDirectory
      The folder in which to build the Puppet module. Defaults to a folder called import in the current location.
    .PARAMETER AllowPrerelease
      Allows you to Puppetize a module marked as a prerelease.
    .PARAMETER PassThru
      If specified, the function returns the path to the root folder of the Puppetized module on the filesystem.
    .PARAMETER Confirm
      Prompts for confirmation before creating the Puppet module
    .PARAMETER WhatIf
      Shows what would happen if the function runs.
    .PARAMETER Repository
      Specifies a non-default PSRepository.
      If left blank, will default to PSGallery.
    .PARAMETER PDKTemplateRef
      Specifies the template git branch or tag to use when creating new moudles or classes.
    .EXAMPLE
      New-PuppetDscModule -PowerShellModuleName PowerShellGet -PowerShellModuleVersion 2.2.3 -Repository PSGallery

      This function will create a new Puppet module, powershellget, which vendors and puppetizes the PowerShellGet
      PowerShell module at version 2.2.3 and its dependencies, exposing the DSC resources as Puppet resources.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param(
    [Parameter(Mandatory = $True)]
    [string]$PowerShellModuleName,
    [string]$PowerShellModuleVersion,
    [string]$PuppetModuleName,
    [string]$PuppetModuleAuthor,
    [hashtable]$PuppetModuleFixture,
    [string]$OutputDirectory,
    [switch]$AllowPrerelease,
    [switch]$PassThru,
    [string]$Repository,
    [string]$PDKTemplateRef = '3.0.0'
  )

  Begin {
    # Unless specified, use a valid Puppet module name
    If ([string]::IsNullOrEmpty($PuppetModuleName)) {
      $PuppetModuleName = Get-PuppetizedModuleName -Name $PowerShellModuleName
    } Else {
      $PuppetizedName = Get-PuppetizedModuleName -Name $PuppetModuleName
      if ($PuppetizedName -ne $PuppetModuleName) {
        Throw "Invalid puppet module name '$PuppetModuleName' specified; must include only lowercase letters, digits, and underscores and not start with a digit"
      }
    }
    # If specified, canonicalize the Puppet module author name
    If (![string]::IsNullOrEmpty($PuppetModuleAuthor)) { $PuppetModuleAuthor = ConvertTo-CanonicalPuppetAuthorName -AuthorName $PuppetModuleAuthor }
    # Default to the `import` folder in the current path
    If ([string]::IsNullOrEmpty($OutputDirectory)) {
      $OutputDirectory = Join-Path -Path (Get-Location) -ChildPath 'import'
    } Else {}

    # make sure that we're operating on a absolute path to avoid confusion from symlinks and relative paths
    $OutputDirectory = New-Item -Path $OutputDirectory -ItemType 'directory' -Force

    $PuppetModuleRootFolderDirectory = Join-Path -Path $OutputDirectory -ChildPath $PuppetModuleName
    $VendoredDscResourcesDirectory = Join-Path -Path $OutputDirectory -ChildPath "$PuppetModuleName/lib/puppet_x/$PuppetModuleName/dsc_resources"
    $PuppetModuleTypeDirectory = Join-Path -Path $PuppetModuleRootFolderDirectory -ChildPath 'lib/puppet/type'
    $PuppetModuleProviderDirectory = Join-Path -Path $PuppetModuleRootFolderDirectory -ChildPath 'lib/puppet/provider'
    $InitialPSModulePath = $Env:PSModulePath
    $InitialErrorActionPreference = $ErrorActionPreference
    If (!(Test-RunningElevated)) {
      Write-PSFMessage -Message 'Running un-elevated: will not be able to parse embedded CIM instances; run again with Administrator permissions to map embedded CIM instances' -Level Warning
    } Else {
      If (Test-SymLinkedItem -Path $OutputDirectory -Recurse) {
        Stop-PSFFunction -EnableException $true -Message "The specified output folder '$OutputDirectory' has a symlink in the path; CIM class parsing will not work in a symlinked folder, specify another path"
      }
      Try {
        $null = Test-WSMan -ErrorAction Stop
      } Catch {
        Stop-PSFFunction -EnableException $true -Message "PSRemoting does not appear to be enabled; in order to parse CIM instances, the function needs to do a stubbed DSC invocation; this will fail without PSRemoting enabled. Enable PSRemoting (possibly via the Enable-PSRemoting command) before retrying. Exception:`r`n$($_.Exception | Format-List -Force * | Out-String )"
      }
    }
  }

  Process {
    $ShouldProcessMessage = "Puppetize the '$PowerShellModuleName' module"
    If (![string]::IsNullOrEmpty($PowerShellModuleVersion)) { $ShouldProcessMessage += " at version '$PowerShellModuleVersion'" }
    If ([string]::IsNullOrEmpty($Repository)) { $Repository = 'PSGallery' }
    If ($PSCmdlet.ShouldProcess($OutputDirectory, $ShouldProcessMessage)) {
      Try {
        $ErrorActionPreference = 'Stop'
        # Scaffold the module via the PDK
        Write-PSFMessage -Message 'Initializing the Puppet Module'
        Initialize-PuppetModule -OutputFolderPath $OutputDirectory -PuppetModuleName $PuppetModuleName -PDKTemplateRef $PDKTemplateRef -verbose

        # Vendor the PowerShell module and all of its dependencies
        Write-PSFMessage -Message 'Vendoring the DSC Resources'
        Add-DscResourceModule -Name $PowerShellModuleName -Path $VendoredDscResourcesDirectory -RequiredVersion $PowerShellModuleVersion -Repository $Repository -AllowPrerelease:$AllowPrerelease

        # Update the Puppet module metadata
        Write-PSFMessage -Message 'Updating the Puppet Module metadata'
        $PowerShellModuleManifestPath = (Resolve-Path -Path "$VendoredDscResourcesDirectory/$PowerShellModuleName/$PowerShellModuleName.psd1")
        $MetadataParameters = @{
          PuppetModuleFolderPath       = $PuppetModuleRootFolderDirectory
          PowerShellModuleManifestPath = $PowerShellModuleManifestPath
          PuppetModuleAuthor           = $PuppetModuleAuthor
        }
        Update-PuppetModuleMetadata @MetadataParameters

        # Update the Puppet module test fixtures
        Write-PSFMessage -Message 'Updating the Puppet Module test fixtures'
        If ($null -eq $PuppetModuleFixture) {
          Update-PuppetModuleFixture -PuppetModuleFolderPath $PuppetModuleRootFolderDirectory
        } Else {
          Update-PuppetModuleFixture -PuppetModuleFolderPath $PuppetModuleRootFolderDirectory -Fixture $PuppetModuleFixture
        }

        # Write the Puppet module README
        Write-PSFMessage -Message 'Writing the Puppet Module readme'
        Update-PuppetModuleReadme -PuppetModuleName $PuppetModuleName -PowerShellModuleName $PowerShellModuleName -PuppetModuleFolderPath $PuppetModuleRootFolderDirectory -PowerShellModuleManifestPath $PowerShellModuleManifestPath

        # Write the Puppet module changelog based on PowerShell module
        Write-PSFMessage -Message 'Writing the Puppet Module changelog'
        Update-PuppetModulechangelog -PuppetModuleFolderPath $PuppetModuleRootFolderDirectory -PowerShellModuleManifestPath $PowerShellModuleManifestPath

        # The PowerShell Module path needs to be munged because the Get-DscResource function always and only
        # checks the PSModulePath for DSC modules; you CANNOT point to a module by path.
        Write-PSFMessage -Message 'Converting the DSC resources to Puppet types and providers'
        Set-PSModulePath -Path $VendoredDscResourcesDirectory
        $Resources = Get-DscResource -Module $PowerShellModuleName | ConvertTo-PuppetResourceApi

        # Write the type and provider files for each DSC Resource
        foreach ($Resource in $Resources) {
          $PuppetTypeFilePath = Join-Path -Path $PuppetModuleTypeDirectory -ChildPath $Resource.RubyFileName
          $PuppetProviderDirectoryPath = Join-Path -Path $PuppetModuleProviderDirectory -ChildPath $Resource.Name
          $PuppetProviderFilePath = Join-Path -Path $PuppetProviderDirectoryPath -ChildPath $Resource.RubyFileName
          if (-not(Test-Path $PuppetModuleTypeDirectory)) {
            New-Item -Path $PuppetModuleTypeDirectory -ItemType Directory -Force | Out-Null
          }
          Out-Utf8File -Path $PuppetTypeFilePath -InputObject $Resource.Type
          if (-not(Test-Path $PuppetProviderDirectoryPath)) {
            New-Item -Path $PuppetProviderDirectoryPath -ItemType Directory -Force | Out-Null
          }
          Out-Utf8File -Path $PuppetProviderFilePath -InputObject $Resource.Provider
        }

        # Generate REFERENCE.md file for the Puppet module from the auto-generated types for each DSC resource
        Write-PSFMessage -Message 'Writing the reference documentation for the Puppet module'
        Set-PSModulePath -Path $InitialPsModulePath
        Add-PuppetReferenceDocumentation -PuppetModuleFolderPath $PuppetModuleRootFolderDirectory -verbose

        If ($PassThru) {
          # Return the folder containing the puppetized module
          Get-Item $PuppetModuleRootFolderDirectory
        }
      } Catch {
        $PSCmdlet.ThrowTerminatingError($PSitem)
      } Finally {
        # Reset the working envrionment
        Set-PSModulePath -Path $InitialPsModulePath
        $ErrorActionPreference = $InitialErrorActionPreference
      }
    }
  }

  End {}
}
