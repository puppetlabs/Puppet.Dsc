function Invoke-BundleInstall {
  <#
      .SYNOPSIS
        Install required gems
      .DESCRIPTION
        Installs required gems as specified in the Gemfile.
      .PARAMETER PuppetModuleFolderPath
        The path, relative or literal, to the Puppet module's root folder.
    #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    $PuppetModuleFolderPath
  )
    # verify required gems installed
    begin {
    $PuppetModuleFolderPath = Resolve-Path -Path $PuppetModuleFolderPath -ErrorAction Stop
    $Command = 'pdk bundle install'
  }
  process {
    Try {
      $ErrorActionPreference = 'Stop'
      Invoke-PdkCommand -Path $PuppetModuleFolderPath -Command $Command -SuccessFilterScript {
<<<<<<< HEAD
        $_ -match 'Bundle complete!'
=======
        $_ -match "Bundle complete!"
>>>>>>> 3f13b62 ((CAT-1322) - Update Function Success Criteria)
      }
    } Catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
  end {}
}
