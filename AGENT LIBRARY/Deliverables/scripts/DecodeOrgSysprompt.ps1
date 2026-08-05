# Reads _orgsp_b64.log, joins all ORG_SYSPROMPT_B64_<i>_<n>:<chunk> lines in order,
# base64-decodes, and writes the result to docs/system-prompt-versions/<output>.txt

param(
    [Parameter(Mandatory = $true)] [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$logPath = Join-Path $root '_orgsp_b64.log'
if (-not (Test-Path $logPath)) {
    throw "Log file not found: $logPath. Run scripts/PullOrgSystemPrompt.apex first."
}

$content = Get-Content -Path $logPath -Raw -Encoding UTF8

# Match every "ORG_SYSPROMPT_B64_<i>_<n>:<base64>" occurrence (multi-line possible)
$pattern = 'ORG_SYSPROMPT_B64_(\d+)_(\d+):([A-Za-z0-9+/=]+)'
$rxMatches = [regex]::Matches($content, $pattern)

if ($rxMatches.Count -eq 0) {
    throw "No base64 chunks found in $logPath"
}

# Group by part total to ensure all parts present
$expectedTotal = [int]$rxMatches[0].Groups[2].Value
$indexed = @{}
foreach ($m in $rxMatches) {
    $idx = [int]$m.Groups[1].Value
    $indexed[$idx] = $m.Groups[3].Value
}
$missing = @()
for ($i = 0; $i -lt $expectedTotal; $i++) {
    if (-not $indexed.ContainsKey($i)) { $missing += $i }
}
if ($missing.Count -gt 0) {
    throw "Missing base64 chunks: $($missing -join ', ') of $expectedTotal"
}

# Concatenate in order
$b64 = ''
for ($i = 0; $i -lt $expectedTotal; $i++) { $b64 += $indexed[$i] }

# Decode
$bytes = [Convert]::FromBase64String($b64)
$text  = [Text.Encoding]::UTF8.GetString($bytes)

$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
[IO.File]::WriteAllText($OutputPath, $text, [Text.UTF8Encoding]::new($false))

$len = $text.Length
$sz  = (Get-Item $OutputPath).Length
Write-Host "Wrote $OutputPath  chars=$len bytes=$sz"
