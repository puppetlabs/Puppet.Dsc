---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Update-ForgeDscModule

## SYNOPSIS
Rebuild and publish Puppetized DSC modules

## SYNTAX

### ByNameSpace (Default)
```
Update-ForgeDscModule -ForgeNameSpace <String> [-ForgeApiUri <String>] [-ForgeToken <String>]
 [-BuildFolderPath <String>] [-PackageFolderPath <String>] [-LatestMajorVersionOnly]
 [-MaximumVersionCountToRebuild <Int32>] [-SleepAfterFailure <Int32>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByNameAndVersion
```
Update-ForgeDscModule -ForgeNameSpace <String> -Name <String[]> -Version <Version> [-ForgeApiUri <String>]
 [-ForgeToken <String>] [-BuildFolderPath <String>] [-PackageFolderPath <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ByName
```
Update-ForgeDscModule -ForgeNameSpace <String> -Name <String[]> [-ForgeApiUri <String>] [-ForgeToken <String>]
 [-BuildFolderPath <String>] [-PackageFolderPath <String>] [-LatestMajorVersionOnly]
 [-MaximumVersionCountToRebuild <Int32>] [-SleepAfterFailure <Int32>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Rebuild and publish Puppetized DSC modules, bumping their Puppet build version by one.

## EXAMPLES

### EXAMPLE 1
```
Update-ForgeDscModule -ForgeNameSpace 'foo'
```

This will search for every Puppetized DSC module in the 'foo' namespace
of the public Puppet Forge and attempt to rebuild and publish (with an
incremented Puppet build version) each release.

### EXAMPLE 2
```
Update-ForgeDscModule -ForgeNameSpace 'foo' -Name 'bar', 'baz'
```

This will search for the 'bar' and 'baz' Puppetized DSC modules in the
'foo' namespace of the public Puppet Forge and attempt to rebuild and
publish (with an incremented Puppet build version) each release of those
modules.

### EXAMPLE 3
```
Update-ForgeDscModule -ForgeNameSpace 'foo' LatestMajorVersionOnly
```

This will search for every Puppetized DSC module in the 'foo' namespace
of the public Puppet Forge and attempt to rebuild and publish (with an
incremented Puppet build version) only releases from the latest major
version of each module; so if a module was released at 2.1.0.0, 2.0.0.0,
1.2.0.0, 1.1.0.0, and 1.0.0.0, only 2.1.0.0 and 2.0.0.0 would be rebuilt
and published.

### EXAMPLE 4
```
Update-ForgeDscModule -ForgeNameSpace 'foo' MaximumVersionCountToRebuild 3
```

This will search for every Puppetized DSC module in the 'foo' namespace
of the public Puppet Forge and attempt to rebuild and publish (with an
incremented Puppet build version) only releases from the latest major
version of each module; so if a module was released at 2.1.0.0, 2.0.0.0,
1.2.0.0, 1.1.0.0, and 1.0.0.0, only 2.1.0.0, 2.0.0.0, and 1.2.0.0 would be
rebuilt and published.

## PARAMETERS

### -ForgeNameSpace
The namespace on the Forge to search for modules

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
The name of one or more Puppetized DSC modules to update.
If no name is
specified, will update all Puppetized DSC modules in the specified
Forge namespace.

```yaml
Type: String[]
Parameter Sets: ByNameAndVersion, ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The specific version to update; if specified, can only be used with a
single Name; rebuild one version of one module and publish it.

```yaml
Type: Version
Parameter Sets: ByNameAndVersion
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForgeApiUri
The Puppet Forge API URI to search and publish to; defaults to the public Puppet Forge

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForgeToken
The Forge API Token for the target account.
If not specified, will use
the FORGE_TOKEN environment variable.
Must pass a token either directly
or via the environment variable to successfully publish to the Forge.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BuildFolderPath
The path, relative or absolute, to the folder in which to Puppetize the
module.
If not specified, will do so in a folder called import in the
current location.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PackageFolderPath
The path, relative or absolute, to the folder in which to build the
module.
If not specified, will build in the pkg folder inside the
BuildFolderPath.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LatestMajorVersionOnly
If specified, will only rebuild releases from the latest major version
for each module being updated.

```yaml
Type: SwitchParameter
Parameter Sets: ByNameSpace, ByName
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumVersionCountToRebuild
If specified, will only rebuild and publish up to this many releases.

```yaml
Type: Int32
Parameter Sets: ByNameSpace, ByName
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SleepAfterFailure
If specified, will wait the specified number of seconds after a failure
and before starting the next update attempt.
Useful in local debugging
and execution.

```yaml
Type: Int32
Parameter Sets: ByNameSpace, ByName
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### None.
## NOTES

## RELATED LINKS
