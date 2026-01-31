#!/bin/bash
# Quick fix for Clawdbot module import error

echo "🔧 Fixing Clawdbot Module Error"
echo "================================"

# Stop service
sudo systemctl stop clawdbot

# Fix the service file with correct PYTHONPATH
cat > /tmp/clawdbot.service << 'EOF'
[Unit]
Description=Clawdbot API Server (EC2)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/clawdbot
Environment="PATH=/opt/clawdbot/venv/bin"
Environment="PYTHONPATH=/opt/clawdbot"
Environment="BACKEND_URL=http://54.221.139.68:8000"
Environment="CLAWDBOT_HOST=0.0.0.0"
Environment="CLAWDBOT_PORT=8080"
Environment="LOG_LEVEL=INFO"
ExecStart=/opt/clawdbot/venv/bin/python /opt/clawdbot/clawdbot_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/clawdbot.service /etc/systemd/system/

# Also copy backend_client.py to /opt/clawdbot so it's in the same directory
sudo cp /opt/clawdbot/clawdbot_backend_client.py /opt/clawdbot/backend_client.py 2>/dev/null || true
sudo chown -R ubuntu:ubuntu /opt/clawdbot

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl start clawdbot
sleep 3

# Check status
echo ""
echo "Checking status..."
sudo systemctl is-active clawdbot && echo "✅ Clawdbot is running" || echo "❌ Still failed"

# Check if port is listening
sudo ss -tlnp | grep 8080 && echo "✅ Port 8080 is listening" || echo "❌ Port 8080 not listening"

# Test health
echo ""
echo "Testing health endpoint..."
curl -s http://localhost:8080/health && echo "" || echo "❌ Health check failed"

echo ""
echo "If still failing, check logs:"
echo "  sudo journalctl -u clawdbot -n 20 --no-pager"
