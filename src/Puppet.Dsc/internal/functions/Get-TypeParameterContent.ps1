Function Get-TypeParameterContent {
  <#
  .SYNOPSIS
    Return the text for a Puppet Resource API Type attribute given a DSC resource's ParameterInfo
  .DESCRIPTION
    Return the text for a Puppet Resource API Type Attribute (a property or parameter), given a DSC
    Resouce's parameter information. It will return the text but _not_ directly write out the file.
  .PARAMETER ParameterInfo
    A PSCustomObject with the required parameter information added to a DSC resource via the
    Get-DscResourceTypeInformation function.
  .EXAMPLE
    Get-TypeParameterContent (Get-DscResourceTypeInformation -Name PSRepository).ParameterInfo

    This will retrieve a DSC resource from the PSModulePath, retrieve the information
    needed to represent the DSC resource's properties as Puppet Resource API type
    attributes and then return the representation of that DSC resource appropriate
    for the Puppet Resource API.
  #>
  [cmdletbinding()]
  Param (
    [OutputType([String], [String[]])]
    [pscustomobject]$ParameterInfo
  )

  ForEach ($Parameter in $ParameterInfo) {
    if (![string]::IsNullOrEmpty($Parameter.name)) {
      if ($Parameter.name -ne 'ensurable') {
        $Parameter.name = "dsc_$($Parameter.name)"
      }
      New-Object -TypeName System.String @"
    $($Parameter.name): {
      type: $(ConvertTo-PuppetRubyString -String ($Parameter.Type -split "`n" -join "`n            ")),
$(
  If ([string]::IsNullOrEmpty($Parameter.Help)) {
    # This has to be a string with a single space to prevent writing `''` in the reference doc
    # See: https://github.com/puppetlabs/puppet-strings/issues/264
    "      desc: ' ',"
  } Else {
    # Assemble the Description String with appropriate indentation
    "      desc: $(ConvertTo-PuppetRubyString -String ($Parameter.Help.Split("`n") -Join ' ')),"
  }
)
$(    If (![string]::IsNullOrEmpty($Parameter.DefaultValue)) {
    "      default: $($Parameter.DefaultValue),"
})
$(
  $Behaviours = @()
  If ($Parameter.is_namevar -eq 'true') { $Behaviours += ':namevar' }
  If ($Parameter.is_parameter -eq $true) { $Behaviours += ':parameter' }
  If ($Parameter.is_read_only -eq $true) { $Behaviours += ':read_only' }
  If ($Behaviours.count -eq 1) {
    "      behaviour: $($Behaviours[0]),"
  } ElseIf ($Behaviours.count -gt 1) {
    "      behaviour: [$($Behaviours -join ', ')],"
  }
)
      mandatory_for_get: $($Parameter.mandatory_for_get),
      mandatory_for_set: $($Parameter.mandatory_for_set),
      mof_type: $(ConvertTo-PuppetRubyString -String $Parameter.mof_type),
      mof_is_embedded: $($Parameter.mof_is_embedded),
    },
"@
    }
  }
}