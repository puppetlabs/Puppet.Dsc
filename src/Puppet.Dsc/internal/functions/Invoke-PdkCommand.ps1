Function Invoke-PdkCommand {
  <#
    .SYNOPSIS
      Run a PDK command
    .DESCRIPTION
      Run a PDK command and control for errors and output.
    .PARAMETER Path
      Specifies the path from which the PDK command should be run; many PDK commands are only
      valid from inside the root folder of a Puppet module.
    .PARAMETER Command
      The String to execute as a PDK command.
    .PARAMETER SuccessFilterScript
      The scriptblock representing a Where-Object FilterScript which will iterate over the stderr
      from the PDK command (which is how it writes output), looking for a an error whose exception
      meets the FilterScript criteria.

      If none of the stderr messages meet the success criteria, the PDK command is assumed to have
      failed and will throw the last message from stderr as an exception.
    .PARAMETER ErrorFilterScript
      The scriptblock representing a Where-Object FilterScript which will iterate over the stderr
      from the PDK command (which is how it writes output), looking for a an error whose exception
      meets the FilterScript criteria.

      If any of the stderr messages meet the error criteria, the PDK command is assumed to have
      failed and will throw the last message from stderr as an exception.
    .EXAMPLE
      Invoke-PDKCommand -Command 'pdk new module foo' -SuccessFilterScript {
        $_ -match "Module 'foo' generated at path"
      }

      This command will run in the current directory, creating a new Puppet module `foo` there. If
      none of the messages from the PDK command match the filterscript it will throw an exception.
  #>
  [CmdletBinding()]
  param(
    [System.String]$Path = '.',
    [Parameter(Mandatory = $True)]
    [System.String]$Command,
    [System.Management.Automation.ScriptBlock]$SuccessFilterScript,
    [System.Management.Automation.ScriptBlock]$ErrorFilterScript,
    [switch]$PassThru
  )

  begin {
    $Path = Resolve-Path $Path -ErrorAction Stop

    $ScriptBlock = [ScriptBlock]::Create("
      Push-Location -Path $Path
      $Command *>&1
    ")
  }

  process {
    Write-PSFMessage -Level Debug -Message "Invoke-PdkCommand -Path '$($Path)' -Command '$($Command)'"

    $PdkResults = Start-Job -ScriptBlock $ScriptBlock | Wait-Job
    $PdkJob = $PdkResults.ChildJobs[0]

    Write-PSFMessage -Level Debug -Message "Output: $($PdkJob.Output)"

    if ($null -ne $SuccessFilterScript) {
      $PdkSuccessMessage = $PdkJob.Output | Where-Object -FilterScript $SuccessFilterScript
    } Else {
      $PdkSuccessMessage = $null
    }

    $hasSuccessFilterScript = ($null -ne $SuccessFilterScript)
    $hasSuccessMatch = ($null -ne $PdkSuccessMessage)
    If ($hasSuccessFilterScript -and -not $hasSuccessMatch) {
      Throw "Command '$Command' failed to match success condition $($SuccessFilterScript):`n$($PdkJob.Output)"
    }

    if ($null -ne $ErrorFilterScript) {
      $PdkErrorMessage = $PdkJob.Output | Where-Object -FilterScript $ErrorFilterScript
    } Else {
      $PdkErrorMessage = $null
    }

    $hasErrorFilterScript = ($null -ne $ErrorFilterScript)
    $hasErrorMatch = ($null -ne $PdkErrorMessage)
    If ($hasErrorFilterScript -and $hasErrorMatch) {
      Throw "Command '$Command' matched error condition $($ErrorFilterScript):`n$($PdkJob.Output)"
    }

    Write-PSFMessage -Level Debug -Message "Command '$Command' executed successfully:`n$($PdkJob.Output)"
    if ($PassThru) {
      $PdkJob.Output
    }
  }

  end { }
}
