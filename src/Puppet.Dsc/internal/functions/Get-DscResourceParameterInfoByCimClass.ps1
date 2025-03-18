Function Get-DscResourceParameterInfoByCimClass {
  <#
    .SYNOPSIS
      Retrieve the DSC Parameter information, if possible, by CIM Instance.

    .DESCRIPTION
      Given a DSC Resource Info object, load its CIM Class by invoking it once (ignoring errors) and then
      introspecting its CIM class information in the DSC namespace. This requires running with administrator
      privileges, unfortunately, as access to the CIM classes is privilege-gated.

      It will discover help documentation if it is surfaced in the CIM class (not all resources do so), will
      retrieve and map embedded CIM instances (which `Get-DscResourceParameterInfo` cannot do), but cannot
      retrieve default values as these are not mapped.

    .PARAMETER DscResource
      A Dsc Resource Info object, as returned by Get-DscResource.

    .EXAMPLE
      Get-DscResource -Name PSRepository | Get-DscResourceParameterInfoByCimClass

      Retrieve the Parameter information from the CIM class for the PSRepository Dsc Resource.
  #>
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline)]
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]$DscResource
  )

  Begin {}

  Process {
    # We can assume it will find the right version because this is only ever called after we've munged the PSModulePath
    $ModulePath = Get-Module -ListAvailable -Name $DscResource.ModuleName | Select-Object -ExpandProperty Path
    # Invoke once to load the CIM class information, ignore all errors
    Initialize-DscResourceCimClass -Name $DscResource.Name -ModuleName $ModulePath -ModuleVersion $DscResource.Version -ErrorAction Stop

    # Look for embedded instances, store them for type-definition interpolation.
    $DefinedEmbeddedInstances = @{}
    $EmbeddedInstanceTypes = Get-EmbeddedCimInstance -ClassName $DscResource.ResourceType -Recurse
    If ($EmbeddedInstanceTypes.count -gt 0) {
      # Parse Embedded Instances in reverse, which should figure out nested instances before those that contain them
      [array]::Reverse($EmbeddedInstanceTypes)
      ForEach ($InstanceType in $EmbeddedInstanceTypes) {
        # Handle credential objects separately as they are well-known constructs
        If ($InstanceType -eq 'MSFT_Credential') {
          $DefinedEmbeddedInstances.$InstanceType = 'Optional[Struct[{ user => String[1], password => Variant[String[1], Sensitive[String[1]]] }]]'
        } Else {
          # Capture the metadata in order to parse the Puppet type definition and retrieve the cim instance types.
          $EmbeddedInstanceMetadata = @{}
          $EmbeddedInstanceMetadata.$InstanceType = @{
            cim_instance_type = "Enum['$InstanceType']"
          }
          $CimClassProperties = Get-CimClassPropertiesList -ClassName $InstanceType
          ForEach ($Property in $CimClassProperties) {
            If ($Property.ReferenceClassName -in $DefinedEmbeddedInstances.Keys) {
              # Handle nested instances, wrapping them in the Array datatype if necessary
              If ($Property.CimType -match 'Array') {
                $EmbeddedInstanceMetadata.$InstanceType.$($Property.Name) = "Array[$($DefinedEmbeddedInstances.($Property.ReferenceClassName))]"
              } Else {
                $EmbeddedInstanceMetadata.$InstanceType.$($Property.Name) = $DefinedEmbeddedInstances.($Property.ReferenceClassName)
              }
            } Else {
              # If it's not a CIM instance the standard type mapper can handle it.
              $EmbeddedInstanceMetadata.$InstanceType.$($Property.Name) = Get-PuppetDataType -DscResourceProperty @{
                Values       = $Property.Qualifiers['Values'].Value
                IsMandatory  = $Property.Flags -Match 'Required'
                # Replace the Array identifier with [] to match current expectations
                PropertyType = $Property.CimType -Replace '(\S+)Array$', '$1[]'
              }
            }
          }
          # Nested CIM instances need to be reassembled into readable Structs; but we want to increase the indentation level by one
          # so that it's more visually distinct in the end file
          $StructComponents = $EmbeddedInstanceMetadata.$InstanceType.Keys.toLowerInvariant() |
            ForEach-Object -Process { "$_ => $($EmbeddedInstanceMetadata.$InstanceType.$_ -replace "`n", "`n  ")" }
          # Assemble the current CIM instance as a struct, strip out any double quotes to prevent breaking parsing
          $DefinedEmbeddedInstances.$InstanceType = "Struct[{`n  $($StructComponents -join ",`n  " -replace '"')`n}]"
        }
      }
    }

    # Do some slight property handling to ignore properties we don't care about.
    # Minimally adapted from Ansible's implementation:
    # - https://github.com/ansible-collections/ansible.windows/blob/main/plugins/modules/win_dsc.ps1#L42-L62
    # Which itself borrows from core DSC:
    # - https://github.com/PowerShell/PowerShell/blob/master/src/System.Management.Automation/DscSupport/CimDSCParser.cs#L1203
    $PropertiesToDiscard = @('ConfigurationName', 'DependsOn', 'ModuleName', 'ModuleVersion', 'ResourceID', 'SourceInfo')
    $DscResourceCimClassProperties = Get-CimClassPropertiesList -ClassName $DscResource.ResourceType |
      Where-Object { $_.Name -notin $PropertiesToDiscard }

    $DscResourceMetadata = @{}

    # Similarly to how the properties were resolved for embedded CIM instances, resolve them for each property
    ForEach ($Property in $DscResourceCimClassProperties) {
      $IsMandatory = $Property.Flags -Match '(Required|Key)'
      $DscResourceMetadata.$($Property.Name) = [ordered]@{
        Name              = $Property.Name.ToLowerInvariant()
        # The one thing we *can't* retrieve here is the default values; they still apply, but they're
        # not exposed in the definition here for some reason. In the alternate implementation, we can
        # only retrieve default values by parsing the AST, so this is acceptable, if not ideal.
        DefaultValue      = $null
        Help              = $Property.Qualifiers['Description'].Value
        is_parameter      = Test-DscResourcePropertyParameterStatus -Property $Property
        is_namevar        = ($Property.Flags -Match 'Key').ToString().ToLowerInvariant()
        is_read_only      = $Property.Flags.HasFlag([Microsoft.Management.Infrastructure.CimFlags]::ReadOnly)
        mandatory_for_get = $IsMandatory.ToString().ToLowerInvariant()
        mandatory_for_set = $IsMandatory.ToString().ToLowerInvariant()
        mof_is_embedded   = 'false'
      }
      If ($Property.ReferenceClassName -in $DefinedEmbeddedInstances.Keys) {
        $DscResourceMetadata.$($Property.Name).mof_is_embedded = 'true'
        $MofType = $Property.ReferenceClassName
        # Munge the type name per the expectations/surface from Get-DscResource and existing provider.
        If ($MofType -eq 'MSFT_Credential') { $MofType = 'PSCredential' }
        $DscResourceMetadata.$($Property.Name).mof_type = if ($Property.CimType -match 'Array') {
          "$MofType[]"
        } Else {
          $MofType
        }
        # Split the definition for the struct and toss away the cim_instance_type key as this is a top-level property
        # and that information is captured in the mof_type key already.
        $SplitDefinition = $DefinedEmbeddedInstances.($Property.ReferenceClassName) -split "`n" |
          Where-Object -FilterScript { $_ -notmatch "cim_instance_type => Enum\['$($Property.ReferenceClassName)'\]" }
        # Recombine the struct definition appropriately mapped as an array or singleton
        If ($Property.CimType -match 'Array') {
          $PuppetType = "Array[$($SplitDefinition -Join "`n")]"
          $DscResourceMetadata.$($Property.Name).Type
        } Else {
          $PuppetType = "$($SplitDefinition -Join "`n")"
        }
        If ($IsMandatory -or ($PuppetType -match '^Optional\[')) {
          $DscResourceMetadata.$($Property.Name).Type = $PuppetType
        } Else {
          $DscResourceMetadata.$($Property.Name).Type = "Optional[$PuppetType]"
        }
      } Else {
        $DscResourceMetadata.$($Property.Name).mof_type = $Property.CimType -Replace '(\S+)Array$', '$1[]'
        $DscResourceMetadata.$($Property.Name).Type = Get-PuppetDataType -DscResourceProperty @{
          Values       = $Property.Qualifiers['Values'].Value
          IsMandatory  = $Property.Flags -Match '(Required|Key)'
          # Replace the Array identifier with [] to match current expectations
          PropertyType = $Property.CimType -Replace '(\S+)Array$', '[$1[]]'
        }
      }
    }

    ForEach ($Property in $DscResourceMetadata.Keys) {
      # Each object has the Name, DefaultValue, Help, mandatory_for_get, mandatory_for_set, mof_type, & Type properties
      # This is the surface that Get-TypeParameterContent expects for processing a resource.
      [PSCustomObject]$DscResourceMetadata.$Property
    }
  }

  End {}
}
