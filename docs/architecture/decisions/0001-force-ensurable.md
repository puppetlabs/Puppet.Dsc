# 1. Force Ensurable = false on Non-ensurable resources

Date: 2023-11-07

## Status

Accepted

## Context

In CAT-1484, it was found that there was a mismatch in behaviour between dsc resource keys and puppet namevars. It was widely assumed that these two attribute types eseentially behaved the same, which was found not to be the case with the dsc_virtualmemory resource (and others) in the ComputerManagementDsc module.
Puppet uses namevars as identifiers, so when a manifest is passed containing only namevar attributes, puppet will ignore the updating values in a manifest and not attempt to update the resource, For example, the Puppet File resource has a single namevar equal to the path of the resource, say "/tmp/foo1.txt".  If this namevar is changed to something like "/tmp/foo2.txt", then the original resource identified by the namevar will not be updated or changed; a new File resource will instead be created.  In similar fashion, DSC uniquely identifies its resources with namevars and will update the dsc resource only when key attributes are passed.

So although they appear the same on the surface, it was found that the below manifest and .mof file **would not** produce the same outcome on the target machine.

```puppet
dsc_virtualmemory { 'CDrive':
    dsc_drive => 'C', # namevar
    dsc_type  => 'AutoManagePagingFile', #namevar
}
```

```powershell
Configuration VirtualMemory_SetVirtualMemory_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        VirtualMemory PagingSettings
        {
            Type        = 'AutoManagePagingFile' #Key
            Drive       = 'C' #Key
        }
    }
}
```

Although the content of both files are essentially equal, the DSC resource will apply the specified changes, puppet will not.

## Decision

We have decided to force an ensurable property on every DSC resource type that has no ensure parameter already present. This has a couple of benefits:

1. Now documentation will clearly show that ensurable can only be set to false on certain types i.e. that they are not ensurabled by puppet.
2. The default value of false ensures that this is always passed along side namevar only manifests, preventing puppet from DSC key attribute updates like above.

## Consequences

Each initial puppet run after this change is applied will show as creating/updating of a resource. This will only occur on the first run and not any subsequent, true to the nature of Puppet.
