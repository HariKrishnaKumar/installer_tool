# ---- Download GUI Installer ----
$scriptUrl = "https://raw.githubusercontent.com/HariKrishnaKumar/installer_tool/main/install_gui.ps1"
$tempFile = "$env:TEMP\install_gui.ps1"

Write-Host "Downloading installer..."

try {
    Invoke-WebRequest -Uri $scriptUrl -OutFile $tempFile -ErrorAction Stop
}
catch {
    Write-Host "Download failed"
    exit
}

Write-Host "Launching installer..."

powershell -ExecutionPolicy Bypass -File $tempFile