---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Get-PowerShellDscModule

## SYNOPSIS
Retrieve one or more PowerShell modules with DSC Resources

## SYNTAX

```
Get-PowerShellDscModule [[-Name] <String[]>] [[-Repository] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieve one or more PowerShell modules with DSC Resources from a PowerShell repository,
returning their name and all released versions.

## EXAMPLES

### EXAMPLE 1
```
Get-PowerShellDscModule
```

Searches the PowerShell Gallery for every module with DSC Resources and returns every
released version of those modules.

## PARAMETERS

### -Name
The name of one or more modules to search for.
If not specified, returns all modules
with DSC Resources.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
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
Position: 2
Default value: PSGallery
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### [PSCustomObject[]] An object with the name of each discovered module and a Releases
### property for every version released to the repository.
## NOTES

## RELATED LINKS
