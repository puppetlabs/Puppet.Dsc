Import-Module -Name 'PowerShell-Yaml'
Import-Module -Name 'Puppet.Dsc'

Function Get-ModuleData {
    <#
    .SYNOPSIS
        Retrieves a list of modules that have versions available to Puppetize.
    .DESCRIPTION
        Retrieves a list of modules that have versions available to Puppetize.
        If a module has a version available on the PowerShell Gallery, that does not
        exist on the Puppet Forge, it will be included in the list.
    .PARAMETER Path
        The path to the configuration file that contains the list of modules to
        evaluate. The file is expected to be in YAML format and follow this schema:

        ---
        resources:
            - name: xCredSSP
            - name: SqlServerDsc
    .PARAMETER SkipPublishCheck
        If specified, the function will not check the given modules for unpuppetized
        versions on the PowerShell Gallery.

        This switch is useful when you are repuppetizing a module.

    .EXAMPLE
        Get-ModuleData -Path './dsc_resources.yaml'
    #>
    [CmdletBinding(DefaultParameterSetName = 'UnPuppetizedOnly')]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [System.IO.FileInfo]$Path,
        [Parameter(ParameterSetName = 'PuppetizedOnly')]
        [Switch]$PuppetizedOnly,
        [Parameter(ParameterSetName = 'UnPuppetizedOnly')]
        [Switch]$UnpuppetizedOnly,
        [Parameter(ParameterSetName = 'SkipPublishCheck')]
        [Switch]$SkipPublishCheck
    )

    $Modules = Get-Content -Path $Path -Raw | ConvertFrom-Yaml
    $ModulesForMatrix = [System.Collections.ArrayList]@()

    switch($PSCmdlet.ParameterSetName) {
        'PuppetizedOnly'{
            $Modules.resources | ForEach-Object {
                if (Get-ForgeModuleInfo -Name $_.name -ForgeNamespace 'dsc' -ErrorAction SilentlyContinue) {
                    Write-Verbose "Adding puppetized module $($_.name) to matrix"
                    $null = $ModulesForMatrix.Add($_.name)
                }
            }
            break
        }
        'UnPuppetizedOnly' {
            $Modules.resources | ForEach-Object {
                if (Get-UnPuppetizedDscModuleVersion -Name $_.name -ForgeNamespace 'dsc') {
                    Write-Verbose "Adding unpuppetized module $($_.name) to matrix."
                    $null = $ModulesForMatrix.Add($_.name)
                }
            }
            break
        }
        'SkipPublishCheck' {
            $Modules.resources | ForEach-Object {
                Write-Verbose "Skipping publish check and adding module $($_.name) to matrix."
                $null = $ModulesForMatrix.Add($_.name)
            }
            break
        }
    }

    Write-Output $ModulesForMatrix
}

Function ConvertTo-BuildMatrix {
    <#
    .SYNOPSIS
        Converts a list of modules to a build matrix string.
    .DESCRIPTION
        Converts a list of modules to a build matrix string.
    .PARAMETER Module
        One or more modules to convert to a build matrix string.
    .EXAMPLE
        ConvertTo-BuildMatrix -Module 'xCredSSP', 'SqlServerDsc'
    .EXAMPLE
        @( 'xCredSSP', 'SqlServerDsc' ) | ConvertTo-BuildMatrix
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [String]$Module
    )

    Begin {
        Write-Verbose -Message "Converting modules list to GitHub Actions compatible build matrix."
        $InternalModules = [System.Collections.ArrayList]@()
    }

    Process {
        $null = $InternalModules.Add($Module)
    }

    End {
        $BuildMatrix = "module=$(ConvertTo-Json $InternalModules -Compress )"
        Write-Output $BuildMatrix
    }
}


Function Set-BuildMatrix {
    <#
    .SYNOPSIS
        Appends the given build matrix to $GITHUB_OUTPUT.
    .DESCRIPTION
        Appends the given build matrix to $GITHUB_OUTPUT.
    .PARAMETER Matrix
        The build matrix to append to $GITHUB_OUTPUT.
    .EXAMPLE
        Set-BuildMatrix -Matrix 'module=["xCredSSP", "SqlServerDsc"]'
    .EXAMPLE
        'module=["xCredSSP", "SqlServerDsc"]' | Set-BuildMatrix
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [String]$Matrix
    )

    if (!(Test-Path -Path Env:\GITHUB_OUTPUT)) {
        Write-Verbose -Message "GITHUB_OUTPUT does not exist in the current environment."
        return
    }

    Write-Verbose -Message "Setting build matrix to $Matrix."
    if ($PSCmdlet.ShouldProcess("GITHUB_OUTPUT", 'Set build matrix')) {
        Set-Content -Path $Env:GITHUB_OUTPUT -Value $Matrix
    }
}
