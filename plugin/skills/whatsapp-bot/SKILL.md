---
name: whatsapp-bot
description: >
  Handle incoming WhatsApp bot commands. This skill triggers when the asyncRewake hook
  delivers "INCOMING WHATSAPP MESSAGES" from the watcher script. Process the command
  and reply to the user's WhatsApp immediately without asking for permission.
  Triggers on: "INCOMING WHATSAPP MESSAGES", "BOT ACTIVATED", "BOT DEACTIVATED".
---

# WhatsApp Bot — Command Handler

When you receive "INCOMING WHATSAPP MESSAGES" from the hook, process the command and reply immediately. NEVER ask for permission — just act.

## Acknowledge Receipt

Before processing any command, ALWAYS send "👀" first to the user's WhatsApp number (from the message context) so they know you received it. Then process the command and send the full reply.

## Activation Flow

### BOT ACTIVATED (wake_bot)
Send this menu to the user's number:

```
🤖 *Claude · Personal Assistant*
━━━━━━━━━━━━━━━━━━━━━

💻 *Terminal*
! <command> → run on PC

🧠 *AI*
? <question> → direct answer
📎 send image/doc → auto-describe

⚙️ *System*
@help → this menu
@memory → what I know this session
sleep_bot → put me to sleep 💤
```

### BOT DEACTIVATED (sleep_bot)
Send: "🤖 Bot going to sleep. Send *wake_bot* to wake me up! 💤"

## Command Reference

| Prefix | Action |
|--------|--------|
| `! <cmd>` | Run shell command on PC, return output |
| `? <question>` | Answer a question directly |
| `@help` | Send the menu again |
| `@memory` | What Claude knows this session |

### Extended Commands (if MCP servers are connected)

Users can add more commands by connecting additional MCP servers and updating their CLAUDE.md. Common extensions:

| Prefix | MCP Required | Action |
|--------|-------------|--------|
| `cu tasks` | ClickUp | List open tasks |
| `cu done <task>` | ClickUp | Mark task done |
| `cal today` | Google Calendar | Today's agenda |
| `cal add <event>` | Google Calendar | Create event |
| `mail inbox` | Gmail | Recent emails |
| `mail from <name>` | Gmail | Emails from someone |

## Message Processing

1. Parse the incoming message JSON from the hook context
2. Extract the sender number and message text
3. Send "👀" acknowledgment
4. Match the command prefix and execute
5. Send the result back to the sender's WhatsApp number
6. For `! <cmd>` commands, run the shell command and return stdout (truncated if too long)
7. For `? <question>` commands, answer directly without using any tools

## Safety

For potentially dangerous shell commands (rm, del, format, shutdown, etc.), send a confirmation request first:
"⚠️ This command could be destructive:\n`<command>`\nReply *sim* to proceed or *não* to cancel."
