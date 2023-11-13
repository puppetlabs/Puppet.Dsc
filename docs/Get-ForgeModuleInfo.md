---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Get-ForgeModuleInfo

## SYNOPSIS
Search a Puppet forge for modules with DSC Resources

## SYNTAX

### ByNameSpace (Default)
```
Get-ForgeModuleInfo -ForgeNameSpace <String> [-ForgeSearchUri <String>] [-PaginationBump <Int32>]
 [<CommonParameters>]
```

### ByName
```
Get-ForgeModuleInfo -ForgeNameSpace <String> -Name <String[]> [-ForgeSearchUri <String>] [<CommonParameters>]
```

## DESCRIPTION
Search a Puppet forge for modules with DSC Resources, returning their name,
every release of that module, and the module's PowerShell metadata.

## EXAMPLES

### EXAMPLE 1
```
Get-ForgeModuleInfo -Name powershellget
```

Search the DSC namespace of the Puppet Forge for the powershellget module,
returning it (if it exists) with the list of releases and the metadata for
the PowerShell module it was built from.

## PARAMETERS

### -ForgeNameSpace
The namespace on the Forge to search for modules.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the module to search for on the Forge.
If left unspecified, will
search the entire namespace for modules.

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForgeSearchUri
The URI to the forge api for retrieving modules; by default, the public
Puppet forge (v3).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Https://forgeapi.puppet.com/v3/modules
Accept pipeline input: False
Accept wildcard characters: False
```

### -PaginationBump
If searching a namespace for modules, indicates the number of modules to return
in a single result set, continuing to search until no more modules are discovered.

```yaml
Type: Int32
Parameter Sets: ByNameSpace
Aliases:

Required: False
Position: Named
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### [PSCustomObject[]] One or more objects with the name, releases, and the
### PowerShellModuleInfo properties.
## NOTES

## RELATED LINKS
