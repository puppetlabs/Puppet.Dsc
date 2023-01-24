@{
  # Script module or binary module file associated with this manifest
  RootModule        = 'Puppet.Dsc.psm1'

  # Version number of this module.
  ModuleVersion     = '1.0.5'

  # ID used to uniquely identify this module
  GUID              = '37c6b5c1-2614-4ff5-bb9f-a610b7da3086'

  # Author of this module
  Author            = 'Puppet'

  # Company or vendor of this module
  CompanyName       = 'Puppet'

  # Copyright statement for this module
  Copyright         = 'Copyright (c) 2020 Puppet'

  # Description of the functionality provided by this module
  Description       = 'Convert DSC resources into Puppet Resource API types and providers'

  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '5.1'

  # Modules that must be imported into the global environment prior to importing
  # this module
  RequiredModules   = @(
    @{ ModuleName = 'PSFramework'; ModuleVersion = '1.1.59' }
    'PSDesiredStateConfiguration'
    'PSDscResources'
    'powershell-yaml'
    @{ ModuleName = 'PowerShellGet'; ModuleVersion = '2.2.3' }
  )

  # Assemblies that must be loaded prior to importing this module
  # RequiredAssemblies = @('bin\puppet.dsc.dll')

  # Type files (.ps1xml) to be loaded when importing this module
  # TypesToProcess = @('xml/puppet.dsc.Types.ps1xml')

  # Format files (.ps1xml) to be loaded when importing this module
  # FormatsToProcess = @('xml\puppet.dsc.Format.ps1xml')

  # Functions to export from this module
  FunctionsToExport = @(
    'ConvertTo-PuppetResourceApi'
    'Export-PuppetModule'
    'Get-ForgeModuleInfo'
    'Get-PowerShellDscModule'
    'Get-PuppetizedModuleName'
    'Get-UnpuppetizedDscModuleVersion'
    'New-PuppetDscModule'
    'Publish-PuppetModule'
    'Publish-NewDscModuleVersion'
    'Update-ForgeDscModule'
  )

  # Cmdlets to export from this module
  CmdletsToExport   = ''

  # Variables to export from this module
  VariablesToExport = ''

  # Aliases to export from this module
  AliasesToExport   = ''

  # List of all modules packaged with this module
  ModuleList        = @()

  # List of all files packaged with this module
  FileList          = @()

  # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
  PrivateData       = @{

    #Support for PowerShellGet galleries.
    PSData = @{

      # PSDesiredStateConfiguration is not installable from the gallery but **is** required.
      # Since it is available on every machine that has Windows PowerShell 5.1, this is fine.
      ExternalModuleDependencies = @(
        'PSDesiredStateConfiguration'
      )

      # Tags applied to this module. These help with module discovery in online galleries.
      Tags                       = @(
        'Puppet'
        'DSC'
        'PSEdition_Desktop'
        'Windows'
      )

      # A URL to the license for this module.
      LicenseUri                 = 'https://github.com/puppetlabs/Puppet.Dsc/blob/main/LICENSE'

      # A URL to the main website for this project.
      ProjectUri                 = 'https://github.com/puppetlabs/Puppet.Dsc'

      # A URL to an icon representing this module.
      # IconUri = ''

      # ReleaseNotes of this module
      # ReleaseNotes = ''

    } # End of PSData hashtable

  } # End of PrivateData hashtable
}
