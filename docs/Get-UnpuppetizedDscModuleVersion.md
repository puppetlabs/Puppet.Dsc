---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Get-UnpuppetizedDscModuleVersion

## SYNOPSIS
Search for versions of a PowerShell module not released to a Puppet feed

## SYNTAX

```
Get-UnpuppetizedDscModuleVersion [-ForgeNameSpace] <String> [[-Name] <String[]>] [[-MinimumVersion] <String>]
 [-OnlyNewer] [[-Repository] <String>] [[-ForgeSearchUri] <String>] [<CommonParameters>]
```

## DESCRIPTION
Search a PowerShell repository and Puppet forge feed feed to discover any
versions of one or modules which have been released to the PowerShell
repository but not yet Puppetized and published to the Puppet Forge.
If
a module has not been Puppetized at all, returns *all* discovered versions
of that module from the PowerShell repository.

## EXAMPLES

### EXAMPLE 1
```
Get-UnpuppetizedDscModuleVersion -Name foo
```

This will look for all versions of the foo module published to the
PowerShell Gallery but not to the Puppet Forge in the 'dsc' namespace,
including versions older than any currently Puppetized.

### EXAMPLE 2
```
Get-UnpuppetizedDscModuleVersion -Name foo -MinimumVersion 1.0
```

This will look for all versions of the foo module published to the
PowerShell Gallery but not to the Puppet Forge in the 'dsc' namespace,
so long as they are newer than 1.0.0.0.

### EXAMPLE 3
```
Get-UnpuppetizedDscModuleVersion -Name foo -OnlyNewer
```

This will look for all versions of the foo module published to the
PowerShell Gallery but not to the Puppet Forge in the 'dsc' namespace,
including only those versions newer than the latest published to the
Puppet Forge.

### EXAMPLE 4
```
Get-UnpuppetizedDscModuleVersion -Name foo -Repository Internal -ForgeNameSpace my_company
```

This will look for all versions of the foo module published to the
'Internal' PowerShell repository but not to the Puppet Forge in the
'my_company' namespace, including versions older than any currently Puppetized.

## PARAMETERS

### -ForgeNameSpace
The namespace on the Forge to search for modules

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of one or more PowerShell modules to search for.
If no name is
specified, will compare all PowerShell modules with DSC Resources in the
specified Repository to the Forge to find unpuppetized module versions.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumVersion
The minimum version to return; any released versions equal to or newer
than this which have been published to the PowerShell repository but not
the Puppet Forge will be returned.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnlyNewer
Only return versions of the PowerShell module on the PowerShell repository
which are newer than the highest version release of the module in the
Puppet Forge.
Use to prevent building legacy versions if not needed.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Repository
The PowerShell repository to search; defaults to the PowerShell Gallery

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForgeSearchUri
The Puppet Forge API URI to search; defaults to the public Puppet Forge

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### [PSCustomObject] Returns an object with the Name property for the name of
### the module and Versions as an array of the module versions which have not
### been Puppetized and published to the Puppet Forge yet.
## NOTES

## RELATED LINKS
