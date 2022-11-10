function Add-DscResourceModule {
  <#
  .SYNOPSIS
    Vendor PowerShell modules into the build folder either by path or by retrieving the modules from the Gallery

  .DESCRIPTION
    Given a DSC module name (and optional version) this will download and unpack the module and its dependencies
    to the local machine. See Save-Module for additional information on what is happening.


  .PARAMETER Name
    Specifies the name of the module to save.

  .PARAMETER Path
    Specifies the location on the local computer to store the saved module.

  .PARAMETER RequiredVersion
    Specifies the exact version number of the module to save.
    If left blank, will default to latest available.

  .PARAMETER Repository
    Specifies a PSRepository.

  .PARAMETER AllowPrerelease
    Allows you to Puppetize a module marked as a prerelease.

  .EXAMPLE
    Add-DscResourceModule -TargetDir ./tmp -Name PowerShellGet -Version 2.2.3 -Repository PSGallery

    This example will search the PowerShell gallery for version `2.2.3` of the PowerShellGet and,
    if it finds it, save the module and its dependencies into a folder called `./tmp`.
  #>
  [CmdletBinding()]
  param (
    $Name,
    $Path,
    $RequiredVersion,
    $Repository,
    [switch]$AllowPrerelease
  )

  Begin { }

  Process {
    if (-not(Test-Path $Path)) {
      if (-not(Test-Path $Path)) {
        $null = New-Item -Path $Path -Force -ItemType 'Directory'
      }
      $PathTmp = ($Path -Replace '(/|\\)$', $Null) + '_tmp'
      if (-not(Test-Path $PathTmp)) {
        $null = New-Item -Path $PathTmp -Force -ItemType 'Directory'
      }
      Save-Module -Name $Name -Path $PathTmp -RequiredVersion $RequiredVersion -Repository $Repository -AllowPrerelease:$AllowPrerelease
      # Validate dependency modules are in the temp path
      $SavedModule = Get-Module -Name "$PathTmp/$Name" -ListAvailable
      ForEach ($RequiredModule in $SavedModule.RequiredModules) {
        # If the required module does not exist, as when it is not available on the gallery,
        # Try to find it locally and copy it over
        If ((Test-Path "$PathTmp/$RequiredModule")) {
          continue
        }
        Try {
          $Module = Get-Module -Name $RequiredModule -ListAvailable -ErrorAction Stop
          Copy-Item -Path (Split-Path -Path $Module.Path -Parent) -Destination $PathTmp -Container -Recurse -ErrorAction Stop
        } Catch {
          $PSCmdlet.ThrowTerminatingError($_)
        }
      }
      # Move the modules to the appropriate folder
      ForEach ($ModuleFolder in (Get-ChildItem $PathTmp)) {
        Move-Item -Path (Get-ChildItem $ModuleFolder.FullName).FullName -Destination "$Path/$($ModuleFolder.Name)"
      }
      Remove-Item $PathTmp -Recurse
    }
  }

  End { }
}
