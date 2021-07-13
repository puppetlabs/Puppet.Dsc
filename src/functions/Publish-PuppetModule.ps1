function Publish-PuppetModule {
  <#
  .SYNOPSIS
    Build and Publish Puppet Module
  .DESCRIPTION
    Generate package for the module and publish to the forge.
  .PARAMETER PuppetModuleFolderPath
    The path, relative or absolute, to the Puppet module's root folder.
  .PARAMETER ExportFolderPath
    The path, relative or absolute, to the folder in which to build the
    module. If not specified, will build in the pkg folder inside the
    PuppetModuleFolderPath
  .PARAMETER PackagedModulePath
    The path, relative or absolute, to an already built Puppet module to
    publish to the forge.
  .PARAMETER ForgeUploadUrl
    The URL for the Forge Upload API. Defaults to the public forge.
  .PARAMETER ForgeToken
    The Forge API Token for the target account. If not specified, will use
    the FORGE_TOKEN environment variable. Must pass a token either directly
    or via the environment variable to successfully publish to the Forge.
  .PARAMETER Build
    Flag whether to build the package.
  .PARAMETER Publish
    Flag whether to publish the package.
  .PARAMETER Force
    Flag whether to skip all prompts when building/publishing the module.
  .EXAMPLE
    Publish-PuppetModule -Build -Publish -PuppetModuleFolderPath ./foo
    This will attempt to build and then publish the Puppet module in ./foo
    leveraging the forge token stored in the FORGE_TOKEN environment variable
  .EXAMPLE
    Publish-PuppetModule -Build -PuppetModuleFolderPath ./foo
    This will call Export-PuppetModule to build the module in ./foo
  .EXAMPLE
    Publish-PuppetModule -Publish -PuppetModuleFolderPath ./foo
    This will use the PDK to attempt to publish the version-matching packaged
    Puppet module in ./foo/pkg leveraging the forge token stored in the
    FORGE_TOKEN environment variable
  .EXAMPLE
    Publish-PuppetModule -Publish -PuppetModuleFolderPath ./foo -Publish -PackagedModulePath ../pkg/myuser-foo-1.2.3-0-0.tar.gz
    This will use the PDK to attempt to publish the specified packaged module,
    leveraging the forge token stored in the FORGE_TOKEN environment variable
  .EXAMPLE
    Publish-PuppetModule -Build -Publish -PuppetModuleFolderPath ./foo -ExportFolderPath C:\dsc
    This will attempt to build the Puppet module found in ./foo to the C:\dsc
    folder and then publish the built module from C:\dsc, leveraging the forge
    token stored in the FORGE_TOKEN environment variable
  .EXAMPLE
    Publish-PuppetModule -Build -Publish -PuppetModuleFolderPath ./foo -Force
    This will attempt to build and then publish the Puppet module in ./foo
    leveraging the forge token stored in the FORGE_TOKEN environment variable
    and ignoring all prompts and warnings, rebuilding the module if needed.
  .EXAMPLE
    Publish-PuppetModule -Publish -PuppetModuleFolderPath ./foo -ForgeToken FooBarBaz
    This will use the PDK to attempt to publish the version-matching packaged
    Puppet module in ./foo/pkg passing 'FooBarBaz' as the token for
    authenticating to the forge.
  #>
  [CmdletBinding(DefaultParameterSetName = 'Build')]
  param (
    [Parameter(Mandatory, ParameterSetName = 'Build')]
    [Parameter(Mandatory, ParameterSetName = 'Publish')]
    [string]$PuppetModuleFolderPath,
    [Parameter(ParameterSetName = 'Build')]
    [string]$ExportFolderPath,
    [Parameter(ParameterSetName = 'Publish')]
    [string]$PackagedModulePath,
    [Parameter(ParameterSetName = 'Build')]
    [Parameter(ParameterSetName = 'Publish')]
    [string]$ForgeToken = $env:FORGE_TOKEN,
    [Parameter(ParameterSetName = 'Build')]
    [Parameter(ParameterSetName = 'Publish')]
    [string]$ForgeUploadUrl,
    [Parameter(ParameterSetName = 'Build')]
    [switch]$Build,
    [Parameter(ParameterSetName = 'Build')]
    [Parameter(Mandatory, ParameterSetName = 'Publish')]
    [switch]$Publish,
    [Parameter(ParameterSetName = 'Build')]
    [Parameter(ParameterSetName = 'Publish')]
    [switch]$Force
  )

  begin {
    $PuppetModuleFolderPath = Resolve-Path -Path $PuppetModuleFolderPath -ErrorAction Stop |
      Select-Object -ExpandProperty Path
  }

  process {
    Try {
      $ErrorActionPreference = 'Stop'

      If ($Build) {
        $ExportParameters = @{
          PuppetModuleFolderPath = $PuppetModuleFolderPath
        }
        If (![string]::IsNullOrEmpty($ExportFolderPath)) { $ExportParameters.ExportFolderPath = $ExportFolderPath }
        If ($Force) { $ExportParameters.Force = $true }
        Export-PuppetModule @ExportParameters
      }

      If ($Publish) {
        If ([string]::IsNullOrEmpty($ForgeToken)) {
          Throw 'No Puppet Forge Token specified (or value was null or empty); you MUST specify a forge token to publish a module'
        }

        $PublishParameters = @{
          Path                = $PuppetModuleFolderPath
          Command             = "pdk release publish --forge-token $ForgeToken"
          SuccessFilterScript = { $_ -match 'Publish to Forge was successful' }
        }

        If ($Force) { $PublishParameters.Command += ' --force' }

        If (![string]::IsNullOrEmpty($ForgeUploadUrl)) {
          $PublishParameters.Command += " --forge-upload-url $ForgeUploadUrl"
        }

        If (![string]::IsNullOrEmpty($ExportFolderPath)) {
          # In this case, assume the latest-built module is the one published in this run
          # and specify the full path to that package file.
          $PackagedModulePath = Get-Item -Path (Join-Path -Path $ExportFolderPath -ChildPath '*.tar.gz') |
            Sort-Object -Descending -Property LastWriteTime |
            Select-Object -ExpandProperty FullName -First 1
        }

        If (![string]::IsNullOrEmpty($PackagedModulePath)) {
          $PackagedModulePath = Resolve-Path -Path $PackagedModulePath -ErrorAction Stop |
            Select-Object -ExpandProperty Path
          $PublishParameters.Command += " --file $PackagedModulePath"
        }

        Write-PSFMessage -Level Verbose "Invoking ``$($PublishParameters.Command -replace $ForgeToken, '<FORGE_TOKEN>')`` from $PuppetModuleFolderPath"
        Invoke-PdkCommand @PublishParameters
      }
    } Catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }

  end {}
}
