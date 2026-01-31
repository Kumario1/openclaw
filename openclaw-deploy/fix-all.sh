#!/bin/bash
# Fix all issues found in diagnostics

set -e

echo "🔧 Fixing OpenClaw Issues"
echo "========================="

# Stop services
echo "1. Stopping services..."
sudo systemctl stop openclaw 2>/dev/null || true
sudo systemctl stop clawdbot 2>/dev/null || true

# Fix backend URL
echo "2. Fixing backend URL..."
export BACKEND_URL="http://54.221.139.68:8000"
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/openclaw.service
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/clawdbot.service
sed -i "s|localhost:8000|54.221.139.68:8000|g" ~/.openclaw/workspace/AGENTS.md 2>/dev/null || true

# Setup Clawdbot
echo "3. Setting up Clawdbot..."
sudo mkdir -p /opt/clawdbot
sudo cp ~/openclaw-deploy/openclaw/clawdbot_server.py /opt/clawdbot/ 2>/dev/null || true
sudo cp ~/openclaw-deploy/openclaw/clawdbot_backend_client.py /opt/clawdbot/ 2>/dev/null || true
sudo chown -R ubuntu:ubuntu /opt/clawdbot

# Create venv if needed
if [ ! -d "/opt/clawdbot/venv" ]; then
    echo "   Creating Python virtual environment..."
    cd /opt/clawdbot
    python3 -m venv venv
    source venv/bin/activate
    pip install fastapi uvicorn httpx pydantic
fi

# Reload systemd
echo "4. Reloading systemd..."
sudo systemctl daemon-reload

# Start services
echo "5. Starting services..."
sudo systemctl start openclaw
sleep 3
sudo systemctl start clawdbot
sleep 3

# Check status
echo ""
echo "6. Checking status..."
sudo systemctl is-active openclaw && echo "✅ OpenClaw running" || echo "❌ OpenClaw failed"
sudo systemctl is-active clawdbot && echo "✅ Clawdbot running" || echo "❌ Clawdbot failed"

echo ""
echo "7. Testing endpoints..."
sleep 2
curl -s http://localhost:8080/health 2>/dev/null && echo "✅ Clawdbot health check passed" || echo "❌ Clawdbot health check failed"

echo ""
echo "========================="
echo "✅ Fix script complete!"
echo ""
echo "Next steps:"
echo "1. Check logs if needed: sudo journalctl -u clawdbot -f"
echo "2. Update backend security group to allow port 8000 from 44.222.228.231"
echo "3. Re-run diagnostics: sudo ./scripts/diagnose.sh"
