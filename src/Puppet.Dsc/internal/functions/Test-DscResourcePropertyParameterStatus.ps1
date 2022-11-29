Function Test-DscResourcePropertyParameterStatus {
  <#
    .SYNOPSIS
      Return whether or not a DSC Resource Property can be read from a target system
    .DESCRIPTION
      Some DSC Resources have properties which cannot be read back from a target system
      with the Get method. These properties are classified as parameters in Puppet.
    .PARAMETER Property
      The DSC Resource property to check for parameter status
    .EXAMPLE
      Test-DscResourcePropertyParameterStatus -Property $DscResource.Properties[0]

      This will return `$True` if the property is a parameter and `$False` otherwise.
  #>
  [cmdletbinding()]
  [OutputType([Boolean])]
  Param(
    # We cannot strongly type this *and* have useful unit tests as the type
    # has read-only values and cannot be created properly nor updated. For
    # other commands we could just grab real examples but for processing a
    # ton of data types, that's just not feasible. It *should* be:
    # Microsoft.PowerShell.DesiredStateConfiguration.DscResourcePropertyInfo
    [ValidateNotNullOrEmpty()]
    $Property
  )

  $KnownParameters = @(
    'Force'
    'JoinOU'
    'KeyUsage'
    'OID'
    'Purge'
    'Validate'
  )

  $Property.Name -in $KnownParameters -or $Property.ReferenceClassName -match 'Credential'
}
