#!/bin/bash
set -e

echo "🤖 Installing OpenClaw for LPL Transition OS..."
echo "================================================"

# Update system
echo "📦 Updating packages..."
apt-get update && apt-get upgrade -y

# Install dependencies
echo "📦 Installing Node.js and dependencies..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs git python3 python3-pip

# Install OpenClaw
echo "📦 Installing OpenClaw..."
npm install -g openclaw@latest

# Create directories
echo "📁 Setting up directories..."
mkdir -p ~/.openclaw/workspace/skills/transition-os
mkdir -p ~/openclaw-tools

# Copy configuration
echo "⚙️  Copying configuration..."
cp config/AGENTS.md ~/.openclaw/workspace/AGENTS.md
cp config/openclaw.json ~/.openclaw/openclaw.json

# Copy backend client tool
cp src/backend_client.py ~/openclaw-tools/
chmod +x ~/openclaw-tools/backend_client.py
pip3 install httpx

# Install systemd service
echo "🔧 Installing systemd service..."
cp scripts/openclaw.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable openclaw

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Set your backend URL:"
echo "   export BACKEND_URL=http://YOUR_BACKEND_IP:8000"
echo ""
echo "2. Update configuration:"
echo "   sed -i \"s|CHANGE_ME_BACKEND_IP:8000|\$BACKEND_URL|g\" ~/.openclaw/workspace/AGENTS.md"
echo "   sudo sed -i \"s|CHANGE_ME:8000|\$BACKEND_URL|g\" /etc/systemd/system/openclaw.service"
echo "   sudo systemctl daemon-reload"
echo ""
echo "3. Run onboarding:"
echo "   openclaw onboard"
echo ""
echo "4. Start OpenClaw:"
echo "   sudo systemctl start openclaw"
echo ""
echo "5. Check status:"
echo "   sudo systemctl status openclaw"
echo "   curl http://localhost:18789/health"
