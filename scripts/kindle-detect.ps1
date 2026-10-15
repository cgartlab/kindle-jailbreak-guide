#!/usr/bin/env pwsh

# kindle-detect.ps1
# 探测 Kindle 设备状态，输出 JSON 到 stdout（同时输出人类可读诊断）。
# 用法：
#   .\kindle-detect.ps1                       # 自动扫描盘符 D:~K:
#   .\kindle-detect.ps1 -Drive F:             # 指定盘符
#   .\kindle-detect.ps1 -JsonOnly              # 只输出 JSON
# 退出码：0 = 检测到设备；1 = 未检测到设备；2 = 参数错误
# 依赖：Windows PowerShell 5.1+（UTF-8 with BOM）

[CmdletBinding()]
param(
    [string]$Drive,   # 可选，指定盘符（例如 "F:"）
    [switch]$JsonOnly  # 只输出 JSON，不打人类可读
)

$ErrorActionPreference = 'Continue'
$drivesToScan = @('D:','E:','F:','G:','H:','I:','J:','K:')
$supportedFirmware = '5.16.2.1.1'

function Find-KindleDrive {
    param([string[]]$ScanList)
    foreach ($d in $ScanList) {
        $root = "$d\"
        if (-not (Test-Path $root)) { continue }
        $verPath = Join-Path $root 'system\version.txt'
        if (Test-Path $verPath) { return $d }
    }
    return $null
}

$targetDrive = $null
if ($Drive) {
    if (Test-Path "${Drive}\system\version.txt") { $targetDrive = $Drive.TrimEnd(':', '\') + ':' }
    else { Write-Error "指定盘符 $Drive 无 Kindle 标识"; exit 2 }
} else {
    $targetDrive = Find-KindleDrive
}

if (-not $targetDrive) {
    $err = @{ error = "未检测到 Kindle 设备"; drives_scanned = $drivesToScan } | ConvertTo-Json -Depth 3
    if ($JsonOnly) { $err } else { Write-Error "未检测到 Kindle 设备（确认：设备已插 USB、未运行 KOReader、USB 线能传数据）" }
    exit 1
}

$root = "$targetDrive\"
$verRaw = Get-Content -Path (Join-Path $root 'system\version.txt') -Raw
$firmware = ($verRaw -replace 'Kindle\s+', '' -replace '\s*\(.*\)', '').Trim()
$model = $verRaw.Trim()

# 越狱标记
$checks = @{
    has_mkk =            [bool](Test-Path (Join-Path $root 'mkk'))
    has_LanguageBreakRan = [bool](Test-Path (Join-Path $root 'LanguageBreakRan'))
    has_hotfix_log =     [bool](Test-Path (Join-Path $root 'languagebreak_log'))
    has_KUAL =           [bool](Test-Path (Join-Path $root 'documents\KUAL.kual'))
    has_koreader =        [bool](Test-Path (Join-Path $root 'koreader'))
    has_weread_plugin =   [bool](Test-Path (Join-Path $root 'koreader\plugins\weread.koplugin'))
    has_BinaryRenamer =   [bool](Test-Path (Join-Path $root 'extensions\BinaryRenamer'))
    has_rmgotro =         [bool](Test-Path (Join-Path $root 'system\version.txt'))
}

# .bin 残留
$binFiles = Get-ChildItem -Path $root -Filter '*.bin' -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
$leftover_bins = @($binFiles)

# 空闲空间
$disk = Get-PSDrive ($targetDrive.TrimEnd(':', '\'))
$free_mb = [math]::Round($disk.Free / 1MB, 0)

# 固件守卫
$firmware_ok = ($firmware -eq $supportedFirmware)

$result = [pscustomobject]@{
    drive      = $targetDrive
    firmware   = $firmware
    model      = $model
    firmware_ok = $firmware_ok
    supported_firmware = $supportedFirmware
    free_mb    = $free_mb
    leftover_bins = $leftover_bins
    checks     = $checks
}

$json = $result | ConvertTo-Json -Depth 4
if (-not $JsonOnly) {
    Write-Host '=== Kindle 设备状态 ===' -ForegroundColor Cyan
    Write-Host "盘符: $targetDrive"
    Write-Host "固件: $firmware" -NoNewline
    if ($firmware_ok) { Write-Host "  (已验证支持)" -ForegroundColor Green } else { Write-Host "  (! 不在已验证范围)" -ForegroundColor Yellow }
    Write-Host "空闲: $free_mb MB"
    Write-Host "越狱标记: mkk=$($checks.has_mkk) LanguageBreakRan=$($checks.has_LanguageBreakRan)"
    Write-Host "KUAL: $($checks.has_KUAL) | KOReader: $($checks.has_koreader) | 微信读书: $($checks.has_weread_plugin) | BinaryRenamer: $($checks.has_BinaryRenamer)"
    if ($leftover_bins.Count -gt 0) { Write-Host "残留 .bin: $($leftover_bins -join ', ')" -ForegroundColor Yellow }
}
$json
exit 0