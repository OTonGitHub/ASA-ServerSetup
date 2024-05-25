## ASA-Server Setup

- Please read the script file before using

### Commands

> The following commands and scripts, assume you use a client management system
> to SSH or PS-RemoteSession into the server to run the following commands,
> so all the commandlets are preceded with weather they are run on client or server.

#### Folder Setup

- First, Create `ASA-SingleEntryPoint` Folder in C Drive.
- SSH into the server using `<code>`
- Then execute `<code>`
- Then execute `<code>`
- Folder setup is complete.

#### SteamCMD

- Well

iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

install powershell 7 without installing chocolatey

Get-Module -Name SteamPS -ListAvailable | Select-Object -Property Name, Version

// INSTALLS

- STEAMPS
- CHOCOLATEY
  - PWSHS

// ssh
// first check if in admin role using below cmmand from ms, the long isInRole one, then run
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

can also remove using Remove-\*

// check if installed
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH\*'

Start-Service sshd

// FROM MICROSOFT => https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell

# Start the sshd service

Start-Service sshd

# OPTIONAL but recommended:

Set-Service -Name sshd -StartupType 'Automatic'

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify

if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}

Get-NetFirewallRule -Direction Inbound | Where-Object { $\_.DisplayName -like '_ssh_' }

// chocolatey
choco install pwsh -y
-- make sure ot use -y flag, try without -y see whathappe
ns.

// Server
Enable-PSRemoting -Force
Get-Service WinRM
Start-Service WinRM
winrm quickconfig

Update-SteamApp -AppID 2430930 -Path 'C:\ASA-EntryPoint'

// check if admin session
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

// switgch to elevated powershell
Start-Process PowerShell -Verb runas

// remove childitems etc
Remove-Item -Path C:\ProgramData\chocolatey -Recurse -Force

// list all items
ls -Force

// default execution policy
RemoteSigned

// install powershell 7
winget install --id Microsoft.Powershell --source winget

// open shell in powershell 7 (client)
pwsh

// Client
Set-Item WSMan:localhost\Client\TrustedHosts -Value 192.168.100.100 -Force
Enter-PSSession -ComputerName 192.168.100.100 -Credential (Get-Credential)

// Check powershell version
$PSVersionTable

Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile "C:\ASA-EntryPoint\steamcmd.zip" -UseBasicParsing

// Disk Space
Get-PSDrive | Where-Object { $_.Free -ne $null } | Select-Object -Property Name, @{Label='FreeSpace (GB)'; expression={($_.Free/1GB).ToString('F2')}}
Get-WmiObject -Class Win32_LogicalDisk | Select-Object -Property DeviceID, VolumeName, @{Label='FreeSpace (GB)'; expression={($_.FreeSpace/1GB).ToString('F2')}}, @{Label='Total (GB)'; expression={($\_.Size/1GB).ToString('F2')}}

// RSAT (client)
// might need previlege
Get-WindowsCapability -Name RSAT\* -Online | Select-Object -Property DisplayName, State

Update-SteamApp -AppID 2430930 -Path 'C:\ASA-EntryPoint'

// COMMON COMMANDS
#Get a list of modules
Get-Module -ListAvailable

#Get the commands that are part of a module
Get-Command -Module ServerManager

#Manage local server features and roles
Get-WindowsFeature
Get-WindowsFeature | Where-Object {$\_.InstallState -eq 'Installed'}
Install-WindowsFeature -Name Telnet-Client
Get-WindowsFeature -Name Telnet-Client
Uninstall-WindowsFeature -Name Telnet-Client

#Get events
Get-EventLog -LogName System -EntryType Error
Get-EventLog -LogName System -EntryType Warning -Newest 3
Get-EventLog -LogName System -EntryType Warning -Message "_time service_"
Get-EventLog -LogName system -Source Microsoft-Windows-Kernel-General

#Manage services
Get-Service
Get-Service -Name BITS
Start-Service -Name BITS
Stop-Service -Name BITS

#Most commands have a ComputerName parameter so they can executed on remote machines
#I prefer to use Powershell Remoting with Invoke-Command in most cases
#PS Remoting can also be used in a SSH style with Enter-PSSession

#Run some commands in an interactive PS remoting session
Enter-PSSession -ComputerName Lab-DC01
HOSTNAME
ipconfig
Get-Service
Get-WindowsFeature
Exit-PSSession

#With Invoke-Command we can execute commands on multiple servers and in parallel
Invoke-Command -ComputerName 'localhost','Lab-DC01' -ScriptBlock {Get-Service BITS}
Invoke-Command -ComputerName 'localhost','Lab-DC01' -ScriptBlock {Get-EventLog -LogName System -EntryType Warning -Newest 3}

Invoke-Command -ComputerName 'localhost','Lab-DC01' -ScriptBlock {Install-WindowsFeature -Name Telnet-Client}
Invoke-Command -ComputerName 'localhost','Lab-DC01' -ScriptBlock {Get-WindowsFeature -Name Telnet-Client}
