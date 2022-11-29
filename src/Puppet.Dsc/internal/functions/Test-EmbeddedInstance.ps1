Function Test-EmbeddedInstance {
  <#
    .SYNOPSIS
      Return whether or not a parameter is an embedded instance
    .DESCRIPTION
      Some DSC resources have data types which map to embedded CIM instances, which are something
      like structured hashes. Unfortunately, we cannot know every possible embedded instance type
      and there's no canonical way to check a DSC resource property for whether the property type
      is itself an embedded instance, so our best proxy is to list well-known types.

      THe list below was compiled on 2020-04-20 by building every single module with DSC resources
      on the PowerShell gallery and covering the data types used in those modules which were not
      embedded instances. This is not the full list of valid data types, but it will hopefully be
      sufficient for our purposes and can easily be updated.
    .PARAMETER PropertyType
      THe property type of a DSC resource property
    .EXAMPLE
      Test-EmbeddedInstance -PropertyType $DscResource.Properties[0].PropertyType

      This will return `$True` if the property is an embedded instance and `$False` otherwise.
  #>
  [cmdletbinding()]
  [OutputType([Boolean])]
  Param(
    [string]$PropertyType
  )
  # Check if included in Base Types
  @(
    'Bool'
    'Boolean'
    'Byte'
    'Char'
    'Char16'
    'DateTime'
    'Decimal'
    'Double'
    'Float'
    'Hashtable'
    'Int'
    'Int16'
    'Int32'
    'Int64'
    'Microsoft.Management.Infrastructure.CimInstance'
    'Object'
    'PSCredential'
    'Real32'
    'Real64'
    'SByte'
    'SecureString'
    'Single'
    'SInt16'
    'SInt32'
    'SInt64'
    'String'
    'Uint16'
    'Uint32'
    'Uint64'
  ) -NotContains ($PropertyType -replace '(\[|\])', $null)
}