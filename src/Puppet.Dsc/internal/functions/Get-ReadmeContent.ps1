function Get-ReadmeContent {
  <#
  .SYNOPSIS
    Return the text for a Puppet Resource API Type given a DSC Resouce.
  .DESCRIPTION
    Return the text for a Puppet Resource API Type given a DSC Resouce.
    It will return the text but _not_ directly write out the file.
  .PARAMETER PuppetModuleName
    The name of the puppet module
  .PARAMETER PowerShellModuleName
    The name of the PowerShell module being puppetized
  .PARAMETER PowerShellModuleVersion
    The version of the PowerShell module being puppetized
  .PARAMETER PowerShellModuleGalleryUri
    The full url to the PowerShell module on a nuget gallery
  .PARAMETER PowerShellModuleProjectUri
    The full url to the PowerShell module's project page/repository

  .EXAMPLE
    $Parameters = @{
      PowerShellModuleName       = 'Foo.Bar'
      PowerShellModuleGalleryUri = "https://www.powershellgallery.com/packages/Foo.Bar/1.0.0"
      PowerShellModuleProjectUri = 'https://github.com/foo/Foo.Bar'
      PowerShellModuleVersion    = '1.0.0'
      PuppetModuleName           = 'foo_bar'
    }
    Get-ReadmeContent @Parameters

    This command return a markdown readme for the puppetized foo_bar module.
  #>
  [cmdletbinding()]
  param (
    [OutputType([String])]
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PowerShellModuleName,
    [ValidateNotNullOrEmpty()][string]$PowerShellModuleDescription,
    [ValidateNotNullOrEmpty()][string]$PowerShellModuleGalleryUri,
    [string]$PowerShellModuleProjectUri,
    [ValidateNotNullOrEmpty()][string]$PowerShellModuleVersion,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PuppetModuleName
  )

  Begin {
    $BuilderModuleGalleryUri = 'https://www.powershellgallery.com/packages/puppet.dsc'
    $BuilderModuleRepository = 'https://github.com/puppetlabs/Puppet.Dsc'
    $BaseProviderSource = 'https://github.com/puppetlabs/ruby-pwsh/blob/main/lib/puppet/provider/dsc_base_provider/dsc_base_provider.rb'
    $ResourceApiOverview = 'https://puppet.com/docs/puppet/latest/create_types_and_providers_resource_api.html'
    $ResourceApiDocumentation = 'https://puppet.com/docs/puppet/latest/about_the_resource_api.html'
    $dscForgePage = 'https://forge.puppet.com/dsc'
    $LegacyDscForgePage = 'https://forge.puppet.com/modules/puppetlabs/dsc'
    $pwshlibForgePage = 'https://forge.puppet.com/puppetlabs/pwshlib'
    $pwshlibIssuesPage = 'https://github.com/puppetlabs/ruby-pwsh/issues/new/choose'
    $PowerShellGetUri = 'https://github.com/PowerShell/PowerShellGet'
    $NarrativeDocumentation = 'https://puppetlabs.github.io/iac/news/roadmap/2020/03/30/dsc-announcement.html'
    $TroubleshootingDocumentation = 'https://github.com/puppetlabs/Puppet.Dsc#troubleshooting'
    $MicrosoftLongPathSupportDocs = 'https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=powershell#enable-long-paths-in-windows-10-version-1607-and-later'
    $PuppetModuleInstallIssue = 'https://tickets.puppetlabs.com/browse/PUP-10924'
    $r10kInstallationIssue = 'https://github.com/puppetlabs/r10k/issues/1117'
    If ([string]::IsNullOrEmpty($PowerShellModuleProjectUri)) {
      # Instead link to the gallery page since the metadata is incomplete
      $PowerShellModuleProjectUri = $PowerShellModuleGalleryUri
    }
  }

  Process {
    # No additional formatting should be needed
    New-Object -TypeName System.String @"
# $PuppetModuleName

## Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Usage](#usage)
1. [Troubleshooting](#troubleshooting)

## Description

This is an auto-generated module, using the [Puppet DSC Builder]($BuilderModuleGalleryUri) to vendor and expose the [$PowerShellModuleName]($PowerShellModuleGalleryUri) PowerShell module's DSC resources as Puppet resources.
The _functionality_ of this module comes entirely from the vendored PowerShell resources, which are pinned at [**v$PowerShellModuleVersion**]($PowerShellModuleGalleryUri).
The PowerShell module describes itself like this:

> _${PowerShellModuleDescription}_

For information on troubleshooting to determine whether any encountered problems are with the Puppet wrapper or the DSC resource, see the [troubleshooting](#troubleshooting) section below.

## Requirements

This module, like all [auto-generated Puppetized DSC modules]($dscForgePage), relies on two important technologies in the Puppet stack: the [Puppet Resource API]($ResourceApiOverview) and the [`puppetlabs/pwshlib`]($pwshlibForgePage) Puppet module.

The Resource API provides a simplified option for writing types and providers and is responsible for how this module is structured.
The Resource API ships inside of Puppet starting with version 6.
While it is _technically_ possible to add the Resource API functionality to Puppet 5.5.x, the DSC functionality has **not** been tested in this setup.
For more information on the Resource API, review the [documentation]($ResourceApiDocumentation).

The module also depends on the `pwshlib` module.
This Puppet module includes two important things: the ruby-pwsh library for running PowerShell code from ruby and the base provider for DSC resources, which this module leverages.

All of the actual work being done to call the DSC resources vendored with this module is in [this file]($BaseProviderSource) from the `pwshlib` module.
This is important for troubleshooting and bug reporting, but doesn't impact your use of the module except that the end result will be that nothing works, as the dependency is not installed alongside this module!

### Long File Path Support

Several PowerShell modules with DSC Resources end up with _very_ long file paths once vendored, many of which exceed the 260 character limit for file paths.
Luckily in Windows 10 (build 1607+), Windows Server 2016 (build 1607+), and Windows Server 2019 there is now an option for supporting long file paths transparently!

We **strongly recommend** enabling long file path support on any machines using this module to avoid path length issues.

You can set this value using the Puppet ``registry_value`` resource:

``````puppet
registry_value { 'HKLM\System\CurrentControlSet\Control\FileSystem\LongPathsEnabled':
  ensure   => 'present',
  data     => [1],
  provider => 'registry',
  type     => 'dword',
}
``````

You can also set this value outside of Puppet by [following the Microsoft documentation]($MicrosoftLongPathSupportDocs).

## Usage

You can specify any of the DSC resources from this module like a normal Puppet resource in your manifests.
The examples below use DSC resources from from the [`PowerShellGet`]($PowerShellGetUri) repository, regardless of what module you're looking at here;
the syntax, not the specifics, is what's important.

For reference documentation about the DSC resources exposed in this module, see the *Reference* Forge tab, or the `REFERENCE.md` file.

``````puppet
# Include a meaningful title for your resource declaration
dsc_psrepository { 'Add team module repo':
    dsc_name               => 'foo',
    dsc_ensure             => present,
    # This location is nonsense, can be any valid folder on your
    # machine or in a share, any location the SourceLocation param
    # for the DSC resource will accept.
    dsc_sourcelocation     => 'C:\Program Files',
    # You must always pass an enum fully lower-cased;
    # Puppet is case sensitive even when PowerShell isn't
    dsc_installationpolicy => untrusted,
}

dsc_psrepository { 'Trust public gallery':
    dsc_name               => 'PSGallery',
    dsc_ensure             => present,
    dsc_installationpolicy => trusted,
}

dsc_psmodule { 'Make Ruby manageable via uru':
  dsc_name   => 'RubyInstaller',
  dsc_ensure => present,
}
``````

### Credentials

Credentials are always specified as a hash of the username and password for the account.
The password **must** use the Puppet [Sensitive type](https://puppet.com/docs/puppet/latest/lang_data_sensitive.html);
this ensures that logs and reports redact the password, displaying it instead as `<Sensitive [value redacted]>`.

``````puppet
dsc_psrepository { 'PowerShell Gallery':
  dsc_name                 => 'psgAllery',
  dsc_installationpolicy   => 'Trusted',
  dsc_psdscrunascredential => {
    user     => 'apple',
    password => Sensitive('foobar'),
  },
}
``````

### Class-Based Resources

Class-based DSC Resources can be used like any other DSC Resource in this module, with one important note:
Due to a bug in calling class-based DSC Resources by path instead of module name, each call to ``Invoke-DscResource`` needs to temporarily munge the system-level environment variable for ``PSModulePath``;
the variable is reset prior to the end of each invocation.

### CIM Instances

Because the CIM instances for DSC resources are fully mapped, the types actually explain fairly precisely what the shape of each CIM instance has to be - and, moreover, the type definition means that you get checking at catalog compile time.
Puppet parses CIM instances are structured hashes (or arrays of structured hashes) that explicitly declare their keys and the valid types of values for each key.

So, for the ``dsc_accesscontrolentry`` property of the ``dsc_ntfsaccessentry`` type, which has a MOF type of ``NTFSAccessControlList[]``, Puppet defines the CIM instance as:

``````ruby
Array[Struct[{
  accesscontrolentry => Array[Struct[{
    accesscontroltype => Enum['Allow', 'Deny'],
    inheritance => Enum['This folder only', 'This folder subfolders and files', 'This folder and subfolders', 'This folder and files', 'Subfolders and files only', 'Subfolders only', 'Files only'],
    ensure => Enum['Present', 'Absent'],
    cim_instance_type => 'NTFSAccessControlEntry',
    filesystemrights => Array[Enum['AppendData', 'ChangePermissions', 'CreateDirectories', 'CreateFiles', 'Delete', 'DeleteSubdirectoriesAndFiles', 'ExecuteFile', 'FullControl', 'ListDirectory', 'Modify', 'Read', 'ReadAndExecute', 'ReadAttributes', 'ReadData', 'ReadExtendedAttributes', 'ReadPermissions', 'Synchronize', 'TakeOwnership', 'Traverse', 'Write', 'WriteAttributes', 'WriteData', 'WriteExtendedAttributes']]
  }]],
  forceprincipal => Optional[Boolean],
  principal => Optional[String],
}]]
``````

A valid example of that in a puppet manifest looks like this:

``````puppet
dsc_accesscontrollist => [
  {
    accesscontrolentry => [
      {
        accesscontroltype => 'Allow',
        inheritance       => 'This folder only',
        ensure            => 'Present',
        filesystemrights  => 'ChangePermissions',
        cim_instance_type => 'NTFSAccessControlEntry',
      },
    ],
    principal          => 'veryRealUserName',
  },
]
``````

For more information about using a built module, check out our [narrative documentation]($NarrativeDocumentation).

### Properties

Note that the only properties specified in a resource declaration which are passed to `Invoke-Dsc` are all prepended with `dsc_`.
If a property does _not_ start with `dsc_` it is used to control how Puppet interacts with DSC/other Puppet resources - for example,
specifying a unique name for the resource for Puppet to distinguish between declarations or Puppet metaparameters (``notifies`, ``before`, etc).

### Validation Mode

By default, these resources use the property validation mode, which checks whether or not the resource is in the desired state the same way most Puppet resources are validated;
by comparing the properties returned from the system with those specified in the manifest.
Sometimes, however, this is insufficient;
many DSC Resources return data that does not compare properly to the desired state (some are missing properties, others are malformed, some simply cannot be strictly compared).
In these cases, you can set the validation mode to ``resource``, which falls back on calling ``Invoke-DscResource`` with the ``Test`` method and trusts that result.

When using the ``resource`` validation mode, the resource is tested once and will then treat **all** properties of that resource as in sync (if the result returned ``true``) or not in sync.
This loses the granularity of change reporting for the resource but prevents flapping and unexpected behavior.

``````puppet
# This will flap because the DSC resource never returns name in SecurityPolicyDsc v2.10.0.0
dsc_securityoption { 'Enforce Anonoymous SID Translation':
  dsc_name => 'Enforce Anonymous SID Translation',
  dsc_network_access_allow_anonymous_sid_name_translation => 'Disabled',
}

# This will idempotently apply
dsc_psrepository { 'PowerShell Gallery':
  validation_mode => 'resource',
  dsc_name        => 'Enforce Anonymous SID Translation',
  dsc_network_access_allow_anonymous_sid_name_translation => 'Disabled',
}
``````

It is important to note that this feature is only supported with a version of ``puppetlabs-pwshlib`` equal to or higher than ``0.9.0``, in which the supporting code for the DSC Base Provider to implement custom insync was shipped.

Finally, while this module's metadata says that the supported Puppet versions are 6.0.0 and up, the implementation of the ``validation_mode`` parameter relies on the ``custom_insync`` feature of the Puppet Resource API.
The ``custom_insync`` feature first shipped in the ``puppet-resource_api`` version ``1.8.14``, which itself is only included in Puppet versions equal to or newer than ``6.23.0`` and ``7.8.0`` for the 6x and 7x platforms respectively.
Using this module against older Puppet versions will result in a warning (example below) and _only_ use the default property-by-property change reporting, regardless of the setting of ``validation_mode``.

``````
Warning: Unknown feature detected: ["custom_insync"]
``````

## Troubleshooting

In general, there are three broad categories of problems:

1. Problems with the way the underlying DSC resource works.
1. Problems with the type definition, where you can't specify a valid set of properties for the DSC resource
1. Problems with calling the underlying DSC resource - the parameters aren't being passed correctly or the resource can't be found

Unfortunately, problems with the way the underlying DSC resource works are something we can't help _directly_ with.
You'll need to [file an issue]($PowerShellModuleProjectUri) with the upstream maintainers for the [PowerShell module]($PowerShellModuleGalleryUri).

Problems with the type definition are when a value that should be valid according to the DSC resource's documentation and code is not accepted by the Puppet wrapper. If and when you run across one of these, please [file an issue]($BuilderModuleRepository/issues/new/choose) with the Puppet DSC Builder; this is where the conversion happens and once we know of a problem we can fix it and regenerate the Puppet modules. To help us identify the issue, please specify the DSC module, version, resource, property and values that are giving you issues. Once a fix is available we will regenerate and release updated versions of this Puppet wrapper.

Problems with calling the underlying DSC resource become apparent by comparing ``<value passed in in puppet>`` with ``<value received by DSC>``.
In this case, please [file an issue]($pwshlibIssuesPage) with the [`puppetlabs/pwshlib`]($pwshlibForgePage) module, which is where the DSC base provider actually lives.
We'll investigate and prioritize a fix and update the `puppetlabs/pwshlib` module.
Updating to the pwshlib version with the fix will immediately take advantage of the improved functionality without waiting for this module to be reconverted and published.

For specific information on troubleshooting a generated module, check the [troubleshooting guide]($TroubleshootingDocumentation) for the `puppet.dsc` module.

## Known Limitations

Currently, because of the way Puppet caches files on agents, use of the legacy [``puppetlabs-dsc``]($LegacyDscForgePage) module is **not** compatible with this or any auto-generated DSC module.
Inclusion of both will lead to pluginsync conflicts.

Right now, if you have the same version of a PowerShell module with class-based DSC Resources in your PSModulePath as vendored in a Puppetized DSC Module,
you cannot use those class-based DSC Resources from inside of Puppet due to a bug in DSC which prevents using a module by path reference instead of name.
Instead, DSC will see that there are two DSC Resources for the same module and version and then error out.

### Configuring the LCM

In order for a Puppetized DSC module to function, the DSC Local Configuration Manager (LCM) ``RefreshMode`` must be set to either ``Push`` or ``Disabled``.
The default value for ``RefreshMode`` in WMF 5.0 and WMF 5.1 is ``Push`` - so if it has not been set to anything else then there is no action needed on your part.
However if the value of the LCM has been set to anything other than ``Push`` then the module will not function and so the value must either be changed back or disabled.

The Puppetized DSC modules use the ``Invoke-DscResource`` cmdlet to invoke DSC Resources of the target machine.
If the ``RefreshMode`` is set to ``Pull``, DSC Resources will only run from a DSC Pull Server - in this setting DSC does not allow any DSC Resources to be run interactively on the host.

### Module Installation

If you're using this module with Puppet Enterprise and Code Manager, everything should "just work" - no errors or issues acquiring and deploying this or any Puppetized DSC module to nodes.

Unfortunately, due a bug in minitar which prevents it from unpacking archives with long file paths, both [``r10k``]($r10kInstallationIssue) and [serverless Puppet (via ``puppet module install``)]($PuppetModuleInstallIssue) methods of installing modules with long path names will fail.
In short, minitar is unable to unpack modules that contain long file paths (though it can create them).

As a workaround, you can retrieve DSC modules from the forge via PowerShell and 7zip:

``````powershell
`$ModuleAuthor = 'dsc'
`$ModuleName = 'xremotedesktopsessionhost'
`$ModuleVersion = '2.0.0-0-1'
`$ArchiveFileName = "`$ModuleAuthor-`$ModuleName-`$ModuleVersion.tar.gz"
`$DownloadUri = "https://forge.puppet.com/v3/files/`$ArchiveFileName"
# Download the module tar.gz to the current directory
Invoke-WebRequest -Uri `$DownloadUri -OutFile ./`$ArchiveFileName
# Use 7zip to extract the module to the current directory
& 7z x `$ArchiveFileName -so | & 7z x -aoa -si -ttar
``````
"@
  }

  End {}
}
