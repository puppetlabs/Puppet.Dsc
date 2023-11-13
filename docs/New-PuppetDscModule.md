---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# New-PuppetDscModule

## SYNOPSIS
Puppetize a PowerShell module with DSC resources

## SYNTAX

```
New-PuppetDscModule [-PowerShellModuleName] <String> [[-PowerShellModuleVersion] <String>]
 [[-PuppetModuleName] <String>] [[-PuppetModuleAuthor] <String>] [[-PuppetModuleFixture] <Hashtable>]
 [[-OutputDirectory] <String>] [-AllowPrerelease] [-PassThru] [[-Repository] <String>]
 [[-PDKTemplateRef] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function builds a Puppet Module which wraps and calls PowerShell DSC resources
via the Puppet resource_api.
This module:

- Includes a base resource_api provider which relies on ruby-pwsh and knows how to invoke DSC resources
- Includes a type for each DSC resource, pulling in the appropriate metadata including help, default value
  and mandatory status, as well as whether or not it includes an embedded mof.
- Allows for the tracking of changes on a property-by-property basis while using DSC and Puppet together

## EXAMPLES

### EXAMPLE 1
```
New-PuppetDscModule -PowerShellModuleName PowerShellGet -PowerShellModuleVersion 2.2.3 -Repository PSGallery
```

This function will create a new Puppet module, powershellget, which vendors and puppetizes the PowerShellGet
PowerShell module at version 2.2.3 and its dependencies, exposing the DSC resources as Puppet resources.

## PARAMETERS

### -PowerShellModuleName
The name of the PowerShell module on the gallery which has DSC resources you want to Puppetize

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

### -PowerShellModuleVersion
The version of the PowerShell module on the gallery which has DSC resources you want to Puppetize.
If left blank, will default to latest available.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PuppetModuleName
The name of the Puppet module for the wrapper; if not specified, will default to the downcased name of
the module to adhere to Puppet naming conventions.

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

### -PuppetModuleAuthor
The name of the Puppet module author; if not specified, will default to your PDK configuration's author.

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

### -PuppetModuleFixture
The fixture reference for the puppetlabs-pwshlib dependency, defined as a hash with the mandatory keys
\`Section\` ('forge_modules' or 'repositories') and \`Repo\` (the name of the module on the forge, like
'puppetlabs/pwshlib', or the git repo url) and the optional keys \`Ref\` (the version on the forge or the
git ref - tag or commit sha) and \`Branch\` (source code repository only, identifying the branch to be
pulled from).

Defaults to retrieving the latest released version of pwshlib from the forge.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputDirectory
The folder in which to build the Puppet module.
Defaults to a folder called import in the current location.

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

### -AllowPrerelease
Allows you to Puppetize a module marked as a prerelease.

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

### -PassThru
If specified, the function returns the path to the root folder of the Puppetized module on the filesystem.

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
Specifies a non-default PSRepository.
If left blank, will default to PSGallery.

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

### -PDKTemplateRef
Specifies the template git branch or tag to use when creating new moudles or classes.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 3.0.0
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the function runs.

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
Prompts for confirmation before creating the Puppet module

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
