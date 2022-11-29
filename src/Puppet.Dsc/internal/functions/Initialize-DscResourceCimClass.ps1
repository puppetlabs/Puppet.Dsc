Function Initialize-DscResourceCimClass {
  <#
    .SYNOPSIS
      Invoke a DSC Resource once to load its CIM class
    .DESCRIPTION
      Invoke a DSC Resource once to load its CIM class into the CIM namespace
      for DSC, allowing other commands to introspect that CIM class.
    .EXAMPLE
      Initialize-DscResourceCimClass -Name PSRepository -ModuleName PowerShellGet -ModuleVersion 2.1.3
      This will assemble the minimum parameters required to invoke the PSRepository resource with the
      Get method, ignoring any/all errors and then do so. Once the invocation has completed, the CIM
      Class is then loaded for other commands to introspect.
  #>
  [cmdletbinding()]
  param(
    [string]$Name,
    [string]$ModuleName,
    [string]$ModuleVersion
  )
  $InvokeParams = @{
    Name        = $Name
    Method      = 'Get'
    Property    = @{foo = 1 }
    ModuleName  = @{
      ModuleName    = $ModuleName
      ModuleVersion = $ModuleVersion
    }
    ErrorAction = 'Stop'
  }
  Try {
    Invoke-DscResource @InvokeParams
  } Catch {
    # We only care if the resource can't be found, not if it fails while executing
    if ($_.Exception.Message -match '(Resource \w+ was not found|The PowerShell DSC resource .+ does not exist at the PowerShell module path nor is it registered as a WMI DSC resource)') {
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }
}
