[cmdletbinding()]
Param(
  [switch]$Full
)

$ErrorActionPreference = 'Stop'

$PowerShellModules = @(
  @{ Name = 'PSFramework' }
  @{ Name = 'powershell-yaml' }
  @{ Name = 'PSScriptAnalyzer' }
  @{ Name = 'xPSDesiredStateConfiguration' }
  @{ Name = 'PSDscResources' }
  @{ Name = 'PowerShellGet'}
  @{ Name = 'Pester'}
)

If ($Full) {
  $ChocolateyPackages += 'pdk'
  $PuppetInstalled = Get-Command puppet -ErrorAction SilentlyContinue
  If ($null -eq $PuppetInstalled) {
    $ChocolateyPackages += 'puppet-agent'
  }
}

If ($Full -or $ENV:CI -eq 'True') {
  Write-Host 'Ensuring WinRM is configured for DSC'
  Get-ChildItem WSMan:\localhost\Listener\ -OutVariable Listeners | Format-List * -Force
  $HTTPListener = $Listeners | Where-Object -FilterScript { $_.Keys.Contains('Transport=HTTP') }
  If ($HTTPListener.Count -eq 0) {
    winrm create winrm/config/Listener?Address=*+Transport=HTTP
    winrm e winrm/config/listener
  }
}

Write-Host "Installing with choco: $ChocolateyPackages"

choco install $ChocolateyPackages --yes --no-progress --stop-on-first-failure --ignore-checksums
if ($LastExitCode -ne 0) {
  throw 'Installation with choco failed.'
}

Write-Host 'Reloading Path to pick up installed software'
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1
Update-SessionEnvironment

Write-Host "Installing $($PowerShellModules.Count) modules with Install-Module"
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
ForEach ($Module in $PowerShellModules) {
  $InstalledModuleVersions = Get-Module -ListAvailable $Module.Name -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Version
  If ($Module.ContainsKey('RequiredVersion')) {
    $AlreadyInstalled = $null -ne ($InstalledModuleVersions | Where-Object -FilterScript { $_ -eq $Module.RequiredVersion })
  } Else {
    $AlreadyInstalled = $null -ne $InstalledModuleVersions
  }
  If ($AlreadyInstalled) {
    Write-Verbose "Skipping $($Module.Name) as it is already installed at $($InstalledModuleVersions)"
  } Else {
    Write-Verbose "Installing $($Module.Name)"
    Install-Module @Module -Force -SkipPublisherCheck -AllowClobber
  }
}

