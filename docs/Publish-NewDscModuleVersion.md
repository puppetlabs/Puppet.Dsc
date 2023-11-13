---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Publish-NewDscModuleVersion

## SYNOPSIS
Build and publish Puppetized DSC module versions not yet on the Forge

## SYNTAX

```
Publish-NewDscModuleVersion [-ForgeNameSpace] <String> [[-Name] <String[]>] [[-MinimumVersion] <String>]
 [-OnlyNewer] [[-MaxBuildCount] <Int32>] [[-Repository] <String>] [[-ForgeApiUri] <String>]
 [[-ForgeToken] <String>] [[-BuildFolderPath] <String>] [[-PackageFolderPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
Build and publish Puppetized DSC module versions not yet on the Forge by
searching for Puppetizable PowerShell modules with DSC Resources in a
repository and then building and published each desired version.

## EXAMPLES

### EXAMPLE 1
```
Publish-NewDscModuleVersion -ForgeNameSpace foo
```

This will search the PowerShell Gallery for any and all modules with DSC
Resources and their releases, comparing this information to the Puppet
Forge; any version of any discovered module *not* published to the 'foo'
namespace on the Forge will be puppetized and published; for any module
which is not already on the Forge in this namespace, all discovered
versions will be Puppetized and published.

### EXAMPLE 2
```
Publish-NewDscModuleVersion -ForgeNameSpace foo -Name 'bar', 'baz'
```

This will search the PowerShell Gallery for the bar and baz modules; any
version of these modules *not* published to the 'foo' namespace on the
Forge will be puppetized and published; if either module is not already
on the Forge in this namespace, all discovered versions for that module
will be Puppetized and published.

### EXAMPLE 3
```
Publish-NewDscModuleVersion -ForgeNameSpace foo -OnlyNewer
```

This will search the PowerShell Gallery for any and all modules with DSC
Resources and their releases, comparing this information to the Puppet
Forge; any version of any discovered module *not* published to the 'foo'
namespace on the Forge *and* whose version is higher than the highest
version published to the Forge will be puppetized and published; for
any module which is not already on the Forge in this namespace, all
discovered versions will be Puppetized and published.

### EXAMPLE 4
```
Publish-NewDscModuleVersion -ForgeNameSpace foo -MaxBuildCount 10
```

This will search the PowerShell Gallery for any and all modules with DSC
Resources and their releases, comparing this information to the Puppet
Forge; any version of any discovered module *not* published to the 'foo'
namespace on the Forge will be puppetized and published, up to 10 total
releases; if there are more unreleased versions than the MaxBuildCount
specification of 10, they will not be built in this call.

## PARAMETERS

### -ForgeNameSpace
The namespace on the Forge to search for modules in and publish to.

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
The name of one or more PowerShell modules to search for new versions to
puppetize.
If no name is specified, will compare all PowerShell modules
with DSC Resources in the specified Repository to the Forge to find
unpuppetized module versions.

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
The minimum version to puppetize; any released versions equal to or newer
than this which have been published to the PowerShell repository but not
the Puppet Forge will be puppetized and published.

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
Only puppetize versions of the PowerShell module on the PowerShell repository
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

### -MaxBuildCount
Only puppetize up to this many releases *total* across modules and versions.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 0
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
Position: 5
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
Position: 6
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
Position: 7
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
Position: 8
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
Position: 9
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
