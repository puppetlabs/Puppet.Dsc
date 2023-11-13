---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# ConvertTo-PuppetResourceApi

## SYNOPSIS
Collate the information about a DSC resource for building a Puppet resource_api type and provider

## SYNTAX

### ByObject (Default)
```
ConvertTo-PuppetResourceApi [-DscResource <DscResourceInfo[]>] [<CommonParameters>]
```

### ByProperty
```
ConvertTo-PuppetResourceApi [-Name <String[]>] [-Module <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function takes a DSC resource and returns the representation of that resource for the Puppet
Resource API types and providers as a PowerShell object for further use.

## EXAMPLES

### EXAMPLE 1
```
Get-DscResource -Name PSRepository | ConvertTo-PuppetResourceApi -OutVariable Foo
```

Retrieve the representation of a Puppet Resource API type and provider from a DSC Resource object.

### EXAMPLE 2
```
ConvertTo-PuppetResourceApi -Name PSRepository
```

Retrieve the representation of a Puppet Resource API type by searching for a DSC resource object via
Get-DscResource.
Will ONLY find the resource if it is in the PSModulePath.

## PARAMETERS

### -DscResource
The DscResourceInfo object to convert; can be passed via the pipeline, normally retrieved
via calling Get-DscResource.

```yaml
Type: DscResourceInfo[]
Parameter Sets: ByObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
If not passing a full object, specify the name of the DSC Resource to retrieve and convert.

```yaml
Type: String[]
Parameter Sets: ByProperty
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Module
If not passing a full object, specify the module name of the the DSC Resource to retrieve and convert.
Can be either a string or a hash containing the keys ModuleName and ModuleVersion.

```yaml
Type: Object
Parameter Sets: ByProperty
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
This function currently takes EITHER:

1.
A DscResource Object, as passed by Get-DSCResource
2.
A combo of name/module to retrieve DSC Resources from

## RELATED LINKS
