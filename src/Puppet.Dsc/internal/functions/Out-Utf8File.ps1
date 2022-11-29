Function Out-Utf8File {
  <#
    .SYNOPSIS
      Sends output to a UTF8 file without a BOM.
    .DESCRIPTION
      Sends output to a UTF8 file without a BOM.
    .PARAMETER Path
      Specifies the path to the output file.
    .PARAMETER InputObject
      Specifies the objects to be written to the file.
      Enter a variable that contains the objects or type a command or expression that gets the objects.
    .EXAMPLE
      Out-File -Path ./foo.json -InputObject ($MyObject | ConvertFrom-Json)
      This command will write the JSON string representation of $MyObject to `./foo.json` with a
      UTF8 encoding, no BOM.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [psobject]$InputObject
  )

  begin {}

  process {
    [IO.File]::WriteAllLines($Path, $InputObject)
  }

  end {}
}