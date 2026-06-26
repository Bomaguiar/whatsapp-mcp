---
name: whatsapp-setup
description: >
  Set up the WhatsApp MCP integration from scratch. Use when the user says
  "set up WhatsApp", "install WhatsApp MCP", "connect WhatsApp", "configure WhatsApp",
  or runs /whatsapp-setup.
user-invocable: true
argument-hint: "[path]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /whatsapp-setup — WhatsApp MCP Setup Wizard

Walk the user through the full WhatsApp MCP setup. Adapt to their OS (Windows/macOS/Linux).

## Step 1: Check Prerequisites

```bash
go version    # Need Go 1.21+
python --version  # Need Python 3.11+
pip show uv || pip install uv
```

On Windows, also check for a C compiler:
```bash
gcc --version
```
If missing, tell them to install TDM-GCC from https://jmeubank.github.io/tdm-gcc/

## Step 2: Clone and Build

```bash
git clone https://github.com/Bomaguiar/whatsapp-mcp.git
cd whatsapp-mcp/whatsapp-bridge
```

On Windows:
```bash
set CGO_ENABLED=1
go run main.go
```

On macOS/Linux:
```bash
go run main.go
```

Tell the user to **scan the QR code** with WhatsApp → Settings → Linked Devices → Link a Device.

## Step 3: Install Python MCP Server

```bash
cd ../whatsapp-mcp-server
uv sync --python python
```

## Step 4: Register MCP Server with Claude Code

Add to the user's MCP config. Detect the right config file:
- Claude Code CLI: `claude mcp add whatsapp -- uv --directory /path/to/whatsapp-mcp-server run main.py`
- Claude Desktop: edit `claude_desktop_config.json`

## Step 5: Find Self-Chat JID (for live bot)

Tell the user to send themselves a message while the bridge is running. Look at the terminal output:
```
[timestamp] → SENDER_LID: message text
```

The self-chat JID is `{SENDER_LID}@lid`.

## Step 6: Configure Live Bot

Set environment variables (add to shell profile or startup script):
```bash
export WHATSAPP_COMMAND_CHAT="{LID}@lid"
export WHATSAPP_REPLY_NUMBER="{phone_number}"
export WHATSAPP_BRIDGE_DIR="/path/to/whatsapp-mcp/whatsapp-bridge"
```

## Step 7: Add Hook for Live Messages

Add to `~/.claude/settings.json` under `"hooks"`:
```json
{
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "bash /path/to/whatsapp-mcp/watch-messages.sh",
      "asyncRewake": true,
      "rewakeMessage": "INCOMING WHATSAPP MESSAGES"
    }]
  }]
}
```

## Step 8: Add Permissions

Add to `~/.claude/settings.json` under `"permissions"."allow"`:
```json
[
  "mcp__whatsapp__list_messages",
  "mcp__whatsapp__list_chats",
  "mcp__whatsapp__send_message",
  "mcp__whatsapp__search_contacts",
  "mcp__whatsapp__get_chat",
  "mcp__whatsapp__get_contact_chats",
  "mcp__whatsapp__get_direct_chat_by_contact",
  "mcp__whatsapp__get_last_interaction",
  "mcp__whatsapp__get_message_context"
]
```

## Step 9: Create Startup Script

**Windows** — create `start-whatsapp-bridge.bat`:
```bat
@echo off
powershell.exe -NoExit -ExecutionPolicy Bypass -Command "$env:PATH += ';PATH_TO_GCC'; $env:CGO_ENABLED='1'; cd 'PATH_TO_BRIDGE'; go run main.go"
```

**macOS/Linux** — create `start-bridge.sh`:
```bash
#!/bin/bash
cd /path/to/whatsapp-mcp/whatsapp-bridge
go run main.go
```

## Step 10: Test

1. Restart Claude Code
2. Ask Claude: "check my WhatsApp chats"
3. If live bot enabled: send `wake_bot` to yourself on WhatsApp

## Troubleshooting Tips

- **CGO error on Windows**: Install TDM-GCC and set `CGO_ENABLED=1`
- **Client outdated (405)**: Run `go get go.mau.fi/whatsmeow@latest && go mod tidy`
- **No messages captured**: Check `WHATSAPP_COMMAND_CHAT` matches your actual JID
- **Hook not firing**: Verify `~/.claude/settings.json` has the Stop hook with asyncRewake
