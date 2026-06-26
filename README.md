# WhatsApp MCP Server + Live Bot for Claude Code

A complete WhatsApp integration for Claude Code — read messages, send replies, and run a **live personal assistant bot** from your phone.

Built on the [whatsmeow](https://github.com/tulir/whatsmeow) library, connecting to your personal WhatsApp via the multi-device API. All messages stored locally in SQLite — nothing leaves your machine unless you ask Claude to read or send.

> Fork of [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp) with added **live message forwarding**, **wake/sleep bot**, and **Claude Code hook integration**.

## What You Get

### MCP Tools (pull-based)
Ask Claude to interact with your WhatsApp anytime:
- `search_contacts` — find contacts by name or number
- `list_chats` / `get_chat` — browse conversations
- `list_messages` — read messages with filters and context
- `send_message` — send text to any contact or group
- `send_file` / `send_audio_message` — send media
- `download_media` — download images, videos, docs from messages

### Live Bot (push-based)
Send commands from your phone and get replies in WhatsApp — no need to open Claude Code:

1. Send `wake_bot` to yourself on WhatsApp
2. Claude replies with a command menu
3. Send commands, get instant replies
4. Send `sleep_bot` to deactivate

**Zero tokens while sleeping** — the watcher is a shell script, not an LLM call.

### Command Menu
```
🤖 Claude · Personal Assistant
━━━━━━━━━━━━━━━━━━━━━

💻 Terminal
! <command> → run on PC

📋 ClickUp
cu tasks → all open tasks
cu tasks <project> → filter by project
cu done <task> → mark as ✅
cu add <task> in <list> → create new

📅 Calendar
cal today → today's agenda
cal week → this week
cal add <event> → create event

📧 Email
mail inbox → recent emails
mail from <name> → from someone
mail search <subject> → search

🧠 AI
? <question> → direct answer
📎 send image/doc → auto-describe

⚙️ System
@help → this menu
@memory → what I know this session
sleep_bot → put me to sleep 💤
```

> Commands depend on what MCP servers you have connected (ClickUp, Google Calendar, Gmail, etc). Customize the menu in your CLAUDE.md.

## Architecture

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────┐
│  Your Phone  │────▶│  Go Bridge       │────▶│  SQLite DB  │
│  (WhatsApp)  │◀────│  (whatsmeow)     │     │  (messages) │
└──────────────┘     └───────┬──────────┘     └──────┬──────┘
                             │ writes                │ reads
                     ┌───────▼──────────┐     ┌──────▼──────┐
                     │  incoming.jsonl  │     │  Python MCP │
                     │  (signal file)   │     │  Server     │
                     └───────┬──────────┘     └──────┬──────┘
                             │ polls                 │ tools
                     ┌───────▼──────────┐     ┌──────▼──────┐
                     │  watch-messages  │     │  Claude     │
                     │  (bash hook)     │────▶│  Code       │
                     └──────────────────┘     └─────────────┘
```

1. **Go Bridge** receives WhatsApp messages in real-time via whatsmeow
2. Messages are stored in **SQLite** (for MCP tools to query)
3. Incoming messages matching the command chat are written to **incoming.jsonl**
4. **watch-messages.sh** polls the file every 3 seconds
5. On new message → exits with code 2 → **Claude Code wakes** via asyncRewake hook
6. Claude processes the command and replies via the MCP `send_message` tool

## Installation

### Prerequisites

- **Go** 1.21+ — [go.dev/dl](https://go.dev/dl/)
- **Python** 3.11+ — [python.org](https://www.python.org/)
- **uv** (Python package manager) — `pip install uv`
- **Claude Code** desktop app — [claude.ai/code](https://claude.ai/code)
- **Windows only:** A C compiler (TDM-GCC recommended) — [jmeubank.github.io/tdm-gcc](https://jmeubank.github.io/tdm-gcc/)
- **FFmpeg** _(optional)_ — only needed for voice message conversion

### Step 1: Clone and Build

```bash
git clone https://github.com/YOUR_USERNAME/whatsapp-mcp.git
cd whatsapp-mcp
```

**Build the Go bridge:**

```bash
cd whatsapp-bridge

# Linux/macOS:
go run main.go

# Windows (CGO required for SQLite):
set CGO_ENABLED=1
go run main.go
```

Scan the **QR code** with WhatsApp → Settings → Linked Devices → Link a Device.

**Install Python MCP server:**

```bash
cd ../whatsapp-mcp-server
uv sync --python python
```

### Step 2: Configure Claude Code MCP

Add to your Claude Code MCP config:

```json
{
  "mcpServers": {
    "whatsapp": {
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/whatsapp-mcp/whatsapp-mcp-server",
        "run",
        "main.py"
      ]
    }
  }
}
```

Or add it via CLI:
```bash
claude mcp add whatsapp -- uv --directory /path/to/whatsapp-mcp/whatsapp-mcp-server run main.py
```

### Step 3: Set Up Live Bot (Optional)

To enable the wake/sleep bot with live WhatsApp commands:

#### 3a. Find Your Self-Chat JID

Run the bridge and send yourself a message. Look at the terminal output:
```
[2026-06-26 14:04:35] → 266064751554576: test
```

The sender ID is your LID. Your self-chat JID is `{LID}@lid` (e.g., `266064751554576@lid`).

#### 3b. Set Environment Variables

```bash
# The JID of your self-chat (command channel)
export WHATSAPP_COMMAND_CHAT="266064751554576@lid"

# Your phone number for replies (with country code, no +)
export WHATSAPP_REPLY_NUMBER="351915873259"

# Bridge directory (auto-detected if not set)
export WHATSAPP_BRIDGE_DIR="/path/to/whatsapp-mcp/whatsapp-bridge"
```

#### 3c. Add Claude Code Hook

Add this to your `~/.claude/settings.json` under `"hooks"`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/whatsapp-mcp/watch-messages.sh",
            "asyncRewake": true,
            "rewakeMessage": "INCOMING WHATSAPP MESSAGES"
          }
        ]
      }
    ]
  }
}
```

#### 3d. Add Bot Instructions to CLAUDE.md

Add the command reference to your project's `CLAUDE.md` so Claude knows how to handle incoming commands. See [CLAUDE.md.example](./CLAUDE.md.example) for a template.

#### 3e. Auto-Approve WhatsApp Tools

Add to your `~/.claude/settings.json` under `"permissions"`:

```json
{
  "permissions": {
    "allow": [
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
  }
}
```

### Step 4: Start Everything

1. **Start the bridge** (keep this terminal open):
   ```bash
   cd whatsapp-bridge
   go run main.go
   ```

2. **Open Claude Code** — the MCP server and watcher hook start automatically.

3. **Send `wake_bot`** to yourself on WhatsApp — Claude replies with the menu!

## Windows Quick Start

For Windows users, a startup script is included:

```powershell
# One-click start:
.\start-whatsapp-bridge.bat
```

To auto-start on boot: copy `start-whatsapp-bridge.bat` to your Windows Startup folder (`Win+R` → `shell:startup`).

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `WHATSAPP_COMMAND_CHAT` | _(none — all chats forwarded)_ | JID of the chat to listen for commands |
| `WHATSAPP_REPLY_NUMBER` | _(none)_ | Phone number to send replies to |
| `WHATSAPP_BRIDGE_DIR` | _(auto-detected)_ | Path to the whatsapp-bridge directory |

## Scheduled Tasks

You can create Claude Code scheduled tasks that use the WhatsApp MCP to send automated reports:

```
Daily school group summary → sends to WhatsApp at 8am
Weekly payment check → sends to WhatsApp every Monday
```

See the Claude Code [scheduled tasks docs](https://docs.anthropic.com/en/docs/claude-code) for setup.

## Troubleshooting

### Bridge crashes immediately
- **Windows:** Make sure CGO is enabled and TDM-GCC is installed
- Check that the `store/` directory is writable

### Messages not appearing in incoming.jsonl
- Verify `WHATSAPP_COMMAND_CHAT` matches your actual self-chat JID
- Check the bridge terminal output — your LID may differ from your phone number
- Self-chat messages have `isFromMe=true` — the bridge handles this correctly

### Hook doesn't wake Claude
- Verify `watch-messages.sh` is executable: `chmod +x watch-messages.sh`
- Check `~/.claude/settings.json` has the `Stop` hook with `asyncRewake: true`
- Test manually: `echo '{"text":"wake_bot"}' > whatsapp-bridge/incoming.jsonl && bash watch-messages.sh`

### QR code doesn't appear
- Delete `store/whatsapp.db` and restart the bridge
- Check your WhatsApp → Linked Devices — remove old entries if at the limit

### WhatsApp client outdated (405 error)
- Update whatsmeow: `cd whatsapp-bridge && go get go.mau.fi/whatsmeow@latest && go mod tidy`

## Security

- All messages stored **locally** in SQLite — nothing sent externally
- The bridge connects via WhatsApp's official multi-device API
- The watcher script runs locally as a shell process
- Claude only accesses messages through MCP tools you explicitly approve
- **Caution:** As with any MCP server, be aware of [the lethal trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) — prompt injection could lead to data exfiltration

## Credits

- Original MCP server by [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp)
- WhatsApp API by [whatsmeow](https://github.com/tulir/whatsmeow)
- Live bot integration by [Bomaguiar](https://github.com/Bomaguiar)

## License

MIT
