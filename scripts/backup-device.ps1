#!/usr/bin/env pwsh
# backup-device.ps1
# 整盘备份 Kindle 设备到电脑
# 用法：
#   .\backup-device.ps1                      # 自动扫描 D:~K:，备份到 .\backup\Kindle-YYYY-MM-DD
#   .\backup-device.ps1 -Drive F:            # 指定盘符
#   .\backup-device.ps1 -Drive F: -OutDir D:\MyBackup     # 指定输出目录
# 依赖：Windows PowerShell 5.1+（UTF-8 with BOM）

[CmdletBinding()]
param(
    [string]$Drive,     # 可选，指定盘符（例如 "F:"）
    [string]$OutDir     # 可选，输出目录
)

$ErrorActionPreference = 'Continue'
$scan = @('D:','E:','F:','G:','H:','I:','J:','K:')

function Find-KindleDrive {
    foreach ($d in $scan) {
        if (-not (Test-Path "$d\")) { continue }
        if (Test-Path "$d\system\version.txt") { return $d }
    }
    return $null
}

$targetDrive = $null
if ($Drive) {
    if (Test-Path "$Drive\system\version.txt") { $targetDrive = $Drive.TrimEnd(':', '\') + ':' }
    else {
        Write-Error "指定盘符 $Drive 无 Kindle 标识（system\version.txt）"
        exit 2
    }
} else {
    $targetDrive = Find-KindleDrive
}

if (-not $targetDrive) {
    Write-Error "未检测到 Kindle 设备。确认：① 设备插 USB；② 不在 KOReader 运行状态；③ USB 线可传数据"
    exit 1
}

$date = Get-Date -Format 'yyyy-MM-dd_HHmm'
if ($OutDir) {
    $backupDir = Join-Path $OutDir "Kindle-$date"
} else {
    $backupDir = Join-Path $PSScriptRoot "..\backup\Kindle-$date"
}
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
}

Write-Host "Kindle 设备盘: $targetDrive" -ForegroundColor Green
Write-Host "备份目标: $backupDir" -ForegroundColor Yellow
Write-Host "开始 robocopy（可能 1-5 分钟）..." -ForegroundColor Yellow

& robocopy "$targetDrive\" $backupDir /MIR /FFT /R:2 /W:5 /XJ /XD ".fseventsd" ".Spotlight-V100"
if ($LASTEXITCODE -ge 8) { Write-Error "备份失败，robocopy exit code $LASTEXITCODE"; exit 1 } else { Write-Host "备份完成（exit $LASTEXITCODE）." -ForegroundColor Green } ".Spotlight-V100
