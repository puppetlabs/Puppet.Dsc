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
