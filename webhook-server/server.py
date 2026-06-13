import os
import json
import requests
from flask import Flask, request, jsonify
from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

WHATSAPP_API = os.environ.get("WHATSAPP_API_URL", "http://localhost:8080")
TRIGGER_KEYWORDS = ["booking carrinha"]

# Stores conversation history per chat JID
conversation_histories: dict[str, list] = {}

SYSTEM_PROMPT = """You are a helpful WhatsApp assistant that handles van (carrinha) bookings.
When someone asks about booking a van, collect the following information naturally in conversation:
- Date and time needed
- Pickup location
- Destination
- Number of passengers or type of cargo
- Contact name

Be friendly, concise, and reply in the same language the user is writing in.
Once you have all the details, confirm the booking summary to the user."""


def contains_trigger(text: str) -> bool:
    text_lower = text.lower()
    return any(keyword in text_lower for keyword in TRIGGER_KEYWORDS)


def send_whatsapp_reply(recipient: str, message: str) -> bool:
    try:
        resp = requests.post(
            f"{WHATSAPP_API}/api/send",
            json={"recipient": recipient, "message": message},
            timeout=10,
        )
        return resp.status_code == 200
    except Exception as e:
        print(f"Failed to send WhatsApp reply: {e}")
        return False


def ask_claude(chat_jid: str, user_message: str) -> str:
    history = conversation_histories.setdefault(chat_jid, [])
    history.append({"role": "user", "content": user_message})

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=500,
        system=SYSTEM_PROMPT,
        messages=history,
    )

    reply = response.content[0].text
    history.append({"role": "assistant", "content": reply})

    # Keep only the last 20 messages to avoid token bloat
    if len(history) > 20:
        conversation_histories[chat_jid] = history[-20:]

    return reply


@app.route("/webhook", methods=["POST"])
def webhook():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "invalid payload"}), 400

    chat_jid = data.get("chat_jid", "")
    sender = data.get("sender", "")
    message = data.get("message", "")
    is_from_me = data.get("is_from_me", False)

    # Ignore messages sent by us
    if is_from_me:
        return jsonify({"status": "ignored"}), 200

    print(f"[webhook] From {sender} ({chat_jid}): {message}")

    # Only act on trigger keywords OR ongoing booking conversations
    in_conversation = chat_jid in conversation_histories
    if not contains_trigger(message) and not in_conversation:
        return jsonify({"status": "no trigger"}), 200

    reply = ask_claude(chat_jid, message)
    print(f"[webhook] Claude reply: {reply}")

    # Recipient for reply: use sender JID for direct chats, chat JID for groups
    recipient = chat_jid if "@g.us" in chat_jid else sender
    send_whatsapp_reply(recipient, reply)

    return jsonify({"status": "replied", "reply": reply}), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/conversations", methods=["GET"])
def conversations():
    return jsonify({jid: len(h) for jid, h in conversation_histories.items()}), 200


@app.route("/conversations/<path:chat_jid>", methods=["DELETE"])
def clear_conversation(chat_jid):
    conversation_histories.pop(chat_jid, None)
    return jsonify({"status": "cleared"}), 200


if __name__ == "__main__":
    port = int(os.environ.get("WEBHOOK_PORT", 3000))
    print(f"Webhook server starting on port {port}")
    print(f"Trigger keywords: {TRIGGER_KEYWORDS}")
    app.run(host="0.0.0.0", port=port, debug=False)
