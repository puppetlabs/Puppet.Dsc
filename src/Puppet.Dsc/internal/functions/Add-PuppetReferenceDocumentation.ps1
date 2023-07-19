function Add-PuppetReferenceDocumentation {
  <#
      .SYNOPSIS
        Generate REFERENCE.md
      .DESCRIPTION
        Generate REFERENCE.md file for the Puppet module from the auto-generated types for each DSC
        resource. This will *always* have the syntax but **may not** have the property documentation,
        depending on whether or not those reference docs were discoverable for each DSC resource.
      .PARAMETER PuppetModuleFolderPath
        The path, relative or literal, to the Puppet module's root folder.
      .EXAMPLE
        Add-PuppetReferenceDocumentation -PuppetModuleFolderPath C:\output\testmodule
        This command will generate `REFERENCE.md` file for the `testmodule` Puppet module.
    #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    $PuppetModuleFolderPath
  )

  begin {
    $PuppetModuleFolderPath = Resolve-Path -Path $PuppetModuleFolderPath -ErrorAction Stop
    $Command = 'pdk bundle exec puppet strings generate --format markdown --out REFERENCE.md'
  }
  process {
    Try {
      $ErrorActionPreference = 'Stop'
      Invoke-PdkCommand -Path $PuppetModuleFolderPath -Command 'pdk bundle exec ruby -v'
      Invoke-PdkCommand -Path $PuppetModuleFolderPath -Command $Command -SuccessFilterScript {
        $_ -match '% documented'
      }
      # Verify REFERENCE.md file is generated
      $ReferenceFile = Join-Path -Path $PuppetModuleFolderPath -ChildPath REFERENCE.md
      $null = Resolve-Path $ReferenceFile
    } Catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
  end {}
}
