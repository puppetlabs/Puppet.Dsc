Function Export-PuppetModule {
  <#
  .SYNOPSIS
    Build a Puppet module with the PDK
  .DESCRIPTION
    Build a Puppet module with the PDK as a .tar.gz
  .PARAMETER PuppetModuleFolderPath
    The path to the folder where the Puppet module to build exists
  .PARAMETER ExportFolderPath
    The path to the folder for the built module to be placed in. If not specified,
    builds in the pkg folder inside the PuppetModuleFolderPath. If the specified
    ExportFolderPath does not exist, the PDK will create it.
  .PARAMETER Force
    Specify this switch to force a build of the module even if it already exists
  .PARAMETER PassThru
    Specify this switch to capture the output of the PDK build command and return it
  .EXAMPLE
    Export-PuppetModule -PuppetModuleFolderPath ./import/powershellget
    This command will invoke the PDK to build the powershellget module in the
    specified folder path.
  .INPUTS
    None.
  .OUTPUTS
    [Object[]] If the PassThru switch is specified, returns the output from the
    PDK execution, including any error records.
  #>

  [CmdletBinding()]
  Param (
    [parameter(Mandatory)]
    [string]$PuppetModuleFolderPath,
    [string]$ExportFolderPath,
    [switch]$Force,
    [switch]$PassThru
  )

  begin {
    $Command = 'pdk build'
    If ($Force) { $Command += ' --force' }
    If (![string]::IsNullOrEmpty($ExportFolderPath)) { $Command += " --target-dir $ExportFolderPath" }
  }

  process {
    $PuppetModuleFolderPath = Resolve-Path $PuppetModuleFolderPath -ErrorAction Stop |
      Select-Object -ExpandProperty Path
    Write-PSFMessage -Level Verbose "Invoking ``$Command`` from $PuppetModuleFolderPath"
    Invoke-PdkCommand -Path $PuppetModuleFolderPath -Command $Command -PassThru:$PassThru -SuccessFilterScript {
      $_ -match 'has completed successfully. Built package can be found here'
    }
  }

  end {}
}