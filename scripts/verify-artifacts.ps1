#!/usr/bin/env pwsh
# verify-artifacts.ps1
# 校验安装包目录下的文件（哈希 + 大小 + 魔数）
# 用法：
#   .\verify-artifacts.ps1                       # 当前目录
#   .\verify-artifacts.ps1 -Dir D:\downloads       # 指定目录
# 退出码：0 = 全部 PASS；1 = 至少一个 FAIL
# 依赖：Windows PowerShell 5.1+

[CmdletBinding()]
param(
    [string]$Dir = (Get-Location).Path
)
$ErrorActionPreference = 'Continue'
$dirFull = (Resolve-Path $Dir).Path

# 已核实的包哈希表（SHA256 大写）
$expected = @(
    @{ Name='LanguageBreak.tar.gz';         Sha='2D508D7E1F01F5FDF949005225258622F0EA3CADF28B20EC3E83B8174371B190'; Size=162816;  Magic='gz' },
    @{ Name='koreader-kindle-legacy-v2026.07.1.zip'; Sha='0ED8D5EEC422DAD4894DDC426894C260CCE55EC3EE3C0BE9E8A4FE46C45A5CDE'; Size=41418752; Magic='zip' },
    @{ Name='weread.koplugin-v1.6.0.zip';   Sha='647ABCA30FE7638D67C5C24E483409ACDEDAA758194F177863D1385365258D51'; Size=910336;  Magic='zip' },
    @{ Name='kual-mrinstaller.tar.xz';      Sha='36B3C28A44AD1A91609CC82D2BB9836AD6D7125BA1F63596307BF93F17A9255E'; Size=1771008; Magic='xz' },
    @{ Name='BinaryRenamer.zip';            Sha='57B236655955A37C8D72CF09E694EE43FC615799A2D50922A33B1232C1AC30C3'; Size=2765;    Magic='zip' }
)

$magicBytes = @{
    'gz'  = [byte[]](0x1F,0x8B)
    'zip' = [byte[]](0x50,0x4B)
    'xz'  = [byte[]](0xFD,0x37,0x7A,0x58,0x5A,0x00)
}

$results = @()
foreach ($e in $expected) {
    $path = Join-Path $dirFull $e.Name
    $row = [pscustomobject]@{ File=$e.Name; Present=$false; SizeOk=$false; HashOk=$false; MagicOk=$false; Verdict='MISSING' }
    if (-not (Test-Path $path)) { $results += $row; continue }
    $row.Present = $true
    $actual = Get-Item $path
    $row.SizeOk = ($actual.Length -eq $e.Size)
    $hash = (Get-FileHash -Path $path -Algorithm SHA256).Hash.ToUpper()
    $row.HashOk = ($hash -eq $e.Sha)
    # 魔数
    $stream = [System.IO.File]::OpenRead($path)
    $buf = New-Object byte[] ($magicBytes[$e.Magic].Length)
    [void]$stream.Read($buf, 0, $buf.Length)
    $stream.Close()
    $row.MagicOk = -join ($buf | ForEach-Object { $_.ToString('X2') }) -eq -join ($magicBytes[$e.Magic] | ForEach-Object { $_.ToString('X2') })
    $row.Verdict = if ($row.HashOk -and $row.SizeOk -and $row.MagicOk) { 'PASS' } else { 'FAIL' }
    $results += $row
}

Write-Host "=== 安装包校验 ===" -ForegroundColor Cyan
Write-Host "目录: $dirFull"
$results | Format-Table File, Present, SizeOk, HashOk, MagicOk, Verdict -AutoSize
$failCount = ($results | Where-Object { $_.Verdict -ne 'PASS' }).Count
if ($failCount -gt 0) {
    Write-Host "FAIL: $failCount 个文件未通过" -ForegroundColor Red
    exit 1
} else {
    Write-Host "全部 PASS" -ForegroundColor Green
    exit 0
}