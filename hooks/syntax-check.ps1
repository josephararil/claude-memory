# PostToolUse: Edit|Write — syntax-check JS/TS files after every save
$raw = [Console]::In.ReadToEnd()
$j = $raw | ConvertFrom-Json
$f = $j.tool_input.file_path
if ($f -and ($f -match '\.(js|ts|jsx|tsx)$')) {
    node --check $f 2>&1 | Out-Null
}
