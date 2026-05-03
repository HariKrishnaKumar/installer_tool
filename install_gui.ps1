# ================================
#   GUI INSTALLER (FINAL FIXED)
# ================================

# ---- ADMIN CHECK (SINGLE LINE - SAFE) ----
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/HariKrishnaKumar/installer_tool/main/install_gui.ps1 | iex`""
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Software Installer"
$form.Size = New-Object System.Drawing.Size(500,550)
$form.StartPosition = "CenterScreen"

$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Size = New-Object System.Drawing.Size(440,250)
$listBox.Location = New-Object System.Drawing.Point(20,20)

$statusBox = New-Object System.Windows.Forms.TextBox
$statusBox.Multiline = $true
$statusBox.ReadOnly = $true
$statusBox.ScrollBars = "Vertical"
$statusBox.Size = New-Object System.Drawing.Size(440,120)
$statusBox.Location = New-Object System.Drawing.Point(20,280)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(440,20)
$progressBar.Location = New-Object System.Drawing.Point(20,410)

$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "Install Selected"
$installBtn.Size = New-Object System.Drawing.Size(150,40)
$installBtn.Location = New-Object System.Drawing.Point(60,440)

$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "Exit"
$exitBtn.Size = New-Object System.Drawing.Size(150,40)
$exitBtn.Location = New-Object System.Drawing.Point(260,440)

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

foreach ($app in $apps) { [void]$listBox.Items.Add($app.name) }

$worker = New-Object System.ComponentModel.BackgroundWorker
$worker.WorkerReportsProgress = $true

Register-ObjectEvent $worker DoWork -Action {
    $sel = $Event.SourceEventArgs.Argument
    $temp = "$env:TEMP\installer"
    New-Item -ItemType Directory -Force -Path $temp | Out-Null

    $total = $sel.Count
    $count = 0

    foreach ($i in $sel) {
        $app = $apps[$i]
        $count++

        $ext = ($app.url.Split('.')[-1]).Split('?')[0]
        $name = $app.name -replace '[^a-zA-Z0-9]', '_'
        $file = "$temp\$name.$ext"

        $Event.Sender.ReportProgress(($count/$total)*100, "Downloading $($app.name)...")

        try { Invoke-WebRequest $app.url -OutFile $file -ErrorAction Stop }
        catch { $Event.Sender.ReportProgress(($count/$total)*100, "FAILED download: $($app.name)"); continue }

        $Event.Sender.ReportProgress(($count/$total)*100, "Installing $($app.name)...")

        try {
            if ($ext -eq "msi") {
                Start-Process "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait
            } else {
                Start-Process $file -ArgumentList $app.args -Wait
            }
        } catch {
            $Event.Sender.ReportProgress(($count/$total)*100, "FAILED install: $($app.name)")
            continue
        }

        $Event.Sender.ReportProgress(($count/$total)*100, "DONE: $($app.name)")
    }
}

Register-ObjectEvent $worker ProgressChanged -Action {
    $progressBar.Value = [int]$Event.SourceEventArgs.ProgressPercentage
    $statusBox.AppendText($Event.SourceEventArgs.UserState + "`r`n")
}

Register-ObjectEvent $worker RunWorkerCompleted -Action {
    $installBtn.Enabled = $true
    $statusBox.AppendText("`r`n=== COMPLETED ===`r`n")
}

$installBtn.Add_Click({
    if ($listBox.CheckedIndices.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one software")
        return
    }

    $installBtn.Enabled = $false
    $statusBox.Clear()
    $progressBar.Value = 0

    $sel = @()
    foreach ($i in $listBox.CheckedIndices) { $sel += $i }

    $worker.RunWorkerAsync($sel)
})

$exitBtn.Add_Click({ $form.Close() })

$form.Controls.Add($listBox)
$form.Controls.Add($statusBox)
$form.Controls.Add($progressBar)
$form.Controls.Add($installBtn)
$form.Controls.Add($exitBtn)

$form.ShowDialog()
