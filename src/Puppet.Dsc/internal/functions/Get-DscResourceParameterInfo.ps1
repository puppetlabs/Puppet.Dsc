function Get-DscResourceParameterInfo {
  <#
    .SYNOPSIS
      Retrieve the DSC Parameter information, if possible

    .DESCRIPTION
      Given a DSC Resource Info object, introspect on the source (if possible) to return information about
      the resources parameters, including their help text, whether or not they are mandatory for calling the
      resource with the Get method, and whether or not they are mandatory for calling the resource with the
      Set method.

      This information can be reliably retrieved if the DSC resource is implemented in PowerShell and is
      not class based. Otherewise, best guesses are made about the mandatory status of the parameters via
      the Required attribute and the help information is null.

    .PARAMETER DscResource
      A Dsc Resource Info object, as returned by Get-DscResource.

    .EXAMPLE
      Get-DscResource -Name PSRepository | Get-DscResourceParameterInfo

      Retrieve the Parameter information from the AST for the PSRepository Dsc Resource.
  #>
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline)]
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]$DscResource
  )

  Begin {}

  Process {
    If ($DscResource.ImplementedAs -eq 'PowerShell') {
      $ParsedAst = [system.management.automation.language.parser]::ParseFile($DscResource.Path, [ref]$null, [ref]$null)
    }
    If ($null -ne $ParsedAst) {
      # We can currently only retrieve parameter metadata from function and composite DSC resources, not class-based :(
      # There are probably more elegant AST filters but this worked for now.
      $GetFunctionAst = $ParsedAst.FindAll( { $true }, $true) | Where-Object -FilterScript { $_.Name -eq 'Get-TargetResource' }
      $SetFunctionAst = $ParsedAst.FindAll( { $true }, $true) | Where-Object -FilterScript { $_.Name -eq 'Set-TargetResource' }
      $FilterForMandatoryParameters = {
        $MandatoryAttribute = $_.Attributes.NamedArguments | Where-Object -FilterScript {
          $_.ArgumentName -eq 'Mandatory' -and
          [string]$_.Argument -eq '$true'
        }
        $null -ne $MandatoryAttribute
      }
      If ($null -ne $GetFunctionAst) {
        $MandatoryGetParameters = $GetFunctionAst.body.ParamBlock.Parameters |
          Where-Object -FilterScript $FilterForMandatoryParameters
      }
      If ($null -ne $SetFunctionAst) {
        $MandatorySetParameters = $SetFunctionAst.body.ParamBlock.Parameters |
          Where-Object -FilterScript $FilterForMandatoryParameters
        # We only care about searching for help info on the set as it's the closest analog
        $HelpInfo = $SetFunctionAst.GetHelpContent().Parameters
      }
    }
    # We iterate over the allowed properties to get those that will work via Invoke-DscResource
    # We filter out the DependsOn and WaitFor properties as they're not used with Invoke-DscResource.
    # Note that this will always return PSDscRunAsCredential (if run on 5x), which doesn't work in 7+
    $AllowedProperties = $DscResource.Properties | Where-Object -FilterScript {
      $_.Name -NotMatch '(dependson|waitfor.*)'
    }
    ForEach ($Parameter in $AllowedProperties) {
      If ($null -ne $HelpInfo) {
        $ParameterDescription = $HelpInfo[$Parameter.Name.ToUpper()]
        If ($null -ne $ParameterDescription) { $ParameterDescription = $ParameterDescription.Trim() }
      } Else { $ParameterDescription = $null }
      If ($null -ne $SetFunctionAst) {
        $MandatorySet = ("`$$($Parameter.Name)" -in [string[]]$MandatorySetParameters.Name)
        $DefaultValue = $SetFunctionAst.body.ParamBlock.Parameters |
          Where-Object -FilterScript { $_.Name -match [string]$Parameter.Name } |
          Select-Object -ExpandProperty DefaultValue
      } Else { $MandatorySet = $Parameter.IsMandatory }
      If ($null -ne $GetFunctionAst) {
        $MandatoryGet = ("`$$($Parameter.Name)" -in [string[]]$MandatoryGetParameters.Name)
      } Else { $MandatoryGet = $Parameter.IsMandatory }
      # We want to return all the useful info from allowed_properties PLUS
      # the help (if any), the default set value (if any), and whether or not the param is mandatory
      # for get or set calls (it *may* be manadatory for set but not get) - if we can't parse, default
      # to using the Required designation from Get-DscResource, which only cares about setting.
      $Type = Get-PuppetDataType -DscResourceProperty $Parameter
      [pscustomobject]@{
        # Downcase the name for the sake of Puppet expectations
        Name              = $Parameter.Name.ToLowerInvariant()
        DefaultValue      = $DefaultValue
        # Type              = $Parameter.Type
        Type              = $Type
        Help              = $ParameterDescription
        # # Turn a boolean into a string and downcase for Puppet language
        mandatory_for_get = $MandatoryGet.ToString().ToLowerInvariant()
        mandatory_for_set = $MandatorySet.ToString().ToLowerInvariant()
        is_parameter      = Test-DscResourcePropertyParameterStatus -Property $Parameter
        # Because we can't check the flags per resource, we have to assume any mandatory params are also namevars
        # This is *not* accurate - properties with the Key flag are namevars whereas ones with Required are merely mandatory
        is_namevar        = $MandatoryGet.ToString().ToLowerInvariant()
        mof_is_embedded   = (Test-EmbeddedInstance -PropertyType $Parameter.PropertyType).ToString().ToLowerInvariant()
        mof_type          = Get-ShortType -PropertyType $Parameter.PropertyType
      }
    }
  }

  End {}
}
