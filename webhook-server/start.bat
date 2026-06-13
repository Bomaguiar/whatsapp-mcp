@echo off
echo Starting WhatsApp Webhook Server...

REM Check if .env exists
if not exist .env (
    echo ERROR: .env file not found!
    echo Please copy .env.example to .env and fill in your ANTHROPIC_API_KEY
    pause
    exit /b 1
)

REM Install dependencies if needed
pip install -r requirements.txt

REM Start the server
python server.py
pause
