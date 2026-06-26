---
name: whatsapp
description: >
  Full WhatsApp access — read messages, search contacts, send replies, browse chats,
  download media. Use this skill ALWAYS when the user mentions WhatsApp, wants to read
  messages, check chats, search contacts, send a message, find a conversation, reply to
  someone, or asks anything related to their WhatsApp. Triggers on: "check my WhatsApp",
  "send a message to X", "what did X say", "read my messages", "find chat with X",
  "reply to X on WhatsApp", "who messaged me", "show my chats", "any WhatsApp?",
  "check my messages", "what did X send me?", or any request involving WhatsApp.
---

# WhatsApp MCP Skill

This skill gives Claude direct access to the user's WhatsApp via the `whatsapp` MCP server.
The Go bridge must be running locally for tools to work.

## Available Tools

Load tools via ToolSearch if they're deferred — search for "whatsapp" to find all tools.

| Tool | What it does |
|------|-------------|
| `mcp__whatsapp__list_chats` | List recent chats, optionally filtered by name |
| `mcp__whatsapp__list_messages` | Read messages from a chat or search across all chats |
| `mcp__whatsapp__search_contacts` | Search contacts by name or phone number |
| `mcp__whatsapp__send_message` | Send a text message to a contact or group |
| `mcp__whatsapp__get_chat` | Get details about a specific chat |
| `mcp__whatsapp__get_contact_chats` | Get all chats for a specific contact |
| `mcp__whatsapp__get_direct_chat_by_contact` | Find the direct chat with a contact |
| `mcp__whatsapp__get_last_interaction` | Get the last message exchanged with a contact |
| `mcp__whatsapp__get_message_context` | Get context around a specific message |
| `mcp__whatsapp__send_file` | Send a file to a contact or group |
| `mcp__whatsapp__send_audio_message` | Send an audio/voice message |
| `mcp__whatsapp__download_media` | Download media from a message |

## Common Workflows

### Reading recent messages
1. Call `list_chats` with `sort_by: "last_active"` and `limit: 20`
2. Present chats in a clean table with name, last message, and time
3. If the user wants to open a chat, call `list_messages` with that chat's `jid`

### Finding a specific chat
1. Call `list_chats` with a `query` matching the contact/group name
2. Present results and ask which one they want

### Sending a message
1. If you don't have the JID, call `search_contacts` or `list_chats` to find it
2. Call `send_message` with the `jid` as recipient and the message text
3. Confirm the message was sent

### Searching messages
1. Call `list_messages` with a `query` to search across all chats
2. Or use `chat_jid` to search within a specific conversation

## Displaying Results

Present chats and messages in clean, readable tables:

| Chat | Last Message | Time |
|------|-------------|------|
| Name | "message preview..." | Today 12:14 |

## Setup

If tools are unavailable, the WhatsApp bridge is not running. Run `/whatsapp-setup` to configure, or start the bridge manually:

```bash
cd /path/to/whatsapp-mcp/whatsapp-bridge
export CGO_ENABLED=1
go run main.go
```

## Privacy

All messages are stored locally in SQLite. Nothing is sent externally except what the user explicitly asks Claude to read or send.
