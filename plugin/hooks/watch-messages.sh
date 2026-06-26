#!/bin/bash
# WhatsApp Live Message Watcher for Claude Code
# Polls incoming.jsonl for new messages and wakes Claude via asyncRewake hook

BRIDGE_DIR="${WHATSAPP_BRIDGE_DIR:-$(dirname "$(readlink -f "$0")")/whatsapp-bridge}"
SIGNAL_FILE="${BRIDGE_DIR}/incoming.jsonl"
PROCESSED_FILE="${BRIDGE_DIR}/incoming.processed"
STATE_FILE="${BRIDGE_DIR}/bot.state"
REPLY_NUMBER="${WHATSAPP_REPLY_NUMBER:-}"

# Get last processed line count
if [ -f "$PROCESSED_FILE" ]; then
    LAST_LINE=$(cat "$PROCESSED_FILE")
else
    LAST_LINE=0
    echo "0" > "$PROCESSED_FILE"
fi

process_messages() {
    local NEW_MSGS="$1"

    # Re-read state
    local BOT_STATE="asleep"
    if [ -f "$STATE_FILE" ]; then
        BOT_STATE=$(cat "$STATE_FILE")
    fi

    local REPLY_INSTRUCTION=""
    if [ -n "$REPLY_NUMBER" ]; then
        REPLY_INSTRUCTION="\nProcess this command and reply to ${REPLY_NUMBER}. First send 👀 to acknowledge, then the full reply. Do NOT ask for permission, just act."
    fi

    if echo "$NEW_MSGS" | grep -qi "wake_bot"; then
        echo "awake" > "$STATE_FILE"
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"INCOMING WHATSAPP MESSAGES - BOT ACTIVATED:\nUser sent wake_bot. Send the assistant menu to ${REPLY_NUMBER} and start processing commands. Do NOT ask for permission, just act.\"}}"
        exit 2
    fi

    if echo "$NEW_MSGS" | grep -qi "sleep_bot"; then
        echo "asleep" > "$STATE_FILE"
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"INCOMING WHATSAPP MESSAGES - BOT DEACTIVATED:\nUser sent sleep_bot. Send goodbye message to ${REPLY_NUMBER}: 🤖 Bot going to sleep. Send *wake_bot* to wake me up! 💤\"}}"
        exit 2
    fi

    if [ "$BOT_STATE" = "awake" ]; then
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"INCOMING WHATSAPP MESSAGES:\n${NEW_MSGS}${REPLY_INSTRUCTION}\"}}"
        exit 2
    fi
}

# Poll for new messages
while true; do
    if [ -f "$SIGNAL_FILE" ]; then
        CURRENT_COUNT=$(wc -l < "$SIGNAL_FILE" | tr -d ' ')

        if [ "$CURRENT_COUNT" -gt "$LAST_LINE" ]; then
            NEW_MSGS=$(tail -n +"$((LAST_LINE + 1))" "$SIGNAL_FILE")
            LAST_LINE=$CURRENT_COUNT
            echo "$LAST_LINE" > "$PROCESSED_FILE"
            process_messages "$NEW_MSGS"
        fi
    fi

    sleep 3
done
