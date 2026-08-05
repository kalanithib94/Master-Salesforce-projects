# Syncs GPTfy_Agent_SystemPrompt_v1.3.0_client.txt onto the "GPTfy Agent"
# record's ccai__System_Prompt__c field.
#
# Usage (from Deliverables folder):
#   powershell -ExecutionPolicy Bypass -File client-package\SyncSystemPromptToGPTfyAgent.ps1 -TargetOrg <alias>
#
# Resolves the agent by Name = "GPTfy Agent" unless -AgentId is supplied.

param(
    [string] $TargetOrg = '',
    [string] $AgentId = '',
    [string] $AgentName = 'GPTfy Agent',
    [string] $SystemPromptPath = '',
    [string] $ApiVersion = 'v66.0'
)

$ErrorActionPreference = 'Stop'

$pkgRoot = $PSScriptRoot
$root = Split-Path -Parent $pkgRoot
if (-not $SystemPromptPath) {
    $SystemPromptPath = Join-Path $pkgRoot 'GPTfy_Agent_SystemPrompt_v1.3.0_client.txt'
}

$tempApex = Join-Path $pkgRoot '_sync_sysprompt.apex'
$tempJson = Join-Path $pkgRoot '_sync_body.json'

if (-not (Test-Path $SystemPromptPath)) {
    throw "System prompt file not found: $SystemPromptPath"
}

$orgArg = if ($TargetOrg) { "--target-org $TargetOrg" } else { '' }

# Resolve agent Id by name when not provided
if (-not $AgentId) {
    $q = "SELECT Id, Name FROM ccai__AI_Agent__c WHERE Name = '$AgentName' LIMIT 1"
    $queryOut = (cmd /c "sf data query --query `"$q`" --json $orgArg 2>&1") | Out-String
    $braceIdx = $queryOut.IndexOf('{')
    $queryJson = if ($braceIdx -ge 0) { $queryOut.Substring($braceIdx) } else { $queryOut }
    $parsed = $queryJson | ConvertFrom-Json
    if (-not $parsed.result.records -or $parsed.result.records.Count -eq 0) {
        throw "No ccai__AI_Agent__c found with Name = '$AgentName'. Run SeedClientSkills.apex first."
    }
    $AgentId = [string]$parsed.result.records[0].Id
    Write-Host "Resolved agent '$AgentName' -> $AgentId"
}

$raw = [System.IO.File]::ReadAllText($SystemPromptPath)
$expectedChars = ($raw -replace "`r`n", "`n").Length

$escaped = $raw -replace '\\', '\\'
$escaped = $escaped -replace "'", "\'"
$escaped = $escaped -replace "`r`n", "`n"
$escaped = $escaped -replace "`r", "`n"
$escaped = $escaped -replace "`n", '\n'

$apex = @"
String SP = '$escaped';
ccai__AI_Agent__c agent = new ccai__AI_Agent__c(
    Id = '$AgentId',
    ccai__System_Prompt__c = SP
);
update agent;
ccai__AI_Agent__c verify = [
    SELECT ccai__System_Prompt__c FROM ccai__AI_Agent__c WHERE Id = '$AgentId' LIMIT 1
];
String stored = verify.ccai__System_Prompt__c == null ? '' : verify.ccai__System_Prompt__c;
Integer storedLen = stored.length();
String localTrim = SP.endsWith('\n') ? SP.removeEnd('\n') : SP;
Integer trimmedLen = localTrim.length();
Boolean exact = (storedLen == SP.length());
Boolean trimmed = (storedLen == trimmedLen) && stored.equals(localTrim);
System.debug('SYSPROMPT_LOCAL_CHARS=' + SP.length());
System.debug('SYSPROMPT_STORED_CHARS=' + storedLen);
System.debug('SYSPROMPT_MATCH=' + (exact || trimmed));
System.debug('SYSPROMPT_MATCH_KIND=' + (exact ? 'exact' : (trimmed ? 'trim-trailing-newline' : 'mismatch')));
"@

[IO.File]::WriteAllText($tempApex, $apex, [Text.UTF8Encoding]::new($false))
$apexBytes = (Get-Item $tempApex).Length
$apexKb = [Math]::Round($apexBytes / 1KB, 2)
Write-Host "Apex script size: $apexKb KB (limit 32 KB). Prompt length: $expectedChars chars (LF-normalised)."

$useRest = $apexBytes -gt 32000
$localChars = -1
$storedChars = -1
$match = 'unknown'
$matchKind = 'unknown'

Push-Location $root
$prevPref = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    if (-not $useRest) {
        Write-Host "`nMode: anonymous-Apex (sf apex run)."
        $relPath = Resolve-Path $tempApex -Relative
        $output = (cmd /c "sf apex run --file `"$relPath`" $orgArg 2>&1") | Out-String
        Write-Host $output
        $localChars = if ($output -match 'SYSPROMPT_LOCAL_CHARS=(\d+)') { [int]$Matches[1] } else { -1 }
        $storedChars = if ($output -match 'SYSPROMPT_STORED_CHARS=(\d+)') { [int]$Matches[1] } else { -1 }
        $match = if ($output -match 'SYSPROMPT_MATCH=(true|false)') { $Matches[1] } else { 'unknown' }
        $matchKind = if ($output -match 'SYSPROMPT_MATCH_KIND=([\w-]+)') { $Matches[1] } else { 'unknown' }
    } else {
        Write-Host "`nMode: REST PATCH (prompt exceeds 32 KB Apex anonymous-script limit)."
        $bodyObj = [pscustomobject]@{ ccai__System_Prompt__c = [string]$raw }
        $body = $bodyObj | ConvertTo-Json -Compress -Depth 2
        [IO.File]::WriteAllText($tempJson, $body, [Text.UTF8Encoding]::new($false))

        $endpoint = "/services/data/$ApiVersion/sobjects/ccai__AI_Agent__c/$AgentId"
        $relJson = Resolve-Path $tempJson -Relative
        $patchOut = (cmd /c "sf api request rest `"$endpoint`" --method PATCH --header `"Content-Type:application/json`" --body `"@$relJson`" $orgArg 2>&1") | Out-String
        Write-Host $patchOut

        if ($LASTEXITCODE -ne 0 -or $patchOut -match 'errorCode' -or $patchOut -match 'Error \(') {
            Write-Warning "REST PATCH failed - inspect output above."
            exit 1
        }

        $verifyOut = (cmd /c "sf data query --query `"SELECT ccai__System_Prompt__c FROM ccai__AI_Agent__c WHERE Id = '$AgentId'`" --json $orgArg 2>&1") | Out-String
        $braceIdx = $verifyOut.IndexOf('{')
        $verifyJson = if ($braceIdx -ge 0) { $verifyOut.Substring($braceIdx) } else { $verifyOut }
        $verify = $verifyJson | ConvertFrom-Json
        $stored = [string]$verify.result.records[0].ccai__System_Prompt__c

        $localChars = ($raw -replace "`r`n", "`n").Length
        $storedChars = $stored.Length
        $marker1 = $raw.Substring(0, [Math]::Min(60, $raw.Length))
        $marker2 = $raw.Substring([Math]::Max(0, $raw.Length - 60))
        $headOk = $stored.Contains($marker1.TrimEnd("`r", "`n"))
        $tailOk = $stored.Contains($marker2.TrimEnd("`r", "`n"))
        if ($headOk -and $tailOk) {
            $match = 'true'
            $matchKind = 'rest-content-match'
        } else {
            $match = 'false'
            $matchKind = 'rest-content-mismatch'
        }
    }
} finally {
    $ErrorActionPreference = $prevPref
    Pop-Location
}

Write-Host ""
Write-Host "RESULT:"
Write-Host "  local chars   = $localChars"
Write-Host "  stored chars  = $storedChars"
Write-Host "  match         = $match  ($matchKind)"

if (Test-Path $tempApex) { Remove-Item $tempApex -Force }
if (Test-Path $tempJson) { Remove-Item $tempJson -Force }

if ($match -ne 'true') {
    Write-Warning "Sync verification did NOT match."
    exit 1
}

Write-Host "`nDone. System prompt synced to agent $AgentId ($AgentName)."
