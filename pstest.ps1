Add-Type -AssemblyName PresentationFramework

function Show-Menu {
    $choices = [System.Windows.MessageBoxButton]::YesNoCancel
    $result = [System.Windows.MessageBox]::Show("Выберите действие:
1. Точка восстановления
2. Отключить автозагрузку
3. Завершить ненужные процессы
4. Установить драйверы
5. Перезагрузка
6. Восстановление системы", "Меню", "OKCancel")

    $menu = New-Object System.Windows.Forms.Form
    $menu.Text = "Меню обслуживания"
    $menu.Size = New-Object System.Drawing.Size(400,400)
    $menu.StartPosition = "CenterScreen"

    $buttons = @(
        "Создать точку восстановления",
        "Отключить автозагрузку",
        "Завершить процессы",
        "Установить драйверы",
        "Перезагрузить",
        "Восстановление системы"
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
        "Создать точку восстановления" {
            Check-RestoreEnabled
            CheckAndCreate-RestorePoint
        }
        "Отключить автозагрузку" {
            Disable-Autostart
        }
        "Завершить процессы" {
            Kill-UnnecessaryProcesses
        }
        "Установить драйверы" {
            Install-Drivers
        }
        "Перезагрузить" {
            Restart-Computer -Force
        }
        "Восстановление системы" {
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
    Checkpoint-Computer -Description "Точка перед обслуживанием" -RestorePointType "MODIFY_SETTINGS"
    [System.Windows.Forms.MessageBox]::Show("Точка восстановления создана.")
}

function Disable-Autostart {
    Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" | 
        ForEach-Object {
            if ($_ -isnot [System.String]) {
                Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.PSChildName
            }
        }
    [System.Windows.Forms.MessageBox]::Show("Автозагрузка отключена.")
}

function Kill-UnnecessaryProcesses {
    $safeList = @("explorer", "powershell", "System", "svchost", "lsass", "winlogon", "csrss", "smss", "services", "wininit", "taskhostw")
    Get-Process | Where-Object { $safeList -notcontains $_.Name -and $_.Id -ne $PID } | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    [System.Windows.Forms.MessageBox]::Show("Ненужные процессы завершены.")
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

    [System.Windows.Forms.MessageBox]::Show("Драйверы установлены.")
}

Add-Type -AssemblyName System.Windows.Forms
Show-Menu
