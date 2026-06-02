# PreToolUse: Bash — block commits/pushes directly to main
$raw = [Console]::In.ReadToEnd()
$j = $raw | ConvertFrom-Json
$cmd = $j.tool_input.command
if (-not $cmd) { exit 0 }

$blocked = $false
$reason = 'BLOCKED: Never commit or push directly to main. Create a feature branch and open a PR instead.'

if ($cmd -match 'git push.*(origin )?main') {
    $blocked = $true
}
if (-not $blocked -and ($cmd -match 'git commit')) {
    try {
        $branch = & git branch --show-current 2>$null
        if ($branch -eq 'main') { $blocked = $true }
    } catch {}
}

if ($blocked) {
    @{
        hookSpecificOutput = @{
            hookEventName         = 'PreToolUse'
            permissionDecision    = 'deny'
            permissionDecisionReason = $reason
        }
    } | ConvertTo-Json -Compress | Write-Output
}
