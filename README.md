## 🚀 How to Install

Run this single command in Windows PowerShell to launch the installer tool instantly. No manual downloads or configurations are required.

```powershell
irm https://raw.githubusercontent.com/HariKrishnaKumar/installer_tool/main/install_gui.ps1 | iex
```

## if any security error add this:

Run this command in Windows PowerShell to launch the installer tool. It will automatically request Administrator privileges and bypass local execution policies.

```powershell
Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command `"irm '[https://raw.githubusercontent.com/HariKrishnaKumar/installer_tool/main/install_gui.ps1](https://raw.githubusercontent.com/HariKrishnaKumar/installer_tool/main/install_gui.ps1)' | iex`""
```

enable:
```
Set-ExecutionPolicy Bypass -Scope Process -Force
```

disable:
```
Set-ExecutionPolicy Undefined -Scope Process
```
