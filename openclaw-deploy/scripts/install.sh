#!/bin/bash
set -e

echo "🤖 Installing OpenClaw + Clawdbot Server for LPL Transition OS..."
echo "================================================================"

# Configuration - UPDATE THIS!
DEFAULT_BACKEND_URL="http://localhost:8000"
BACKEND_URL=${BACKEND_URL:-$DEFAULT_BACKEND_URL}

echo ""
echo "📋 Configuration:"
echo "   Backend URL: $BACKEND_URL"
echo ""

# Update system
echo "📦 Updating packages..."
apt-get update && apt-get upgrade -y

# Install dependencies
echo "📦 Installing Node.js 22+ and Python..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs git python3 python3-pip python3-venv

# Install OpenClaw
echo "📦 Installing OpenClaw..."
npm install -g openclaw@latest

# Create directories
echo "📁 Setting up directories..."
mkdir -p ~/.openclaw/workspace/skills/transition-os
mkdir -p ~/openclaw-tools
mkdir -p /opt/clawdbot

# Copy configuration
echo "⚙️  Copying OpenClaw configuration..."
cp config/AGENTS.md ~/.openclaw/workspace/AGENTS.md
cp config/openclaw.json ~/.openclaw/openclaw.json

# Update backend URL in AGENTS.md
sed -i "s|\${BACKEND_URL}|$BACKEND_URL|g" ~/.openclaw/workspace/AGENTS.md

# Copy and setup backend client tool
echo "⚙️  Setting up backend client..."
cp src/backend_client.py ~/openclaw-tools/
chmod +x ~/openclaw-tools/backend_client.py
pip3 install httpx

# Create skill definition for transition-os
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

# Install OpenClaw systemd service
echo "🔧 Installing OpenClaw systemd service..."
cp scripts/openclaw.service /etc/systemd/system/

# Update backend URL in service file
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/openclaw.service

systemctl daemon-reload
systemctl enable openclaw

# Setup Clawdbot API Server (optional but recommended)
echo "🔧 Setting up Clawdbot API Server..."
cp openclaw/clawdbot_server.py /opt/clawdbot/
cp openclaw/clawdbot_backend_client.py /opt/clawdbot/
cp scripts/clawdbot.service /etc/systemd/system/

# Create Python venv for Clawdbot
cd /opt/clawdbot
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn httpx pydantic

# Update backend URL in Clawdbot service
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/clawdbot.service

systemctl daemon-reload
systemctl enable clawdbot

echo ""
echo "✅ Installation complete!"
echo ""
echo "================================================"
echo "🔧 Next steps:"
echo ""
echo "1. Run OpenClaw onboarding:"
echo "   openclaw onboard"
echo ""
echo "2. Add API keys to /etc/environment:"
echo "   sudo nano /etc/environment"
echo "   ANTHROPIC_API_KEY=sk-ant-..."
echo "   OPENAI_API_KEY=sk-..."
echo ""
echo "3. Start services:"
echo "   sudo systemctl start openclaw    # Port 18789"
echo "   sudo systemctl start clawdbot    # Port 8080"
echo ""
echo "4. Check status:"
echo "   sudo systemctl status openclaw"
echo "   sudo systemctl status clawdbot"
echo ""
echo "5. Test endpoints:"
echo "   curl http://localhost:18789/health"
echo "   curl http://localhost:8080/health"
echo ""
echo "================================================"
echo "🌐 Available Models (configured):"
echo "   - default: claude-sonnet-4"
echo "   - fast: claude-haiku"
echo "   - powerful: claude-opus-4-5"
echo "   - gpt4: gpt-4o"
echo "   - gpt4-mini: gpt-4o-mini"
echo "================================================"
