Function Publish-NewDscModuleVersion {
  <#
    .SYNOPSIS
      Build and publish Puppetized DSC module versions not yet on the Forge
    .DESCRIPTION
      Build and publish Puppetized DSC module versions not yet on the Forge by
      searching for Puppetizable PowerShell modules with DSC Resources in a
      repository and then building and published each desired version.
    .PARAMETER ForgeNameSpace
      The namespace on the Forge to search for modules in and publish to.
    .PARAMETER Name
      The name of one or more PowerShell modules to search for new versions to
      puppetize. If no name is specified, will compare all PowerShell modules
      with DSC Resources in the specified Repository to the Forge to find
      unpuppetized module versions.
    .PARAMETER MinimumVersion
      The minimum version to puppetize; any released versions equal to or newer
      than this which have been published to the PowerShell repository but not
      the Puppet Forge will be puppetized and published.
    .PARAMETER OnlyNewer
      Only puppetize versions of the PowerShell module on the PowerShell repository
      which are newer than the highest version release of the module in the
      Puppet Forge. Use to prevent building legacy versions if not needed.
    .PARAMETER MaxBuildCount
      Only puppetize up to this many releases *total* across modules and versions.
    .PARAMETER Repository
      The PowerShell repository to search; defaults to the PowerShell Gallery
    .PARAMETER ForgeApiUri
      The Puppet Forge API URI to search and publish to; defaults to the public Puppet Forge
    .PARAMETER ForgeToken
      The Forge API Token for the target account. If not specified, will use
      the FORGE_TOKEN environment variable. Must pass a token either directly
      or via the environment variable to successfully publish to the Forge.
    .PARAMETER BuildFolderPath
      The path, relative or absolute, to the folder in which to Puppetize the
      module. If not specified, will do so in a folder called import in the
      current location.
    .PARAMETER PackageFolderPath
      The path, relative or absolute, to the folder in which to build the
      module. If not specified, will build in the pkg folder inside the
      BuildFolderPath.
    .EXAMPLE
      Publish-NewDscModuleVersion -ForgeNameSpace foo
      This will search the PowerShell Gallery for any and all modules with DSC
      Resources and their releases, comparing this information to the Puppet
      Forge; any version of any discovered module *not* published to the 'foo'
      namespace on the Forge will be puppetized and published; for any module
      which is not already on the Forge in this namespace, all discovered
      versions will be Puppetized and published.
    .EXAMPLE
      Publish-NewDscModuleVersion -ForgeNameSpace foo -Name 'bar', 'baz'
      This will search the PowerShell Gallery for the bar and baz modules; any
      version of these modules *not* published to the 'foo' namespace on the
      Forge will be puppetized and published; if either module is not already
      on the Forge in this namespace, all discovered versions for that module
      will be Puppetized and published.
    .EXAMPLE
      Publish-NewDscModuleVersion -ForgeNameSpace foo -OnlyNewer
      This will search the PowerShell Gallery for any and all modules with DSC
      Resources and their releases, comparing this information to the Puppet
      Forge; any version of any discovered module *not* published to the 'foo'
      namespace on the Forge *and* whose version is higher than the highest
      version published to the Forge will be puppetized and published; for
      any module which is not already on the Forge in this namespace, all
      discovered versions will be Puppetized and published.
    .EXAMPLE
      Publish-NewDscModuleVersion -ForgeNameSpace foo -MaxBuildCount 10
      This will search the PowerShell Gallery for any and all modules with DSC
      Resources and their releases, comparing this information to the Puppet
      Forge; any version of any discovered module *not* published to the 'foo'
      namespace on the Forge will be puppetized and published, up to 10 total
      releases; if there are more unreleased versions than the MaxBuildCount
      specification of 10, they will not be built in this call.
    .INPUTS
      None.
    .OUTPUTS
      None.
  #>

  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$ForgeNameSpace,
    [string[]]$Name,
    [string]$MinimumVersion,
    [switch]$OnlyNewer,
    [int]$MaxBuildCount,
    [string]$Repository,
    [string]$ForgeApiUri,
    [string]$ForgeToken,
    [string]$BuildFolderPath,
    [string]$PackageFolderPath
  )

  Begin {
    $DefaultErrorActionPreference = $ErrorActionPreference
    $SearchParameters = @{
      ForgeNameSpace = $ForgeNameSpace
    }
    If ($MinimumVersion) { $SearchParameters.MinimumVersion = $MinimumVersion }
    If ($OnlyNewer) { $SearchParameters.OnlyNewer = $true }
    If ($Name.Count -gt 0) { $SearchParameters.Name = $Name }
    If (![string]::IsNullOrEmpty($Repository)) { $SearchParameters.Repository = $Repository }
    If (![string]::IsNullOrEmpty($ForgeApiUri)) { $SearchParameters.ForgeSearchUri = "$ForgeApiUri/modules" }

    If ($MaxBuildCount -gt 0) {
      $CurrentBuildCount = 0
    }
  }

  Process {
    $ModuleInformation = Get-UnpuppetizedDscModuleVersion @SearchParameters
    ForEach ($Module in $ModuleInformation) {
      If ($CurrentBuildCount -eq $MaxBuildCount) { return }
      ForEach ($Version in $Module.Versions) {
        If ($MaxBuildCount -gt 0) {
          If ($CurrentBuildCount -eq $MaxBuildCount) { return }
          $CurrentBuildCount++
        }
        try {
          $ErrorActionPreference = 'Stop'
          #region Build from Gallery
          $PuppetizeParameters = @{
            PuppetModuleAuthor      = $ForgeNameSpace
            PowerShellModuleName    = [string]$Module.Name
            PowerShellModuleVersion = $Version
            PassThru                = $true
          }
          If (![string]::IsNullOrEmpty($BuildFolderPath)) { $PuppetizeParameters.OutputDirectory = $BuildFolderPath }
          Write-PSFMessage -Level Verbose -Message "Puppetizing with:`r`n$($PuppetizeParameters | ConvertTo-Json)"
          $ModuleFolderPath = New-PuppetDscModule @PuppetizeParameters |
            Select-Object -Property Name
          $PuppetizedVersion = Get-Content -Path "$ModuleFolderPath/metadata.json" -Raw |
            ConvertFrom-Json |
            Select-Object -ExpandProperty 'version'
          #endregion
          #region Export & Publish
          $PublishParameters = @{
            PuppetModuleFolderPath = $ModuleFolderPath
            Build                  = $true
            Publish                = $true
            Force                  = $true
          }
          If (![string]::IsNullOrEmpty($ForgeToken)) { $PublishParameters.ForgeToken = $ForgeToken }
          If (![string]::IsNullOrEmpty($ForgeApiUri)) { $PublishParameters.ForgeUploadUrl = "$ForgeApiUri/releases" }
          If (![string]::IsNullOrEmpty($PackageFolderPath)) { $PublishParameters.ExportFolderPath = $PackageFolderPath }

          Write-PSFMessage -Level Verbose -Message "Publishing $($Module.Name) at $($PuppetizedVersion) with`r`n$(($PublishParameters | ConvertTo-Json) -replace $ForgeToken, '<FORGE_TOKEN>')"
          Publish-PuppetModule @PublishParameters
          #endregion
        } catch {
          $ErrorActionPreference = $DefaultErrorActionPreference

          $ErrorParameters = @{
            Message     = "Unable to puppetize and publish $($Module.Name) for $Version"
            ErrorRecord = $PSItem
          }
          If ($ErrorActionPreference -eq 'Stop') { $ErrorParameters.EnableException = $true }

          Stop-PSFFunction @ErrorParameters
        }
      }
    }
  }

  End {}
}