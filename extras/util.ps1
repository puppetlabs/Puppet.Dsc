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
)
Get-ChildItem -Path $PrivateFunctionsFolder |
  Where-Object -FilterScript {
    $_.BaseName -in $PrivateFunctionsToLoad
  } |
  ForEach-Object -Process {
    . $_.FullName
  }

Function ConvertTo-VersionBuild {
  [CmdletBinding()]
  param (
    [Parameter()]
    [String[]]
    $Version
  )

  Begin { }
  Process {
    $Version | Sort-Object -Descending | ForEach-Object -Process {
      [pscustomobject]@{
        Version = $_.substring(0, ($_.length - 2))
        Build   = [int]([string]$_[-1])
      }
    }
  }
  End { }
}

Function Get-LatestBuild {
  [CmdletBinding()]
  param (
    [Parameter()]
    [String[]]
    $Version
  )
  Begin { }
  Process {
    $VersionAndBuild = ConvertTo-VersionBuild -Version $Version
    $VersionAndBuild.version |
      Select-Object -Unique |
      ForEach-Object -Process {
        $VersionAndBuild |
          Where-Object -Property Version -EQ $_ |
          Sort-Object -Property Build -Descending |
          Select-Object -First 1
        }
  }
  End { }
}

Function ConvertFrom-VersionBuild {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [object[]]
    $VersionBuild
  )

  Begin { }
  Process {
    $VersionBuild | ForEach-Object -Process {
      "$($_.Version)-$($_.Build)"
    }
  }
  End { }
}

Function Get-ForgeModuleInfo {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string[]]
    $Name,
    [Parameter()]
    [datetime]
    $Until,
    [Parameter()]
    [datetime]
    $Since,
    [Parameter()]
    [string[]]
    $SkipVersion
  )

  Begin {
    $UriBase = 'https://forgeapi.puppet.com/v3/modules/dsc-'
    $ModuleSearchParameters = @{
      Method          = 'Get'
      UseBasicParsing = $True
      Headers         = @{
        Authotization = "Bearer $ENV:FORGE_TOKEN"
      }
    }
  }
  Process {
    foreach ($Module in $Name) {
      $ModuleSearchParameters.Uri = $UriBase + (Get-PuppetizedModuleName $Module)
      $Result = Invoke-RestMethod @ModuleSearchParameters
      # Filter Releases:
      if ($null -ne $Until) {
        $Result.releases = $Result.releases | Where-Object -FilterScript {
          [datetime]$_.created_at -lt $Until
        }
      }
      if ($null -ne $Since) {
        $Result.releases = $Result.releases | Where-Object -FilterScript {
          [datetime]$_.created_at -gt $Since
        }
      }
      If ($null -ne $SkipVersion) {
        $Result.releases = $Result.releases | Where-Object -FilterScript {
          $null = $_.version -match '(?<Version>\d+\.\d+\.\d+-\d+)-(?<Build>\d+$)'
          $ReleaseVersion = $Matches.Version
          $ReleaseVersion -notin $SkipVersion
        }
      }

      [PSCustomObject]@{
        Name                 = $Result.name
        Releases             = $Result.releases.version
        PowerShellModuleInfo = $Result.current_release.metadata.dsc_module_metadata
      }
    }
  }
  End { }
}

Function Get-ForgeDscModules {
  [CmdletBinding()]
  param (
    [Parameter()]
    [datetime]
    $Until,
    [Parameter()]
    [datetime]
    $Since
  )

  Begin {
    $PaginationBump = 5
    $ForgeSearchParameters = @{
      Method          = 'Get'
      UseBasicParsing = $True
      Uri             = 'https://forgeapi.puppet.com/v3/modules'
      Headers         = @{
        Authotization = "Bearer $ENV:FORGE_TOKEN"
      }
      Body            = @{
        owner  = 'dsc'
        limit  = $PaginationBump
        offset = 0
      }
    }
    $Results = [System.Collections.ArrayList]::new()
  }

  Process {
    do {
      $Response = Invoke-RestMethod @ForgeSearchParameters
      ForEach ($Result in $Response.results) {
        # Filter Releases:
        if ($null -ne $Until) {
          $Result.releases = $Result.releases | Where-Object -FilterScript {
            [datetime]$_.created_at -lt $Until
          }
        }
        if ($null -ne $Since) {
          $Result.releases = $Result.releases | Where-Object -FilterScript {
            [datetime]$_.created_at -gt $Since
          }
        }
        $null = $Results.Add([PSCustomObject]@{
            Name                 = $Result.name
            Releases             = $Result.releases.version
            PowerShellModuleInfo = $Result.current_release.metadata.dsc_module_metadata
          })
      }
      $ForgeSearchParameters.body.offset += $PaginationBump
    } until ($null -eq $Response.Pagination.Next)
    $Results
  }
  End { }
}

Function Export-PuppetModule {
  [CmdletBinding()]
  Param (
    [string]$FolderToExecuteIn,
    [string]$ExportFolder
  )

  If ([string]::IsNullOrEmpty($ExportFolder)) {
    $Command = 'pdk build'
  } Else {
    $Command = "pdk build --target-dir $ExportFolder"
  }
  Invoke-PdkCommand -Path $FolderToExecuteIn -Command $Command -SuccessFilterScript {
    $_ -match 'has completed successfully. Built package can be found here'
  }
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

Function Set-PuppetModuleVersion {
  [CmdletBinding()]
  Param (
    [string]$FolderToExecuteIn,
    [string]$Version
  )

  Begin { }

  Process {
    $PuppetMetadataJsonPath = Join-Path -Path $FolderToExecuteIn -ChildPath 'metadata.json' | Resolve-Path
    $PuppetMetadata = Get-Content -Path $PuppetMetadataJsonPath -Raw | ConvertFrom-Json
    $PuppetMetadata.version = $Version
    $PuppetMetadataJson = ConvertTo-UnescapedJson -InputObject $PuppetMetadata -Depth 10
    Out-Utf8File -Path $PuppetMetadataJsonPath -InputObject $PuppetMetadataJson
  }

  End { }
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

Function Get-PowerShellDscModule {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string[]]
    $Name
  )

  Begin { }
  Process {
    If ($null -eq $Name) {
      $Name = Find-Module -DscResource * -Name * |
        Select-Object -ExpandProperty Name
    }

    ForEach ($NameToSearch in $Name) {
      $Response = Find-Module -Name $NameToSearch -AllVersions
      [PSCustomObject]@{
        Name     = $NameToSearch
        Releases = $Response.Version
      }
    }
  }
  End { }
}

Function ConvertTo-StandardizedVersionString {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [version[]]
    $Version
  )
  Begin { }
  Process {
    ForEach ($VersionToProcess in $Version) {
      $StandardizedVersion = [PSCustomObject]@{
        Major    = $VersionToProcess.Major
        Minor    = $VersionToProcess.Minor
        Build    = $VersionToProcess.Build
        Revision = $VersionToProcess.Revision
      }
      if ($StandardizedVersion.Minor -eq -1) {
        $StandardizedVersion.Minor = 0
      }
      if ($StandardizedVersion.Major -eq -1) {
        $StandardizedVersion.Major = 0
      }
      if ($StandardizedVersion.Build -eq -1) {
        $StandardizedVersion.Build = 0
      }
      if ($StandardizedVersion.Revision -eq -1) {
        $StandardizedVersion.Revision = 0
      }
      "$($StandardizedVersion.Major).$($StandardizedVersion.Minor).$($StandardizedVersion.Build).$($StandardizedVersion.Revision)"
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
