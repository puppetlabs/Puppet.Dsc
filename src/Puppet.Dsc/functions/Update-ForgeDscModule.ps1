Function Update-ForgeDscModule {
  <#
  .SYNOPSIS
    Rebuild and publish Puppetized DSC modules
  .DESCRIPTION
    Rebuild and publish Puppetized DSC modules, bumping their Puppet build version by one.
  .PARAMETER ForgeNameSpace
    The namespace on the Forge to search for modules
  .PARAMETER Name
    The name of one or more Puppetized DSC modules to update. If no name is
    specified, will update all Puppetized DSC modules in the specified
    Forge namespace.
  .PARAMETER Version
    The specific version to update; if specified, can only be used with a
    single Name; rebuild one version of one module and publish it.
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
  .PARAMETER LatestMajorVersionOnly
    If specified, will only rebuild releases from the latest major version
    for each module being updated.
  .PARAMETER MaximumVersionCountToRebuild
    If specified, will only rebuild and publish up to this many releases.
  .PARAMETER SleepAfterFailure
    If specified, will wait the specified number of seconds after a failure
    and before starting the next update attempt. Useful in local debugging
    and execution.
  .EXAMPLE
    Update-ForgeDscModule -ForgeNameSpace 'foo'
    This will search for every Puppetized DSC module in the 'foo' namespace
    of the public Puppet Forge and attempt to rebuild and publish (with an
    incremented Puppet build version) each release.
  .EXAMPLE
    Update-ForgeDscModule -ForgeNameSpace 'foo' -Name 'bar', 'baz'
    This will search for the 'bar' and 'baz' Puppetized DSC modules in the
    'foo' namespace of the public Puppet Forge and attempt to rebuild and
    publish (with an incremented Puppet build version) each release of those
    modules.
  .EXAMPLE
    Update-ForgeDscModule -ForgeNameSpace 'foo' LatestMajorVersionOnly
    This will search for every Puppetized DSC module in the 'foo' namespace
    of the public Puppet Forge and attempt to rebuild and publish (with an
    incremented Puppet build version) only releases from the latest major
    version of each module; so if a module was released at 2.1.0.0, 2.0.0.0,
    1.2.0.0, 1.1.0.0, and 1.0.0.0, only 2.1.0.0 and 2.0.0.0 would be rebuilt
    and published.
  .EXAMPLE
    Update-ForgeDscModule -ForgeNameSpace 'foo' MaximumVersionCountToRebuild 3
    This will search for every Puppetized DSC module in the 'foo' namespace
    of the public Puppet Forge and attempt to rebuild and publish (with an
    incremented Puppet build version) only releases from the latest major
    version of each module; so if a module was released at 2.1.0.0, 2.0.0.0,
    1.2.0.0, 1.1.0.0, and 1.0.0.0, only 2.1.0.0, 2.0.0.0, and 1.2.0.0 would be
    rebuilt and published.
  .INPUTS
    None.
  .OUTPUTS
    None.
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByNameSpace')]
  param (
    [Parameter(Mandatory, ParameterSetName = 'ByNameSpace')]
    [Parameter(Mandatory, ParameterSetName = 'ByName')]
    [Parameter(Mandatory, ParameterSetName = 'ByNameAndVersion')]
    [string]$ForgeNameSpace,
    [Parameter(Mandatory, ParameterSetName = 'ByName')]
    [Parameter(Mandatory, ParameterSetName = 'ByNameAndVersion')]
    [string[]]$Name,
    [Parameter(Mandatory, ParameterSetName = 'ByNameAndVersion')]
    [version]$Version,
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [Parameter(ParameterSetName = 'ByName')]
    [Parameter(ParameterSetName = 'ByNameAndVersion')]
    [string]$ForgeApiUri,
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [Parameter(ParameterSetName = 'ByName')]
    [Parameter(ParameterSetName = 'ByNameAndVersion')]
    [string]$ForgeToken,
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [Parameter(ParameterSetName = 'ByName')]
    [Parameter(ParameterSetName = 'ByNameAndVersion')]
    [string]$BuildFolderPath,
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [Parameter(ParameterSetName = 'ByName')]
    [Parameter(ParameterSetName = 'ByNameAndVersion')]
    [string]$PackageFolderPath,
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [Parameter(ParameterSetName = 'ByName')]
    [switch]$LatestMajorVersionOnly,
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [Parameter(ParameterSetName = 'ByName')]
    [int]$MaximumVersionCountToRebuild,
    [Parameter(ParameterSetName = 'ByNameSpace')]
    [Parameter(ParameterSetName = 'ByName')]
    [int]$SleepAfterFailure = 0
  )

  Begin {
    $DefaultErrorActionPreference = $ErrorActionPreference
    If (![string]::IsNullOrEmpty($Version)) {
      If ($Name.Count -ne 1) {
        If ($Name.Count -eq 0) { $Message = 'Specified a Version without a Name; must specify a single Name if specifying Version' }
        If ($Name.Count -gt 1) { $Message = 'Specified a Version with multiple Names; must specify a single Name if specifying Version' }
        Throw $Message
      }
      # Standardize on a puppetized four-digit version string
      $PuppetizedVersion = ConvertTo-StandardizedVersionString -Version $Version
      $PuppetizedVersion = $PuppetizedVersion -replace '\.(\d+)$', '-$1'
      Write-PSFMessage -Level Verbose -Message "Puppetized Version: $PuppetizedVersion"
    }
  }

  Process {
    $FilterParams = @{}
    If (![string]::IsNullOrEmpty($ForgeApiUri)) { $FilterParams.ForgeSearchUri = "$ForgeApiUri/modules" }
    If (![string]::IsNullOrEmpty($ForgeNameSpace)) { $FilterParams.ForgeNameSpace = $ForgeNameSpace }
    If (![string]::IsNullOrEmpty($Name)) { $FilterParams.Name = $Name }

    Write-PSFMessage -Level Verbose -Message "Looking for DSC modules on the Forge with the filter:`r`n$($FilterParams | ConvertTo-Json)"
    $ModulesToRebuild = Get-ForgeModuleInfo @FilterParams

    foreach ($Module in $ModulesToRebuild) {
      $ReleasesToRebuild = Get-LatestBuild -Version $Module.Releases
      #region Filter Releases to Rebuild
      If ($LatestMajorVersionOnly) {
        $LatestMajorVersion = $ReleasesToRebuild[0].Version -split '\.' | Select-Object -First 1
        $ReleasesToRebuild = $ReleasesToRebuild | Where-Object -FilterScript { $_.Version -match "^$LatestMajorVersion\." }
      }
      If ($MaximumVersionCountToRebuild -gt 0) {
        $ReleasesToRebuild = $ReleasesToRebuild | Select-Object -First $MaximumVersionCountToRebuild
      }
      If (![string]::IsNullOrEmpty($PuppetizedVersion)) {
        $ReleasesToRebuild = $ReleasesToRebuild | Where-Object -FilterScript { $_.Version -eq $PuppetizedVersion }
        If ($null -eq $ReleasesToRebuild) {
          Write-PSFMessage -Level Warning "Unable to find any releases at version '$PuppetizedVersion' for the '$($Module.Name)' module in the '$ForgeNameSpace' namespace"
        }
      }
      #endregion
      foreach ($VersionAndBuild in $ReleasesToRebuild) {
        try {
          $ErrorActionPreference = 'Stop'
          #region Build from Gallery
          $PuppetizeParameters = @{
            PuppetModuleAuthor      = $ForgeNameSpace
            PowerShellModuleName    = [string]$Module.PowerShellModuleInfo.Name
            PowerShellModuleVersion = [string]$VersionAndBuild.Version -replace '-', '.'
            PassThru                = $true
          }
          If (![string]::IsNullOrEmpty($BuildFolderPath)) { $PuppetizeParameters.OutputDirectory = $BuildFolderPath }
          Write-PSFMessage -Level Verbose -Message "Puppetizing with:`r`n$($PuppetizeParameters | ConvertTo-Json)"
          $ModuleFolderPath = New-PuppetDscModule @PuppetizeParameters |
            Select-Object -ExpandProperty FullName
          #endregion
          #region Update Build Version
          # Copy the VersionAndBuild object so as to be able to keep the comparison info
          $NewVersion = $VersionAndBuild | ConvertTo-Json | ConvertFrom-Json
          $Newversion.Build += 1
          $NewVersion = $NewVersion | ConvertFrom-VersionBuild
          Write-PSFMessage -Level Verbose -Message "Bumping build version from $($VersionAndBuild | ConvertFrom-VersionBuild) to $NewVersion"
          Set-PuppetModuleVersion -PuppetModuleFolderPath $ModuleFolderPath -Version $NewVersion
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

          Write-PSFMessage -Level Verbose -Message "Publishing $($Module.Name) at $($NewVersion) with`r`n$(($PublishParameters | ConvertTo-Json) -replace $ForgeToken, '<FORGE_TOKEN>')"
          Publish-PuppetModule @PublishParameters
          #endregion
        } catch {
          $ErrorActionPreference = $DefaultErrorActionPreference

          $ErrorParameters = @{
            Message     = "Unable to puppetize and publish $($Module.Name) for $($VersionAndBuild.Version)"
            ErrorRecord = $PSItem
          }
          If ($ErrorActionPreference -eq 'Stop') { $ErrorParameters.EnableException = $true }

          Stop-PSFFunction @ErrorParameters

          If ($SleepAfterFailure -gt 0) {
            Start-Sleep -Seconds $SleepAfterFailure
          }
        }
      }
    }
  }

  End { }
}