# ================================
#   CLEAN INSTALLER (STABLE)
# ================================

# ---- Admin check ----
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# ---- Temp folder ----
$temp = Join-Path $env:TEMP "installer"
New-Item -ItemType Directory -Force -Path $temp | Out-Null

# ---- Software list ----
$apps = @(
    @{ name="Python"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/python-3.13.2-amd64.exe"; args="/quiet InstallAllUsers=1 PrependPath=1" },
    @{ name="VS Code"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/VSCodeUserSetup-x64-1.97.0.exe"; args="/silent" },
    @{ name="PyCharm"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/pycharm-community-2024.3.2.exe"; args="/S" },
    @{ name="Anaconda"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/Anaconda3-2024.10-1-Windows-x86_64.exe"; args="/InstallationType=AllUsers /S /AddToPath=1" },
    @{ name="Android Studio"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/android-studio-2023.3.1.1-windows.exe"; args="/S" },
    @{ name="XAMPP"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/xampp-windows-x64-8.0.30-0-VS16-installer.exe"; args="/S" },
    @{ name="MySQL"; type="msi"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/mysql-installer-community-8.0.43.0.msi" },
    @{ name="Turbo C++"; type="msi"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/Turbo.C++.3.2.msi" }
)

# ---- Selection UI ----
$selected = @()
$index = 0

while ($true) {
    Clear-Host
    Write-Host "====================================="
    Write-Host " Select software (SPACE to toggle)"
    Write-Host " ENTER = Install"
    Write-Host "====================================="
    Write-Host ""

    for ($i = 0; $i -lt $apps.Count; $i++) {

        if ($i -eq $index) { $pointer = ">" } else { $pointer = " " }

        if ($selected -contains $i) {
            $mark = "[x]"
        } else {
            $mark = "[ ]"
        }

        Write-Host "$pointer $mark $($apps[$i].name)"
    }

    $key = [Console]::ReadKey($true)

    if ($key.Key -eq "UpArrow" -and $index -gt 0) {
        $index--
    }
    elseif ($key.Key -eq "DownArrow" -and $index -lt ($apps.Count - 1)) {
        $index++
    }
    elseif ($key.Key -eq "Spacebar") {
        if ($selected -contains $index) {
            $selected = $selected | Where-Object { $_ -ne $index }
        } else {
            $selected += $index
        }
    }
    elseif ($key.Key -eq "Enter") {
        break
    }
}

# ---- Install ----
foreach ($i in $selected) {

    $app = $apps[$i]

    $ext = ($app.url.Split('.')[-1]).Split('?')[0]
    $safeName = $app.name -replace '[^a-zA-Z0-9]', '_'
    $file = Join-Path $temp ($safeName + "." + $ext)

    Write-Host ""
    Write-Host "Installing $($app.name)..."

    try {
        Invoke-WebRequest -Uri $app.url -OutFile $file -ErrorAction Stop

        if ($ext -eq "msi") {
            Start-Process "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait
        } else {
            Start-Process $file -ArgumentList $app.args -Wait
        }

        Write-Host "SUCCESS"
    }
    catch {
        Write-Host "FAILED"
    }
}

Write-Host ""
Write-Host "Completed."
Pause

$selected = @()
$index = 0

while ($true) {
    Clear-Host
    Write-Host "====================================="
    Write-Host " Select software (SPACE to toggle)"
    Write-Host " ENTER = Install"
    Write-Host " ESC = Exit"
    Write-Host "====================================="
    Write-Host ""

    for ($i = 0; $i -lt $apps.Count; $i++) {

        if ($i -eq $index) { $pointer = ">" } else { $pointer = " " }

        if ($selected -contains $i) {
            $mark = "[x]"
        } else {
            $mark = "[ ]"
        }

        Write-Host "$pointer $mark $($apps[$i].name)"
    }

    $key = [Console]::ReadKey($true)

    if ($key.Key -eq "UpArrow" -and $index -gt 0) {
        $index--
    }
    elseif ($key.Key -eq "DownArrow" -and $index -lt ($apps.Count - 1)) {
        $index++
    }
    elseif ($key.Key -eq "Spacebar") {
        if ($selected -contains $index) {
            $selected = $selected | Where-Object { $_ -ne $index }
        } else {
            $selected += $index
        }
    }
    elseif ($key.Key -eq "Enter") {
        break
    }
    elseif ($key.Key -eq "Escape") {
        Write-Host "`nExiting..."
        exit
    }
}