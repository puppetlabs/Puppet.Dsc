Function ConvertTo-UnescapedJson {
  <#
    .SYNOPSIS
      Convert a  PowerShell object to JSON *without* Unicode escapes
    .DESCRIPTION
      Convert a  PowerShell object to JSON *without* Unicode escapes
    .PARAMETER InputObject
      Specifies the objects to convert to JSON format.
      Enter a variable that contains the objects, or type a command or expression that gets the objects.
      You can also pipe an object to ConvertTo-Json.

      The InputObject parameter is required, but its value can be null ($null) or an empty string.
      When the input object is $null, ConvertTo-Json does not generate any output.
      When the input object is an empty string, ConvertTo-Json returns an empty string.
    .PARAMETER Depth
      Specifies how many levels of contained objects are included in the JSON representation. The default value is 2.
    .PARAMETER Compress
      Omits white space and indented formatting in the output string.
    .EXAMPLE
      ConvertTo-UnescapedJson -InputObject @{a = '>=1'}

      Using `ConvertTo-Json` here would output `"a": "\u003e=1"` instead of the
      correct output, `"a": ">=1"`, so running `ConvertTo-UnescapedJson` instead
      ensures the correct string to be passed along.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [AllowNull()]
    [System.Object]
    ${InputObject},

    [ValidateRange(1, 2147483647)]
    [int]
    ${Depth},

    [switch]
    ${Compress})

  begin {
    try {
      $outBuffer = $null
      if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
        $PSBoundParameters['OutBuffer'] = 1
      }
      $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\ConvertTo-Json', [System.Management.Automation.CommandTypes]::Cmdlet)
      $scriptCmd = {
        & $wrappedCmd @PSBoundParameters | ForEach-Object -Process {
          [System.Text.RegularExpressions.Regex]::Unescape($_)
        }
      }
      $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
      $steppablePipeline.Begin($PSCmdlet)
    } catch {
      throw
    }
  }

  process {
    try {
      $steppablePipeline.Process($_)
    } catch {
      throw
    }
  }

  end {
    try {
      $steppablePipeline.End()
    } catch {
      throw
    }
  }
  <#
    .ForwardHelpTargetName Microsoft.PowerShell.Utility\ConvertTo-Json
    .ForwardHelpCategory Cmdlet
  #>
}