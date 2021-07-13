$ProjectRoot = Split-Path -Parent $PSCommandPath |
  Split-Path -Parent |
  Resolve-Path

$ModulePath = Join-Path -Path $ProjectRoot -ChildPath 'src\puppet.dsc.psd1' | Resolve-Path
Import-Module $ModulePath -Force

$PrivateFunctionsFolder = Join-Path -Path $ProjectRoot -ChildPath 'src\internal\functions' | Resolve-Path
$PrivateFunctionsToLoad = @(
  'Invoke-PdkCommand'
  'Out-Utf8File'
  'ConvertTo-UnescapedJson'
  'ConvertTo-VersionBuild'
  'ConvertFrom-VersionBuild'
  'ConvertTo-StandardizedVersionString'
  'Get-LatestBuild'
  'Set-PuppetModuleVersion'
)
Get-ChildItem -Path $PrivateFunctionsFolder |
  Where-Object -FilterScript {
    $_.BaseName -in $PrivateFunctionsToLoad
  } |
  ForEach-Object -Process {
    . $_.FullName
  }

Function Publish-PuppetDscModule {
  [CmdletBinding()]
  Param (
    [string]$FolderToExecuteIn,
    [string]$PackagedModulePath
  )
  If ([string]::IsNullOrEmpty($PackagedModulePath)) {
    Write-Verbose "Publishing from $FolderToExecuteIn"
    $Command = "pdk release publish --forge-token $env:FORGE_TOKEN"
  } Else {
    Write-Verbose "Publishing $PackagedModulePath"
    $Command = "pdk release publish --forge-token $env:FORGE_TOKEN --file $PackagedModulePath"
  }

  Invoke-PdkCommand -Path $FolderToExecuteIn -Command $Command -SuccessFilterScript {
    $_ -match 'Publish to Forge was successful'
  }
}

Function Update-ForgeDscModule {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string[]]$Name,
    [Parameter()]
    [datetime]
    $Until,
    [Parameter()]
    [datetime]
    $Since,
    [Parameter()]
    [string[]]
    $SkipVersion,
    [string]$BuildFolderRoot,
    [string]$PackageFolder
  )

  Begin { }

  Process {
    $FilterParams = @{}
    If ($null -ne $Until) { $FilterParams.Until = $Until }
    If ($null -ne $Since) { $FilterParams.Since = $Since }
    If ($null -eq $Name) {
      Write-Host "Looking for DSC modules on the forge with the filter:`r`n$($FilterParams | Out-String)"
      $ModulesToRebuild = Get-ForgeDscModules @FilterParams
    } Else {
      Write-Host "Looking for the $Name DSC module on the forge with the filter:`r`n$($FilterParams | Out-String)"
      If ($null -ne $SkipVersion) { $FilterParams.SkipVersion = $SkipVersion }
      $ModulesToRebuild = Get-ForgeModuleInfo -Name $Name @FilterParams
    }
    foreach ($Module in $ModulesToRebuild) {
      foreach ($VersionAndBuild in (Get-LatestBuild $Module.Releases)) {
        try {
          $ErrorActionPreference = 'Stop'
          $BuildFolder = Join-Path -Path $BuildFolderRoot -ChildPath $Module.Name
          If (Test-Path $BuildFolder) {
            Remove-Item $BuildFolder -Force -Recurse
          }
          $PuppetizeParameters = @{
            PuppetModuleAuthor      = 'dsc'
            PowerShellModuleName    = [string]$Module.PowerShellModuleInfo.Name
            PowerShellModuleVersion = [string]$VersionAndBuild.Version -replace '-', '.'
          }
          If (![string]::IsNullOrEmpty($BuildFolderRoot)) { $PuppetizeParameters.OutputDirectory = $BuildFolderRoot }
          Write-Host "Puppetizing with:`r`n$($PuppetizeParameters | Out-String)"
          New-PuppetDscModule @PuppetizeParameters
          $NewVersion = $VersionAndBuild | ConvertTo-Json | ConvertFrom-Json

          $Newversion.Build += 1
          $NewVersion = $NewVersion | ConvertFrom-VersionBuild
          Write-Host "Bumping build version from $($VersionAndBuild | ConvertFrom-VersionBuild) to $NewVersion"
          Set-PuppetModuleVersion -FolderToExecuteIn $BuildFolder -Version $NewVersion
          If ([string]::IsNullOrEmpty($PackageFolder)) {
            Export-PuppetModule -FolderToExecuteIn $BuildFolder
            Write-Host "Publishing $($Module.Name) at $NewVersion"
            Publish-PuppetDscModule -FolderToExecuteIn $BuildFolder
          } Else {
            Export-PuppetModule -FolderToExecuteIn $BuildFolder -ExportFolder $PackageFolder
            $PackagedModulePath = Get-ChildItem -Path $PackageFolder | Where-Object -FilterScript {
              $_.BaseName -match [regex]::escape($Module.Name) -and $_.BaseName -match $NewVersion
            } | Select-Object -ExpandProperty FullName
            Write-Host "Publishing $($Module.Name) from $PackagedModulePath"
            Publish-PuppetDscModule -FolderToExecuteIn $BuildFolder -PackagedModulePath $PackagedModulePath
          }
        } catch {
          $ErrorActionPreference = 'Continue'
          Throw "Unable to puppetize and publish $($Module.Name) for $($VersionAndBuild.Version)"
          Start-Sleep -Seconds 15
        }
      }
    }
  }

  End { }
}

Function Get-UnreleasedDscModuleVersion {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string[]]
    $Name
  )

  Begin { }
  Process {
    $GalleryModuleInfo = Get-PowerShellDscModule -Name $Name
    ForEach ($Module in $GalleryModuleInfo) {
      $ForgeModuleInfo = Get-ForgeModuleInfo -Name (Get-PuppetizedModuleName -Name $Module.Name)
      $VersionsReleasedToForge = Get-LatestBuild $ForgeModuleInfo.Releases |
        Select-Object -ExpandProperty Version |
        ForEach-Object -Process { $_ -replace '-', '.' }
      $ModuleVersions = ConvertTo-StandardizedVersionString -Version $Module.Releases
      $VersionsToRelease = $ModuleVersions | Where-Object -FilterScript { $_ -notin $VersionsReleasedToForge }
      [PSCustomObject]@{
        Name     = $Module.Name
        Versions = $VersionsToRelease
      }
    }
  }
  End { }
}

Function Publish-NewDscModuleVersion {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string[]]
    $Name
  )
  Begin {}
  Process {
    $ModuleInformation = Get-UnreleasedDscModuleVersion -Name $Name
    ForEach ($Module in $ModuleInformation) {
      $PuppetModuleName = Get-PuppetizedModuleName $Module.Name
      $OutputFolder = "$(Get-Location)/import/$PuppetModuleName"
      ForEach ($Version in $Module.Versions) {
        If (Test-Path $OutputFolder) {
          Remove-Item $OutputFolder -Force -Recurse
        }
        $PuppetizeParameters = @{
          PuppetModuleAuthor      = 'dsc'
          PowerShellModuleName    = $Module.Name
          PowerShellModuleVersion = $Version
        }
        Write-Host "Puppetizing with: $($PuppetizeParameters | Out-String)"
        New-PuppetDscModule @PuppetizeParameters
        $PublishCommand = @(
          'pdk'
          'release'
          "--forge-token=$ENV:FORGE_TOKEN"
          '--skip-changelog'
          '--skip-validation'
          '--skip-documentation'
          '--skip-dependency'
          '--force'
        ) -Join ' '
        Write-Host "Executing: $PublishCommand"
        Invoke-PdkCommand -Path $OutputFolder -Command $PublishCommand -SuccessFilterScript { $_ -match 'Publish to Forge was successful' }
        Write-Host "Published $($Module.Name) as $PuppetModuleName at $Version"
      }
    }
  }
  End {}
}
