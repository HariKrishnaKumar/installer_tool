Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---- Form ----
$form = New-Object System.Windows.Forms.Form
$form.Text = "Software Installer"
$form.Size = New-Object System.Drawing.Size(450,500)
$form.StartPosition = "CenterScreen"

# ---- List ----
$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Size = New-Object System.Drawing.Size(400,300)
$listBox.Location = New-Object System.Drawing.Point(20,20)

# ---- Apps ----
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

# Add items
foreach ($app in $apps) {
    [void]$listBox.Items.Add($app.name)
}

# ---- Buttons ----
$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "Install Selected"
$installBtn.Size = New-Object System.Drawing.Size(150,40)
$installBtn.Location = New-Object System.Drawing.Point(50,350)

$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "Exit"
$exitBtn.Size = New-Object System.Drawing.Size(150,40)
$exitBtn.Location = New-Object System.Drawing.Point(230,350)

# ---- INSTALL LOGIC ----
$installBtn.Add_Click({

    $temp = "$env:TEMP\installer"
    New-Item -ItemType Directory -Force -Path $temp | Out-Null

    $success = @()
    $failed = @()

    foreach ($index in $listBox.CheckedIndices) {

        $app = $apps[$index]

        $ext = ($app.url.Split('.')[-1]).Split('?')[0]
        $safeName = $app.name -replace '[^a-zA-Z0-9]', '_'
        $file = "$temp\$safeName.$ext"

        # ---- DOWNLOAD (RETRY) ----
        $downloaded = $false
        for ($i=1; $i -le 2; $i++) {
            try {
                Invoke-WebRequest -Uri $app.url -OutFile $file -ErrorAction Stop
                $downloaded = $true
                break
            }
            catch {
                if ($i -eq 2) {
                    $failed += $app.name
                }
            }
        }

        if (-not $downloaded) { continue }

        # ---- INSTALL ----
        try {
            if ($ext -eq "msi") {
                Start-Process "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait
            }
            else {
                Start-Process $file -ArgumentList $app.args -Wait
            }
        }
        catch {
            $failed += $app.name
            continue
        }

        # ---- VERIFY ----
        $installed = $true

        if ($app.name -eq "Python") {
            if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
                $installed = $false
            }
        }

        if (-not $installed) {
            $failed += $app.name
            continue
        }

        # ---- PATH FIX ----
        if ($app.name -eq "Python") {
            $pythonPath = "C:\Program Files\Python313"
            if (Test-Path $pythonPath) {
                $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
                if ($envPath -notlike "*Python313*") {
                    [Environment]::SetEnvironmentVariable(
                        "Path",
                        "$envPath;$pythonPath;$pythonPath\Scripts",
                        "Machine"
                    )
                }
            }
        }

        $success += $app.name
    }

    # ---- RESULT ----
    $msg = "Installed:`n" + ($success -join "`n") + "`n`nFailed:`n" + ($failed -join "`n")
    [System.Windows.Forms.MessageBox]::Show($msg, "Summary")

})

# ---- Exit ----
$exitBtn.Add_Click({
    $form.Close()
})

# ---- Add Controls ----
$form.Controls.Add($listBox)
$form.Controls.Add($installBtn)
$form.Controls.Add($exitBtn)

# ---- Run ----
$form.ShowDialog()