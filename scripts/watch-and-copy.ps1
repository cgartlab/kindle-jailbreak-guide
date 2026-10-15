#!/usr/bin/env pwsh
# watch-and-copy.ps1
# 轮询盘符：盘一出现就自动 robocopy，抢时间步骤自动化
# 用法：
#   .\watch-and-copy.ps1 -Src "C:\path\LanguageBreak" -Dest F:
#   .\watch-and-copy.ps1 -Src C:\src -Dest ""        # 自动探测所有常见盘符
# 依赖：Windows PowerShell 5.1+（UTF-8 with BOM）

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$Src,    # 源目录
    [string]$Dest = ""                          # 目标盘符或根路径；空则自动扫 D:~K:
)

$ErrorActionPreference = 'Continue'
$poll = 500   # 毫秒

if (-not (Test-Path $Src)) {
    Write-Error "源目录不存在: $Src"
    exit 2
}
$srcFull = (Resolve-Path $Src).Path.TrimEnd('\','/')

$scan = @('D:','E:','F:','G:','H:','I:','J:','K:')

function Find-Target {
    foreach ($d in $scan) {
        $root = "$d\"
        if (-not (Test-Path $root)) { continue }
        if (Test-Path "$root\system\version.txt") { return $root }
    }
    return $null
}

function Do-Copy {
    param([string]$DestRoot)
    Write-Host "盘符出现: $DestRoot" -ForegroundColor Green
    Write-Host "开始 robocopy..." -ForegroundColor Yellow
    & robocopy $srcFull $DestRoot /E /IS /IT /R:1 /W:1
    if ($LASTEXITCODE -ge 8) { Write-Error "robocopy 失败 exitcode $LASTEXITCODE"; exit 1 }
    Write-Host "拷贝完成" -ForegroundColor Green
    Write-Host "请务必 sha256 复核<rfl:parameter name="srcFull -Destination $DestRoot"
    exit 0
}

if ($Dest -ne "") {
    if (-not (Test-Path "$Dest\")) {
        Write-Host "等待目标盘 $Dest 出现..." -ForegroundColor Yellow
    }
    while (-not (Test-Path "$Dest\")) {
        Start-Sleep -Milliseconds $poll
    }
    Do-Copy -DestRoot "$Dest\"
} else {
    Write-Host "等待 Kindle 盘符出现（轮询 $($scan -join ', ')）..." -ForegroundColor Yellow
    while ($true) {
        $target = Find-Target
        if ($target) { Do-Copy -DestRoot $target }
        Start-Sleep -Milliseconds $poll
    }
}