# Disable the slow default web download progress bar for faster speeds
$ProgressPreference = 'SilentlyContinue'

# ── STEP 1: CLEAN ADMIN ELEVATION ──────────────────────────────
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
$IsAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    if ($PSCommandPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        $url = "https://raw.githubusercontent.com/HariKrishnaKumar/installer_tool/main/install_gui.ps1"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command `"irm '$url' | iex`""
    }
    exit
}

# ── STEP 2: LOAD WINFORMS ──────────────────────────────────────
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ── STEP 3: APP LIST ──────────────────────────────────────────
$apps = @(
    @{ name="Python 3.13"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/python-3.13.2-amd64.exe"; args="/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" }
    @{ name="VS Code"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/VSCodeUserSetup-x64-1.97.0.exe"; args="/VERYSILENT /SUPPRESSMSGBOXES /MERGETASKS=!runcode" }
    @{ name="PyCharm Community"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/pycharm-community-2024.3.2.exe"; args="/S" }
    @{ name="Anaconda"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/Anaconda3-2024.10-1-Windows-x86_64.exe"; args="/InstallationType=AllUsers /RegisterPython=1 /S /AddToPath=1" }
    @{ name="Android Studio"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/android-studio-2023.3.1.1-windows.exe"; args="/S" }
    @{ name="XAMPP"; type="exe"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/xampp-windows-x64-8.0.30-0-VS16-installer.exe"; args="--mode unattended --disable-components gettingstarted" }
    @{ name="MySQL"; type="msi"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/mysql-installer-community-8.0.43.0.msi"; args="" }
    @{ name="Turbo C++"; type="zip"; url="https://github.com/HariKrishnaKumar/software_bca/releases/download/v1.0/TurboC3.zip"; args="C:\TurboC3" }
)

# ── STEP 4: UI DESIGN ─────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = "Software Installer"
$form.Size = New-Object System.Drawing.Size(520, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Select software to install:"
$lblTitle.Location = New-Object System.Drawing.Point(20, 15)
$lblTitle.Size = New-Object System.Drawing.Size(460, 20)
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::White

$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Location = New-Object System.Drawing.Point(20, 40)
$listBox.Size = New-Object System.Drawing.Size(460, 220)
$listBox.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$listBox.ForeColor = [System.Drawing.Color]::White
$listBox.CheckOnClick = $true
foreach ($app in $apps) { [void]$listBox.Items.Add($app.name) }

$btnAll = New-Object System.Windows.Forms.Button
$btnAll.Text = "Select All"
$btnAll.Location = New-Object System.Drawing.Point(20, 270)
$btnAll.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnAll.ForeColor = [System.Drawing.Color]::White

$btnNone = New-Object System.Windows.Forms.Button
$btnNone.Text = "Select None"
$btnNone.Location = New-Object System.Drawing.Point(100, 270)
$btnNone.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$btnNone.ForeColor = [System.Drawing.Color]::White

$statusBox = New-Object System.Windows.Forms.TextBox
$statusBox.Multiline = $true
$statusBox.ReadOnly = $true
$statusBox.ScrollBars = "Vertical"
$statusBox.Location = New-Object System.Drawing.Point(20, 310)
$statusBox.Size = New-Object System.Drawing.Size(460, 150)
$statusBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$statusBox.ForeColor = [System.Drawing.Color]::LimeGreen

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 470)
$progressBar.Size = New-Object System.Drawing.Size(460, 20)

$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "Install Selected"
$installBtn.Location = New-Object System.Drawing.Point(20, 500)
$installBtn.Size = New-Object System.Drawing.Size(220, 40)
$installBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 50)
$installBtn.ForeColor = [System.Drawing.Color]::White

$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "Exit"
$exitBtn.Location = New-Object System.Drawing.Point(260, 500)
$exitBtn.Size = New-Object System.Drawing.Size(220, 40)
$exitBtn.BackColor = [System.Drawing.Color]::FromArgb(180, 30, 30)
$exitBtn.ForeColor = [System.Drawing.Color]::White

# ── STEP 5: HELPERS ───────────────────────────────────────────
function Write-Log([string]$msg) {
    $statusBox.AppendText("$msg`r`n")
    $statusBox.SelectionStart = $statusBox.Text.Length
    $statusBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# ── STEP 6: BUTTON LOGIC ──────────────────────────────────────
$btnAll.Add_Click({ for ($i=0; $i -lt $listBox.Items.Count; $i++) { $listBox.SetItemChecked($i, $true) } })
$btnNone.Add_Click({ for ($i=0; $i -lt $listBox.Items.Count; $i++) { $listBox.SetItemChecked($i, $false) } })
$exitBtn.Add_Click({ $form.Close() })

$installBtn.Add_Click({
    $selected = @()
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        if ($listBox.GetItemChecked($i)) { $selected += $i }
    }

    if ($selected.Count -eq 0) { return }

    $installBtn.Enabled = $false
    $listBox.Enabled = $false
    $statusBox.Clear()
    $progressBar.Value = 0

    $temp = "$env:TEMP\software_installer"
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    
    $total = $selected.Count
    $done = 0

    foreach ($idx in $selected) {
        $app = $apps[$idx]
        $done++
        
        $ext = ($app.url -split '\.')[-1]
        $file = "$temp\$($app.name -replace '[^a-zA-Z0-9]', '_').$ext"
        $percent = [math]::Round((($done - 1) / $total) * 100)

        # Update Console Progress Bar
        Write-Progress -Activity "BCA Software Installer" -Status "Downloading $($app.name)... [$done/$total]" -PercentComplete $percent

        Write-Log "[$done/$total] Downloading $($app.name)..."
        $progressBar.Value = $percent
        [System.Windows.Forms.Application]::DoEvents()

        try {
            Invoke-WebRequest -Uri $app.url -OutFile $file -UseBasicParsing -ErrorAction Stop
            Write-Log "  [OK] Downloaded. Installing..."
            Write-Progress -Activity "BCA Software Installer" -Status "Installing $($app.name)... [$done/$total]" -PercentComplete $percent
            [System.Windows.Forms.Application]::DoEvents()

            if ($app.type -eq "zip") {
                Expand-Archive -Path $file -DestinationPath $app.args -Force
                Write-Log "  [OK] Extracted Successfully to $($app.args)."
            }
            elseif ($app.type -eq "msi") {
                $proc = Start-Process "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait -PassThru -ErrorAction Stop
                if ($proc.ExitCode -in 0, 3010) { Write-Log "  [OK] Installed Successfully." } 
                else { Write-Log "  [WARN] Finished with exit code $($proc.ExitCode)." }
            } 
            else {
                $proc = Start-Process $file -ArgumentList $app.args -Wait -PassThru -ErrorAction Stop
                if ($proc.ExitCode -in 0, 3010) { Write-Log "  [OK] Installed Successfully." } 
                else { Write-Log "  [WARN] Finished with exit code $($proc.ExitCode)." }
            }
        }
        catch {
            Write-Log "  [FAIL] ERROR: $($_.Exception.Message)"
        }
        
        $percentComplete = [math]::Round(($done / $total) * 100)
        $progressBar.Value = $percentComplete
        Write-Progress -Activity "BCA Software Installer" -Status "Completed $($app.name)" -PercentComplete $percentComplete
        Write-Log "----------------------------------"
    }

    Write-Log "ALL OPERATIONS COMPLETE."
    Write-Progress -Activity "BCA Software Installer" -Completed
    $installBtn.Enabled = $true
    $listBox.Enabled = $true
})

# ── STEP 7: EXECUTE ───────────────────────────────────────────
$form.Controls.AddRange(@($lblTitle, $listBox, $btnAll, $btnNone, $statusBox, $progressBar, $installBtn, $exitBtn))
[void]$form.ShowDialog()
