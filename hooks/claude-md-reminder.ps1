# PostToolUse: Bash — remind to update CLAUDE.md after git commit
$raw = [Console]::In.ReadToEnd()
$j = $raw | ConvertFrom-Json
$cmd = $j.tool_input.command
if ($cmd -and ($cmd -match 'git commit')) {
    Write-Output '{"systemMessage": "REMINDER: Did you update CLAUDE.md to reflect this change?"}'
}
