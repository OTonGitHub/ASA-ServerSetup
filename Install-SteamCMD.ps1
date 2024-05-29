#Requires -RunAsAdministrator

Write-Host "Starting SteamCMD Installation..."

function Add-EnvPath {
    <#
    .LINK
    https://gist.github.com/mkropat/c1226e0cc2ca941b23a9
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [ValidateSet('Machine', 'User', 'Session')]
        [string]$Container = 'Session'
    )

    process {
        $VerbosePreference = 'Continue'

        Write-Verbose -Message "Container is set to: $Container"
        $Path = $Path.Trim()

        $containerMapping = @{
            Machine = [EnvironmentVariableTarget]::Machine
            User    = [EnvironmentVariableTarget]::User
            Session = [EnvironmentVariableTarget]::Process
        }

        $containerType = $containerMapping[$Container]
        $persistedPaths = [Environment]::GetEnvironmentVariable('Path', $containerType).
            Split([System.IO.Path]::PathSeparator).Trim() -ne ''

        if ($persistedPaths -notcontains $Path) {
            # previous step with `Trim()` + `-ne ''` already takes care of empty tokens,
            # no need to filter again here
            $persistedPaths = ($persistedPaths + $Path) -join [System.IO.Path]::PathSeparator
            [Environment]::SetEnvironmentVariable('Path', $persistedPaths, $containerType)
            $env:Path += ';$Path'

            Write-Verbose -Message "Adding $Path to environment path."
        } else {
            Write-Verbose -Message "$Path is already located in env:Path."
        }
    } # Process
} # Cmdlet

function Get-SteamCMDPath {
    <#
    .SYNOPSIS
    Find SteamCMD Install Path.

    .NOTES
    While it is a pretty simple search function of the env paths,
    All credit goes to author depicited by the link provided below as it has depedency by the Install-SteamCMD Module.

    .LINK
    https://www.powershellgallery.com/packages/SteamPS/2.0.1/Content/Private%5CGet-SteamPath.ps1
    #>

    [CmdletBinding()]
    param ()

    process {
        $VerbosePreference = 'Continue'

        $SteamCMDPaths = $env:Path.Split(';') | Where-Object { $_ -like "*SteamCMD*" }
        $Result = @()
    
        foreach ($SteamCMDPath in $SteamCMDPaths) {
            if ($null -ne $SteamCMDPath) {
                $ObjectProperties = [ordered]@{
                    'Path'       = $SteamCMDPath
                    'Executable' = Join-Path -Path $SteamCMDPath -ChildPath 'steamcmd.exe'
                }
                $Result += [PSCustomObject]$ObjectProperties
            }
        }
    
        if ($Result.Count -gt 0) {
            return $Result
        } else {
            Write-Host "No SteamCMD path found in the environment PATH variable."
            return $null
        }
    } # process
} # Cmdlet

function Install-SteamCMD {
    <#
    .SYNOPSIS
    Install SteamCMD.

    .DESCRIPTION
    This cmdlet/(function now) downloads SteamCMD and configures it in a custom or
    predefined location (C:\ASA-SingleEntryPoint).

    .PARAMETER InstallPath
    Specifiy the install location of SteamCMD.

    .PARAMETER Force
    The Force parameter allows the user to skip the "Should Continue" box.

    .EXAMPLE
    Install-SteamCMD

    Installs SteamCMD in C:\ASA-SingleEntryPoint.

    .EXAMPLE
    Applies if using as a cmdlet on shell.
        Install-SteamCMD -InstallPath 'C:'
            Installs SteamCMD in C:\SteamCMD.

    .NOTES
    Original Author: Frederik Hjorslev Poulsen,
    This is slightly modified version of the script for my own use, all credit goes to Hjorslev.

    .LINK
    https://hjorslev.github.io/SteamPS/Install-SteamCMD.html
    #>

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript( {
                if ($_.Substring(($_.Length -1)) -eq '\') {
                    throw "InstallPath may not end with a trailing slash."
                }
                $true
            })]
        # [string]$InstallPath = "$($env:ProgramFiles)",
        [string]$InstallPath = "C:\ASA-SingleEntryPoint",

        [Parameter(Mandatory = $false)]
        [switch]$Force = $true
    )

    process {
        $VerbosePreference = 'Continue'

        # Check for administrative privileges
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator."
            # Start-Process powershell -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`"") -Verb RunAs
            exit
        }

        if ($Force -or $PSCmdlet.ShouldContinue('Would you like to continue?', 'Install SteamCMD')) {
            # Ensures that SteamCMD is installed in a folder named SteamCMD.
            $InstallPath = $InstallPath + '\SteamCMD'

            # OT Handling Multiple Previous Installed Locations Added To Path
            $SteamPaths = Get-SteamCMDPath
            $PathExists = $false
            # Check if there are any SteamCMD paths
            if ($null -eq $SteamPaths) {
                Write-Verbose -Message "Adding $($InstallPath) to Environment Variable PATH."
                Add-EnvPath -Path $InstallPath -Container Machine
            } 
            else 
            {
                foreach ($Item in $SteamPaths) {
                    if ($Item.Path -ne $InstallPath) {
                        Write-Host "Removing path: $($Item.Path)"
                        # $envPathList = $env:Path -split ';' | Where-Object { $_ -ne $Item.Path }
                        $Targets = @(
                            [System.EnvironmentVariableTarget]::Machine,
                            [System.EnvironmentVariableTarget]::User
                        )
                        $envPath = ""
                        foreach ($Target in $Targets) {
                            $path = [Environment]::GetEnvironmentVariable('Path', $Target) -split ';' | Where-Object { $_ -ne $PathToRemove }
                            $envPath += ($path -join ';')
                            [Environment]::SetEnvironmentVariable('Path', $env:Path, $Target)
                        }
                        $env:Path = $envPath                        
                    } else {
                        $PathExists = $true
                        Write-Host "Keeping path: $($Item.Path)"
                    }
                }
                if (-not $PathExists) {
                    Write-Verbose -Message "Adding $($InstallPath) to Environment Variable PATH."
                    Add-EnvPath -Path $InstallPath -Container Machine
                }
            }

            $TempDirectory = 'C:\TempForSteamCMDInstallation'
            if (-not (Test-Path -Path $TempDirectory)) {
                Write-Verbose -Message 'Creating Temp directory.'
                    # Need safetey here, refactor to const.
                New-Item -Path 'C:\' -Name 'TempForSteamCMDInstallation' -ItemType Directory | Write-Verbose
            }

            # Download SteamCMD.
            Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile "$($TempDirectory)\steamcmd.zip" -UseBasicParsing

            # Create SteamCMD directory if necessary.
            if (-not (Test-Path -Path $InstallPath)) {
                Write-Verbose -Message "Creating SteamCMD directory: $($InstallPath)"
                New-Item -Path $InstallPath -ItemType Directory | Write-Verbose
                    # Need to add check here for item IsExist and throw safely
                Expand-Archive -Path "$($TempDirectory)\steamcmd.zip" -DestinationPath $InstallPath
            }

            # Doing some initial configuration of SteamCMD. The first time SteamCMD is launched it will need to do some updates.
            Write-Host -Object 'Configuring SteamCMD for the first time. This might take a little while.'
            Write-Host -Object 'Please wait' -NoNewline
            Start-Process -FilePath "$($InstallPath)\steamcmd.exe" -ArgumentList 'validate +quit' -WindowStyle Hidden
            do {
                Write-Host -Object "." -NoNewline
                Start-Sleep -Seconds 3
            }
            until (-not (Get-Process -Name "*steamcmd*"))
        }
    } # Process

    end {
        if (Test-Path -Path "$($TempDirectory)\steamcmd.zip") {
            Remove-Item -Path "$($TempDirectory)" -Recurse -Force
            Write-Host ""; Write-Verbose -Message "Temp Directory Removed.." -Verbose
        }

        if (Test-Path -Path (Get-SteamCMDPath).Executable) {
            Write-Output -InputObject "SteamCMD is now installed. Please close/open your PowerShell host."
            Write-Output "`n"; 
        }
    } # End
} # Cmdlet

Install-SteamCMD