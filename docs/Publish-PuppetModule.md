---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Publish-PuppetModule

## SYNOPSIS
Build and Publish Puppet Module

## SYNTAX

### Build (Default)
```
Publish-PuppetModule -PuppetModuleFolderPath <String> [-ExportFolderPath <String>] [-ForgeToken <String>]
 [-ForgeUploadUrl <String>] [-Build] [-Publish] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Publish
```
Publish-PuppetModule -PuppetModuleFolderPath <String> [-PackagedModulePath <String>] [-ForgeToken <String>]
 [-ForgeUploadUrl <String>] [-Publish] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generate package for the module and publish to the forge.

## EXAMPLES

### EXAMPLE 1
```
Publish-PuppetModule -Build -Publish -PuppetModuleFolderPath ./foo
```

This will attempt to build and then publish the Puppet module in ./foo
leveraging the forge token stored in the FORGE_TOKEN environment variable

### EXAMPLE 2
```
Publish-PuppetModule -Build -PuppetModuleFolderPath ./foo
```

This will call Export-PuppetModule to build the module in ./foo

### EXAMPLE 3
```
Publish-PuppetModule -Publish -PuppetModuleFolderPath ./foo
```

This will use the PDK to attempt to publish the version-matching packaged
Puppet module in ./foo/pkg leveraging the forge token stored in the
FORGE_TOKEN environment variable

### EXAMPLE 4
```
Publish-PuppetModule -Publish -PuppetModuleFolderPath ./foo -Publish -PackagedModulePath ../pkg/myuser-foo-1.2.3-0-0.tar.gz
```

This will use the PDK to attempt to publish the specified packaged module,
leveraging the forge token stored in the FORGE_TOKEN environment variable

### EXAMPLE 5
```
Publish-PuppetModule -Build -Publish -PuppetModuleFolderPath ./foo -ExportFolderPath C:\dsc
```

This will attempt to build the Puppet module found in ./foo to the C:\dsc
folder and then publish the built module from C:\dsc, leveraging the forge
token stored in the FORGE_TOKEN environment variable

### EXAMPLE 6
```
Publish-PuppetModule -Build -Publish -PuppetModuleFolderPath ./foo -Force
```

This will attempt to build and then publish the Puppet module in ./foo
leveraging the forge token stored in the FORGE_TOKEN environment variable
and ignoring all prompts and warnings, rebuilding the module if needed.

### EXAMPLE 7
```
Publish-PuppetModule -Publish -PuppetModuleFolderPath ./foo -ForgeToken FooBarBaz
```

This will use the PDK to attempt to publish the version-matching packaged
Puppet module in ./foo/pkg passing 'FooBarBaz' as the token for
authenticating to the forge.

## PARAMETERS

### -PuppetModuleFolderPath
The path, relative or absolute, to the Puppet module's root folder.

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

### -ExportFolderPath
The path, relative or absolute, to the folder in which to build the
module.
If not specified, will build in the pkg folder inside the
PuppetModuleFolderPath

```yaml
Type: String
Parameter Sets: Build
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PackagedModulePath
The path, relative or absolute, to an already built Puppet module to
publish to the forge.

```yaml
Type: String
Parameter Sets: Publish
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
Default value: $env:FORGE_TOKEN
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForgeUploadUrl
The URL for the Forge Upload API.
Defaults to the public forge.

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

### -Build
Flag whether to build the package.

```yaml
Type: SwitchParameter
Parameter Sets: Build
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Publish
Flag whether to publish the package.

```yaml
Type: SwitchParameter
Parameter Sets: Build
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: Publish
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Flag whether to skip all prompts when building/publishing the module.

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

## OUTPUTS

## NOTES

## RELATED LINKS
