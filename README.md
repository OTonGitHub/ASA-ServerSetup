## ASA-Server Setup

- **important! setup assumes that you are**
  - using a Windows Server Core (GUI-less) as the hosting server.
  - and use a remote machine to open a session to the server and doing the configuration.
- there are various way to do this, you may use:
  - SSH & Use `Chocolatey` to install what you require.
  - using `SteamPS` or other such Powershell tools, which usually has a dependency (usually Powershell v7+).
- I have found that, these existing methods, have either too many dependencies or is heavy.
- hence the following script and commands focuses on creating a **Minimal** and **Repeatable** set of instructions
  on setting up SteamCMD and then your ARK/any game servers.
- please read the script file before using.
- keep in mind, all the client side commands to be run uses powershell, powershell 7+ is cross-platform, so you can use
  any device as the client.

### Commands

> _The following commands and scripts, assume you use a client device to manage the server
> to SSH or Enter-PSSession into the server to run the following commands,
> so all the commandlets are preceded with weather they are run on client or directly on the server._

everything that will be installed or persisted will be to the following directory

- `C:\ASA-SingleEntryPoint`

#### Update Windows Server Core

> Run directly on the server, as both SSH & Remote PS Sessions for running this command gets rejected by windows.

- type `SConfig` into the shell and press enter.
- follow the on-screen instructions to update the server

#### Installing OpenSSH Server

_DON'T INSTALL OPENSSH IF YOU RATHER MODIFY SCRIPT TO DISABLE INTERACTIVITY_

> Again, not required but, in the case, and we do use a script that needs interaction,
> using `Enter-PSSession` remotely will not allow this.
> Furhtermore, having `ssh` allows us to use `SCP` to copy the files to the server, but I will
> show the other method of using Enter-PSSession with Copy-Item from powershell as well.

- `Enter-PSSession -ComputerName <your_server_ip_address> -Credential (Get-Credential)`
- use this command to check installation status of openSSH on the server
- `Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH\*'`
- install `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
- `Start-Service sshd`
- `Set-Service -Name sshd -StartupType 'Automatic'`
- Set Firewall Rule:
  - `if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) { Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."; New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 } else { Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists." }`
- check if firewall configured
- `Get-NetFirewallRule -Direction Inbound | Where-Object { $_.DisplayName -like '*ssh*' }`

#### Installing SteamCMD

**The `Install-SteamCMD.ps1` script mostly code from the `SteamPS` project, taken from `WinGet` website, under fair use,
I have kept credit even in the script itself**

> Client (exit and re-open powershell, then follow below)

- while you can directly download the file from the server, I will avoid that for safetey reasons, and
  want users to download it first on their client and go through the script.
- use the following command to download the latest available version of the script.
- `curl -O https://raw.githubusercontent.com/OTonGitHub/ASA-ServerSetup/main/Install-SteamCMD.ps1`
  I will not be held responsible for any issues caused from the code, go through it on your own!
- then copy this file to the server, to do this, use the following commands.

#### Create Directory Remotely

- `$Session = New-PSSession -ComputerName <your_server_ip_address> -Credential (Get-Credential)`
- use `Get-PSSession` to make sure the session is open.
- create directory before copying.
- `Invoke-Command -Session $Session -ScriptBlock { New-Item -ItemType Directory -Path "C:\ASA-SingleEntryPoint" }`
- #### PSSession Session Method
  - assuming still in the same shell session from last command.
  - `Copy-Item "Install-SteamCMD.ps1" -Destination "C:\ASA-SingleEntryPoint" -ToSession $Session`
  - cleanup.
  - `Remove-PSSession -Session $SESSION`
  - `rm Install-SteamCMD.ps1`
- #### Using SCP (If Installed OpenSSH)
  - `scp .\Install-SteamCMD.ps1 Administrator@<your_server_ip_address>:C:\ASA-SingleEntryPoint\`

**Now that the file is copied, hopefully without any errors, we can use the shell to directly open a connection to the
server to continue the rest of the setup.**

- If you decide to use OpenSSH, run
  - `ssh Administrator@<your_server_ip_address>`
  - `powershell`
    - don't add `powershell` at the end of `ssh` command.
- Else If you otherwise would like to avoid using OpenSSh, Then
  - modify script to remove interactive parts of the code, then run
  - `Enter-PSSession -ComputerName <your_server_ip_address> -Credential (Get-Credential)`.
- `cd C:\ASA-SingleEntryPoint`
- `powershell -NoProfile -ExecutionPolicy Bypass -File "Install-SteamCMD.ps1"`
- script is safe to re-run, follow on-screen instructions.
- script should install latest version of SteamCMD as provided by the Valve CDN.
- and it should add the correct .exe file to the env, you can call `steamcmd` from the server shell now.

${{\color{Goldenrod}\normalsize{\textsf{
If for any reason, maybe you cancel the download or the process is interrupted etc, you might want to restart
}}}}$ </br>
${{\color{Goldenrod}\normalsize{\textsf{
by deleting the ASA-SingleEntryPoint directory and starting over, if for any reason, maybe you cancel the download
}}}}$ </br>
${{\color{Goldenrod}\normalsize{\textsf{
or the process is interrupted etc. BUT, only do this at this point, do not delete the directory later on if you
}}}}$ </br>
${{\color{Goldenrod}\normalsize{\textsf{
have succesfully installed SteamCMD using the above instructions.
}}}}$ <!-- yea this is stupid -->

- `Remove-Item -Path C:\ASA-SingleEntryPoint -Recurse -Force`
- then just re-do everything from above.
- only thing this does-not undo is removing the steamcmd.exe path from the env path.

#### Uninstall SSH and Remove Firewall Rule

- `Stop-Service sshd`
- `Set-Service -Name sshd -StartupType 'Disabled'`
- `Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
- `Remove-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'`

#### Using SteamCMD - Initial Setup

> Client (exit and re-open powershell, then follow below)

- first try running `steamcmd` to make sure it's installed and working properly.
- rest will be updated in the next few days..
