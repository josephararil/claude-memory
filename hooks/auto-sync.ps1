# Auto-commit and push ~/.claude tracked files after Claude writes a file.
# Replaces the old claude-memory sync.ps1. Runs as a PostToolUse(Write) hook.

$repoPath = "C:\Users\jharari\.claude"

if (!(Test-Path "$repoPath\.git")) { exit 0 }

Set-Location $repoPath

git add -A 2>$null

# Only commit if there are staged changes
git diff --staged --quiet 2>$null
if ($LASTEXITCODE -eq 0) { exit 0 }

git commit -m "auto: sync claude files" --quiet 2>$null
git push origin main --quiet 2>$null

exit 0
