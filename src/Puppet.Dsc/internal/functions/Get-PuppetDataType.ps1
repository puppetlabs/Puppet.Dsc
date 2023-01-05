Function Get-PuppetDataType {
  <#
    .SYNOPSIS
      Get the representation of a DSC Resource Property Type as a Puppet Resource API Data Type
    .DESCRIPTION
      This function provides a way of generating strongly typed Puppet Resource API attributes by
      introspecting a DSC Resource's properties to provide as much useful feedback to manifest
      authors at manifest-write time and catalog-compilation.

      It cannot currently discover the proper structure for most embedded instances, though the
      embedded instance schema for PSCredentials *has* been included.
    .PARAMETER DscResourceProperty
      The DscResourcePropertyInfo object which represents a single property for a given DSC resource.
    .EXAMPLE
      Get-PuppetDataTYpe -DscResourceProperty $DscResource.Properties[0]

      This will return a string representing the Puppet Data type that most closely equates to the
      PowerShell data type that this Property has.
  #>
  [cmdletbinding()]
  [OutputType([String])]
  Param(
    # We cannot strongly type this *and* have useful unit tests as the type
    # has read-only values and cannot be created properly nor updated. For
    # other commands we could just grab real examples but for processing a
    # ton of data types, that's just not feasible. It *should* be:
    # Microsoft.PowerShell.DesiredStateConfiguration.DscResourcePropertyInfo
    [ValidateNotNullOrEmpty()]
    $DscResourceProperty
  )
  # https://docs.microsoft.com/en-us/dotnet/api/system.numerics.biginteger?view=netframework-4.8
  # https://docs.microsoft.com/en-us/dotnet/api/system.numerics.complex?view=netframework-4.8 - Can we represent a complex number in Puppet? Do we want to?
  # https://docs.microsoft.com/en-us/dotnet/api/system.intptr?view=netframework-4.8
  $OtherIntegers = @(
    'bigint'
    'IntPtr'
    'UIntPtr'
  )
  # https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types
  $Floats = @(
    'single'
    'double'
    'decimal'
  )
  If (![String]::IsNullOrEmpty($DscResourceProperty.Values)) {
    # Enums are handles specially
    $InnerText = [System.Collections.ArrayList]::new()
    $DscResourceProperty.Values | ForEach-Object -Process {
        $null = $InnerText.Add("'$_'")
        $null = $innerText.Add("'$($_.toLower())'")
    }
    $PuppetDataTypeText = "Enum[$(($InnerText | Select-Object -Unique) -join ', ')]"
  } Else {
    If (Test-EmbeddedInstance -PropertyType $DscResourceProperty.PropertyType) {
      # TODO: We SHOULD be able to walk our way to the nested data structure for these Hashes
      $PuppetDataTypeText = 'Hash'
    } Else {
      # Strip the brackets away for easier comparison; arrays are handled later anyway
      $DataTypeName = $DscResourceProperty.PropertyType -replace '(\[|\])', $null
      $PuppetDataTypeText = switch ($DataTypeName) {
        { $_ -in 'Bool', 'Boolean' } { 'Boolean' }
        'String' { 'String' }
        # https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/integral-numeric-types
        'byte' { 'Integer[0, 255]' }
        'Uint16' { 'Integer[0, 65535]' }
        'Uint32' { 'Integer[0, 4294967295]' }
        'Uint64' { 'Integer[0, 18446744073709551615]' }
        'Real32' { 'Float' }
        'Real64' { 'Float' }
        'sybte' { 'Integer[-128, 127]' }
        { $_ -in 'int16', 'SInt16' } { 'Integer[-32768, 32767]' }
        { $_ -in 'int', 'int32', 'SInt32' } { 'Integer[-2147483648, 2147483647]' }
        { $_ -in 'int64', 'SInt64' } { 'Integer[-9223372036854775808, 9223372036854775807]' }
        { $_ -in $OtherIntegers } { 'Integer' }
        { $_ -in $Floats } { 'Float' }
        'PSCredential' { 'Struct[{ user => String[1], password => Sensitive[String[1]] }]' }
        # Can we mandate that an attribute be a sensitive string? Does this even make sense?
        'SecureString' { 'Sensitive[String]' }
        # TODO: Should this just be a string? Do we need/want to validate this?
        'DateTime' { 'Timestamp' }
        'HashTable' { 'Hash' }
        'Char' { 'String[1,1]' }
        # This is kinda gross, but this only came up once in 350+ module builds
        'Object' { 'Any' }
        default {
          # Better to scream loudly than write an invalid type?
          # Optionally include a Force param to put down `Any` as the data type?
          Throw "Cannot convert DSC Type '$($DscResourceProperty.PropertyType)'"
        }
      }
    }
  }

  If ($DscResourceProperty.PropertyType -match [Regex]::Escape('[]')) {
    $PuppetDataTypeText = "Array[$($PuppetDataTypeText)]"
  }

  # Special case PSCredential for now to always be optional
  If (($True -eq $DscResourceProperty.IsMandatory) -and ('PSCredential' -ne $DataTypeName)) {
    $PuppetDataTypeText
  } Else {
    "Optional[$PuppetDataTypeText]"
  }
}
