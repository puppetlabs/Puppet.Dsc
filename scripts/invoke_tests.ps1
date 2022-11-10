[cmdletbinding()]
Param(
  [Parameter(Mandatory = $true)]
  [string[]]$TestPath,
  [Parameter(Mandatory = $true)]
  [string]$ResultsPath,
  [string]$Tag,
  [string]$PwshLibSource,
  [string]$PwshLibRepo,
  [string]$PwshLibReference
)

$ErrorActionPreference = 'Stop'

Get-Module -Name Pester | Remove-Module
Import-Module -Name Pester -MinimumVersion 5.0.0

$ProjectRoot = Split-Path -Parent $PSCommandPath | Split-Path -Parent | Resolve-Path

Import-Module -Name (Join-Path -Path $ProjectRoot -ChildPath 'src/Puppet.Dsc/puppet.dsc.psd1')

$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Output.Verbosity = 'Detailed'
$PesterConfiguration.Run.PassThru = $true

If ($ResultsPath) {
  $PesterConfiguration.TestResult.Enabled = $true
  $PesterConfiguration.TestResult.OutputPath = $ResultsPath
}

If ($null -ne $Tag) {
  $PesterConfiguration.Filter.Tag = $Tag
}

If ($null -ne $PwshLibSource) {
  $Data = @{
    PwshLibSource = $PwshLibSource
    PwshLibRepo   = $PwshLibRepo
  }
  # Ignore reference if not specified or specified as latest (needed for CI)
  If (![string]::IsNullOrEmpty($PwshLibReference) -and 'latest' -ne $PwshLibReference) { $Data.PwshLibReference = $PwshLibReference }
  $PesterConfiguration.Run.Container = New-PesterContainer -Path $TestPath -Data $Data
} Else {
  $PesterConfiguration.Run.Path = $TestPath
}

Invoke-Pester -Configuration $PesterConfiguration
