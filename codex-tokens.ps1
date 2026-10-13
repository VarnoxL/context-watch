# On-demand context-usage check for Codex CLI, soft target 100k tokens.
# Codex CLI has no statusline hook like Claude Code, so run this manually:
#   powershell -File codex-tokens.ps1
# Override the target with $env:CONTEXT_WATCH_TARGET if 100k isn't your number.
$Esc = [char]27
$target = if ($env:CONTEXT_WATCH_TARGET) { [int]$env:CONTEXT_WATCH_TARGET } else { 100000 }

$latest = Get-ChildItem -Path "$HOME\.codex\sessions" -Recurse -Filter "rollout-*.jsonl" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latest) {
    Write-Host "No Codex session found under ~\.codex\sessions"
    exit 0
}

$tokens = 0
Get-Content $latest.FullName -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $entry = $_ | ConvertFrom-Json
        if ($entry.type -eq "token_count" -and $entry.info.last_token_usage) {
            $tokens = [int]$entry.info.last_token_usage.total_tokens
        }
    } catch {}
}

$pct = [math]::Round(($tokens / $target) * 100)
$barWidth = 10
$filled = [math]::Min($barWidth, [math]::Floor(($tokens / $target) * $barWidth))
$bar = ("#" * $filled) + ("-" * ($barWidth - $filled))
$color = if ($pct -ge 100) { "38;5;196" } elseif ($pct -ge 75) { "38;5;214" } else { "38;5;108" }
$label = "{0:N1}k" -f ($tokens / 1000)
$targetLabel = "{0:N0}k" -f ($target / 1000)

$reminder = if ($tokens -ge $target) { " >>> COMPACT OR START A NEW CHAT <<<" } else { "" }
Write-Host "$($latest.Name)"
[Console]::Write("${Esc}[${color}m[$bar] $label/$targetLabel ($pct%)$reminder${Esc}[0m`n")
