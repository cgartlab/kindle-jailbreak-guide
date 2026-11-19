#!/usr/bin/env pwsh
# desensitize-check.ps1
# 扫描仓库文本文件，检查是否残存敏感内容
# 用法：
#   .\scripts\desensitize-check.ps1                  # 扫描当前目录
#   .\scripts\desensitize-check.ps1 -Path D:\path    # 指定目录
# 退出码：0 = 干净；1 = 发现敏感内容
# 依赖：Windows PowerShell 5.1+

[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot "..")
)
$root = (Resolve-Path $Path).Path

# 检查模式（每项：名称 + 正则）
$patterns = [ordered]@{
    # 只匹配“前缀 + 实际值”：文档里单独写成占位符说明的前缀（amzn1_acc、AELMRK）不算泄漏，
    # 否则扫描器会把 AGENTS.md 的规则说明本身判成命中（2026-11 起 CI 一直红）。
    "亚马逊账号标识"        = 'am' + 'zn1[._]acc[A-Za-z0-9._-]{6,}'
    "亚马逊账号ID"         = 'AEL' + 'MRK[A-Z0-9]{4,}'
    "卷序列号（XXXX-XXXX）" = '\b(?!XXXX-XXXX)[A-Z0-9]{4}-[A-Z0-9]{4}\b'
    "本地绝对路径"        = 'C:\\Users\\[^\\]|D:\\3-Resource|d:\\3-Resource'
    "邮箱"               = '@gmail\.com|@qq\.com|@163\.com|@outlook\.com|@hotmail\.com'
    "sk- 前缀 API Key"    = 'sk-[a-zA-Z0-9]{20}'
    "Bearer token"       = 'Bearer\s+\S{20,}'
}

# 扫描的文件类型
$exts = @('*.md','*.yaml','*.yml','*.ps1','.gitignore','.gitattributes')

$files = @()
foreach ($e in $exts) {
    $got = Get-ChildItem -Path $root -Recurse -Include $e -File -ErrorAction SilentlyContinue |
           Where-Object { $_.FullName -notmatch '\\\.git\\' }
    $files += $got
}
$files = $files | Sort-Object -Property FullName -Unique

# 需要大小写敏感匹配的规则：卷序列号只用大写，若按默认不区分大小写，
# 任何形如 xxxx-xxxx 的小写片段（kual-mrinstaller、verify-artifacts）都会被误判。
$caseSensitiveRules = @('卷序列号（XXXX-XXXX）')

$hasHit = $false
foreach ($f in $files) {
    foreach ($k in $patterns.Keys) {
        $splat = @{ Path = $f.FullName; Pattern = $patterns[$k]; ErrorAction = 'SilentlyContinue' }
        if ($caseSensitiveRules -contains $k) { $splat['CaseSensitive'] = $true }
        $hits = Select-String @splat
        if ($hits) {
            $hasHit = $true
            foreach ($h in $hits) {
                Write-Host ("[FAIL] {0}:{1} [{2}]" -f (Resolve-Path -Relative $h.Path), $h.LineNumber, $k) -ForegroundColor Red
            }
        }
    }
}

if ($hasHit) {
    Write-Host ""
    Write-Host "脱敏检查：发现敏感内容，需要清理后重新提交。" -ForegroundColor Red
    exit 1
} else {
    Write-Host "脱敏检查：全部干净，没有敏感内容。" -ForegroundColor Green
    exit 0
}