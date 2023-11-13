---
external help file: Puppet.Dsc-help.xml
Module Name: puppet.dsc
online version:
schema: 2.0.0
---

# Export-PuppetModule

## SYNOPSIS
Build a Puppet module with the PDK

## SYNTAX

```
Export-PuppetModule [-PuppetModuleFolderPath] <String> [[-ExportFolderPath] <String>] [-Force] [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
Build a Puppet module with the PDK as a .tar.gz

## EXAMPLES

### EXAMPLE 1
```
Export-PuppetModule -PuppetModuleFolderPath ./import/powershellget
```

This command will invoke the PDK to build the powershellget module in the
specified folder path.

## PARAMETERS

### -PuppetModuleFolderPath
The path to the folder where the Puppet module to build exists

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

### -ExportFolderPath
The path to the folder for the built module to be placed in.
If not specified,
builds in the pkg folder inside the PuppetModuleFolderPath.
If the specified
ExportFolderPath does not exist, the PDK will create it.

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

### -Force
Specify this switch to force a build of the module even if it already exists

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
Specify this switch to capture the output of the PDK build command and return it

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### [Object[]] If the PassThru switch is specified, returns the output from the
### PDK execution, including any error records.
## NOTES

## RELATED LINKS
