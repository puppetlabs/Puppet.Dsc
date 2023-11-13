---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Get-PuppetizedModuleName

## SYNOPSIS
Get a valid puppet module name from a PowerShell Module name

## SYNTAX

```
Get-PuppetizedModuleName [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get a valid puppet module name from a PowerShell Module name

## EXAMPLES

### EXAMPLE 1
```
Get-PuppetizedModuleName -Name Azure.Something.Or.Other
```

This will return 'azure_something_or_other', which is a valid
Puppet module name.

## PARAMETERS

### -Name
The name of the PowerShell module you want to puppetize

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String
## NOTES

## RELATED LINKS
