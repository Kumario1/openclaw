# Continue Installation After Error

## The Issue
Ubuntu 24.04 has stricter Python package management. The script has been fixed.

## Continue Where You Left Off

SSH back into your EC2:

```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231
```

Then run these commands to continue:

```bash
cd ~/openclaw-deploy

# Install httpx properly
sudo apt-get install -y python3-httpx

# Continue with the rest of the installation
sudo ./scripts/install.sh
```

If that still gives errors, try:

```bash
# Alternative: Install with pip using break-system-packages flag
cd ~/openclaw-deploy

# Set backend URL
export BACKEND_URL="http://54.221.139.68:8000"

# Manual setup
mkdir -p ~/openclaw-tools
cp src/backend_client.py ~/openclaw-tools/
chmod +x ~/openclaw-tools/backend_client.py

# Install httpx
pip3 install httpx --break-system-packages

# Copy config
mkdir -p ~/.openclaw/workspace/skills/transition-os
cp config/AGENTS.md ~/.openclaw/workspace/AGENTS.md
cp config/openclaw.json ~/.openclaw/openclaw.json

# Update backend URL in AGENTS.md
sed -i "s|\\\${BACKEND_URL}|$BACKEND_URL|g" ~/.openclaw/workspace/AGENTS.md

# Create skill definition
cat > ~/.openclaw/workspace/skills/transition-os/SKILL.md << 'EOF'
# Transition OS Skill

Tools for interacting with LPL Transition OS backend.

## Available Tools

- `backend_client.py list` - List all households
- `backend_client.py get <id>` - Get household details
- `backend_client.py complete <task_id>` - Complete a task
- `backend_client.py validate <doc_id>` - Validate document
- `backend_client.py meeting <household_id>` - Get meeting pack
- `backend_client.py eta <workflow_id>` - Get ETA prediction

## Environment

BACKEND_URL is set in the environment.
EOF

# Install services
sudo cp scripts/openclaw.service /etc/systemd/system/
sudo cp scripts/clawdbot.service /etc/systemd/system/

# Update backend URL in services
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/openclaw.service
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/clawdbot.service

# Setup Clawdbot
cd /opt/clawdbot
sudo python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn httpx pydantic

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl enable clawdbot

echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Add API keys: sudo nano /etc/environment"
echo "2. Run: openclaw onboard"
echo "3. Start: sudo systemctl start openclaw clawdbot"
```

## Quick Fix (One Command)

```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231 "pip3 install httpx --break-system-packages && cd ~/openclaw-deploy && sudo ./scripts/install.sh"
```
