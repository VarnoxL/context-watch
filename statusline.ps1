# Claude Code statusline: context-window usage bar, soft target 100k tokens.
# Install: point ~/.claude/settings.json -> statusLine.command at this file.
# Override the target with $env:CONTEXT_WATCH_TARGET if 100k isn't your number.
#
# If the ponytail plugin (github.com/DietrichGebert/ponytail) is active, its
# badge is shown too -- harmless no-op if you don't have it.
$Esc = [char]27
$stdin = [Console]::In.ReadToEnd()
$data = $null
try { $data = $stdin | ConvertFrom-Json } catch {}

# --- ponytail badge (optional, mirrors the ponytail plugin's own statusline hook) ---
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$Flag = Join-Path $ClaudeDir ".ponytail-active"
if (Test-Path $Flag) {
    $Mode = (Get-Content $Flag -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
    if ([string]::IsNullOrEmpty($Mode) -or $Mode -eq "full") {
        [Console]::Write("${Esc}[38;5;108m[PONYTAIL]${Esc}[0m ")
    } else {
        [Console]::Write("${Esc}[38;5;108m[PONYTAIL:$($Mode.ToUpperInvariant())]${Esc}[0m ")
    }
}

# --- context-window usage bar ---
$target = if ($env:CONTEXT_WATCH_TARGET) { [int]$env:CONTEXT_WATCH_TARGET } else { 100000 }
$tokens = 0
try {
    $transcriptPath = $data.transcript_path
    if ($transcriptPath -and (Test-Path $transcriptPath)) {
        $lastUsage = $null
        Get-Content $transcriptPath -Tail 80 -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $entry = $_ | ConvertFrom-Json
                if ($entry.message.usage) { $lastUsage = $entry.message.usage }
            } catch {}
        }
        if ($lastUsage) {
            $tokens = [int]$lastUsage.input_tokens + [int]$lastUsage.cache_creation_input_tokens + `
                      [int]$lastUsage.cache_read_input_tokens + [int]$lastUsage.output_tokens
        }
    }
} catch {}

$pct = [math]::Round(($tokens / $target) * 100)
$barWidth = 10
$filled = [math]::Min($barWidth, [math]::Floor(($tokens / $target) * $barWidth))
$bar = ("#" * $filled) + ("-" * ($barWidth - $filled))
$color = if ($pct -ge 100) { "38;5;196" } elseif ($pct -ge 75) { "38;5;214" } else { "38;5;108" }
$label = "{0:N1}k" -f ($tokens / 1000)
$targetLabel = "{0:N0}k" -f ($target / 1000)

$reminder = if ($tokens -ge $target) { " >>> COMPACT OR START A NEW CHAT <<<" } else { "" }
[Console]::Write("${Esc}[${color}m[$bar] $label/$targetLabel ($pct%)$reminder${Esc}[0m")
