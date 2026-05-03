Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---- Form ----
$form = New-Object System.Windows.Forms.Form
$form.Text = "Software Installer"
$form.Size = New-Object System.Drawing.Size(500,550)
$form.StartPosition = "CenterScreen"

# ---- List ----
$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Size = New-Object System.Drawing.Size(440,250)
$listBox.Location = New-Object System.Drawing.Point(20,20)

# ---- Status Box ----
$statusBox = New-Object System.Windows.Forms.TextBox
$statusBox.Multiline = $true
$statusBox.ReadOnly = $true
$statusBox.ScrollBars = "Vertical"
$statusBox.Size = New-Object System.Drawing.Size(440,120)
$statusBox.Location = New-Object System.Drawing.Point(20,280)

# ---- Progress Bar ----
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(440,20)
$progressBar.Location = New-Object System.Drawing.Point(20,410)

# ---- Buttons ----
$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "Install Selected"
$installBtn.Size = New-Object System.Drawing.Size(150,40)
$installBtn.Location = New-Object System.Drawing.Point(60,440)

$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "Exit"
$exitBtn.Size = New-Object System.Drawing.Size(150,40)
$exitBtn.Location = New-Object System.Drawing.Point(260,440)

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

# ---- Background Worker (NO UI FREEZE) ----
$worker = New-Object System.ComponentModel.BackgroundWorker
$worker.WorkerReportsProgress = $true

$worker.DoWork += {
    param($sender, $e)

    $temp = "$env:TEMP\installer"
    New-Item -ItemType Directory -Force -Path $temp | Out-Null

    $selectedIndexes = $e.Argument
    $total = $selectedIndexes.Count
    $count = 0

    foreach ($index in $selectedIndexes) {

        $app = $apps[$index]
        $count++

        $sender.ReportProgress(($count / $total) * 100, "Downloading $($app.name)...")

        $ext = ($app.url.Split('.')[-1]).Split('?')[0]
        $safeName = $app.name -replace '[^a-zA-Z0-9]', '_'
        $file = "$temp\$safeName.$ext"

        try {
            Invoke-WebRequest -Uri $app.url -OutFile $file -ErrorAction Stop
        }
        catch {
            $sender.ReportProgress(($count / $total) * 100, "FAILED download: $($app.name)")
            continue
        }

        $sender.ReportProgress(($count / $total) * 100, "Installing $($app.name)...")

        try {
            if ($ext -eq "msi") {
                Start-Process "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait
            } else {
                Start-Process $file -ArgumentList $app.args -Wait
            }
        }
        catch {
            $sender.ReportProgress(($count / $total) * 100, "FAILED install: $($app.name)")
            continue
        }

        $sender.ReportProgress(($count / $total) * 100, "DONE: $($app.name)")
    }
}

$worker.ProgressChanged += {
    param($sender, $e)

    $progressBar.Value = [int]$e.ProgressPercentage
    $statusBox.AppendText($e.UserState + "`r`n")
}

$worker.RunWorkerCompleted += {
    $installBtn.Enabled = $true
    $statusBox.AppendText("`r`n=== ALL TASKS COMPLETED ===`r`n")
}

# ---- Install Button ----
$installBtn.Add_Click({

    if ($listBox.CheckedIndices.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one software")
        return
    }

    $installBtn.Enabled = $false
    $statusBox.Clear()
    $progressBar.Value = 0

    $selected = @()
    foreach ($i in $listBox.CheckedIndices) { $selected += $i }

    $worker.RunWorkerAsync($selected)
})

# ---- Exit ----
$exitBtn.Add_Click({ $form.Close() })

# ---- Add Controls ----
$form.Controls.Add($listBox)
$form.Controls.Add($statusBox)
$form.Controls.Add($progressBar)
$form.Controls.Add($installBtn)
$form.Controls.Add($exitBtn)

# ---- Run ----
$form.ShowDialog()