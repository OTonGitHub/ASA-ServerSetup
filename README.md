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

#### Installing SteamCMD

> Client (exit and re-open powershell, then follow below)

- while you can directly download the file from the server, I will avoid that for safetey reasons, and
  want users to download it first on their client and go through the script.
- use the following command to download the latest available version of the script.
- `curl -O https://raw.githubusercontent.com/OTonGitHub/ASA-ServerSetup/main/Install-SteamCMD.ps1`
  I will not be held responsible for any issues caused from the code, go through it on your own!
- then copy this file to the server, to do this, use the following commands.
- `$Session = New-PSSession -ComputerName <your_server_ip_address> -Credential (Get-Credential)`
- use `Get-PSSession` to make sure the session is open.
- `Copy-Item "C:\D:\path\to\Install-SteamCMD.ps1" -Destination "C:\ASA-SingleEntryPoint" -ToSession $Session`
- `Remove-PSSession -Session $SESSION`

Now that the file is copied, hopefully without any errors, we can use the shell to directly open a connection to the
server to continue the rest of the setup.

- `Enter-PSSession -ComputerName <your_server_ip_address> -Credential (Get-Credential)`.
- `cd C:\ASA-SingleEntryPoint`
- `powershell -NoProfile -ExecutionPolicy Bypass -File "Install-SteamCMD.ps1"`
- script is safe to re-run, follow on-screen instructions.
- script should install latest version of SteamCMD as provided by the Valve CDN.
- and it should add the correct .exe file to the env, you can call `steamcmd` from the server shell now.

${{\color{Goldenrod}\small{\textsf{
If for any reason, maybe you cancel the download or the process is interrupted etc, you might want to restart
}}}}$ </br>
${{\color{Goldenrod}\small{\textsf{
by deleting the ASA-SingleEntryPoint directory and starting over, if for any reason, maybe you cancel the download
}}}}$ </br>
${{\color{Goldenrod}\small{\textsf{
or the process is interrupted etc. BUT, only do this at this point, do not delete the directory later on if you
}}}}$ </br>
${{\color{Goldenrod}\small{\textsf{
have succesfully installed SteamCMD using the above instructions.
}}}}$

- `Remove-Item -Path C:\ASA-SingleEntryPoint -Recurse -Force`
- then just re-do everything from above.
- only thing this does-not undo is removing the steamcmd.exe path from the env path.

#### Using SteamCMD - Initial Setup

> Client (exit and re-open powershell, then follow below)

- first try running `steamcmd` to make sure it's installed and working properly.
