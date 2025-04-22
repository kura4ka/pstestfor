Add-Type -AssemblyName PresentationFramework

function Show-Menu {
    $menu = New-Object System.Windows.Forms.Form
    $menu.Text = "System Maintenance Menu"
    $menu.Size = New-Object System.Drawing.Size(400,400)
    $menu.StartPosition = "CenterScreen"

    $buttons = @(
        "Create Restore Point",
        "Disable Startup Programs",
        "Kill Unnecessary Processes",
        "Install Drivers",
        "Restart System",
        "System Restore"
    )

    for ($i = 0; $i -lt $buttons.Length; $i++) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $buttons[$i]
        $btn.Size = New-Object System.Drawing.Size(350,40)
        $btn.Location = New-Object System.Drawing.Point(20, 30 + ($i * 50))
        $btn.Add_Click({ Execute-Action $btn.Text })
        $menu.Controls.Add($btn)
    }

    [void]$menu.ShowDialog()
}

function Execute-Action($action) {
    switch ($action) {
        "Create Restore Point" {
            Check-RestoreEnabled
            CheckAndCreate-RestorePoint
        }
        "Disable Startup Programs" {
            Disable-Autostart
        }
        "Kill Unnecessary Processes" {
            Kill-UnnecessaryProcesses
        }
        "Install Drivers" {
            Install-Drivers
        }
        "Restart System" {
            Restart-Computer -Force
        }
        "System Restore" {
            Start-Process "rstrui.exe"
        }
    }
}

function Check-RestoreEnabled {
    $enabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    if (!$enabled) {
        Enable-ComputerRestore -Drive "C:\"
    }
}

function CheckAndCreate-RestorePoint {
    Check-RestoreEnabled
    Checkpoint-Computer -Description "Pre-Maintenance Restore Point" -RestorePointType "MODIFY_SETTINGS"
    [System.Windows.Forms.MessageBox]::Show("Restore point created successfully.")
}

function Disable-Autostart {
    Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" | 
        ForEach-Object {
            if ($_ -isnot [System.String]) {
                Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.PSChildName
            }
        }
    [System.Windows.Forms.MessageBox]::Show("Startup programs disabled.")
}

function Kill-UnnecessaryProcesses {
    $safeList = @("explorer", "powershell", "System", "svchost", "lsass", "winlogon", "csrss", "smss", "services", "wininit", "taskhostw")
    Get-Process | Where-Object { $safeList -notcontains $_.Name -and $_.Id -ne $PID } | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    [System.Windows.Forms.MessageBox]::Show("Unnecessary processes terminated.")
}

function Install-Drivers {
    $driverLinks = @(
        "https://drive.google.com/uc?export=download&id=ID_1",
        "https://drive.google.com/uc?export=download&id=ID_2"
    )

    $tempDir = "$env:TEMP\Drivers"
    if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir }

    foreach ($link in $driverLinks) {
        $fileName = "$tempDir\driver$((Get-Random).ToString()).exe"
        Invoke-WebRequest -Uri $link -OutFile $fileName
        Start-Process $fileName -ArgumentList "/S" -Wait
    }

    [System.Windows.Forms.MessageBox]::Show("Drivers installed successfully.")
}

Add-Type -AssemblyName System.Windows.Forms
Show-Menu
