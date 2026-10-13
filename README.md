# context-watch

A context-window usage bar for AI coding agents, with a soft target (default
100k tokens) and a reminder to compact or start a new chat once you cross it.

```
[#########-] 97.2k/100k (97%)
[##########] 103.4k/100k (103%) >>> COMPACT OR START A NEW CHAT <<<
```

Windows / PowerShell only for now.

## Claude Code

Shows live in the statusline on every turn, reading real per-turn token usage
straight out of your session transcript.

1. Copy `statusline.ps1` somewhere stable, e.g. `~/.claude/statusline.ps1`.
2. Add to `~/.claude/settings.json`:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\you\\.claude\\statusline.ps1\""
     }
   }
   ```

## Codex CLI

Codex CLI has no statusline hook to attach to, so this is run on demand. It
reads your most recent session's token usage from `~/.codex/sessions`.

```
powershell -ExecutionPolicy Bypass -File codex-tokens.ps1
```

## Changing the target

Both scripts default to 100,000 tokens. Override with an environment
variable if you want a different ceiling:

```
$env:CONTEXT_WATCH_TARGET = 150000
```

## Why not other agents (Cursor, Windsurf, ...)?

They don't expose token usage via any file or API today, so there's no real
data to show — only guessed numbers, which this tool won't fake.
