#!/bin/bash
# Final fix for all issues

echo "🔧 Final Fix for Clawdbot"
echo "========================="

# Stop service
sudo systemctl stop clawdbot

# Ensure both files are in /opt/clawdbot
sudo mkdir -p /opt/clawdbot
sudo cp ~/openclaw-deploy/openclaw/clawdbot_server.py /opt/clawdbot/
sudo cp ~/openclaw-deploy/openclaw/clawdbot_backend_client.py /opt/clawdbot/

# Fix the import in server file to use local import
sudo sed -i 's/from openclaw.clawdbot_backend_client/from clawdbot_backend_client/g' /opt/clawdbot/clawdbot_server.py

# Fix permissions
sudo chown -R ubuntu:ubuntu /opt/clawdbot

# Ensure venv exists with dependencies
if [ ! -d "/opt/clawdbot/venv" ]; then
    echo "Creating virtual environment..."
    cd /opt/clawdbot
    python3 -m venv venv
fi

echo "Installing dependencies..."
cd /opt/clawdbot
source venv/bin/activate
pip install fastapi uvicorn httpx pydantic

# Create fixed service file
cat > /tmp/clawdbot.service << 'EOF'
[Unit]
Description=Clawdbot API Server (EC2)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/clawdbot
Environment="PATH=/opt/clawdbot/venv/bin"
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
sudo systemctl daemon-reload

# Start service
sudo systemctl start clawdbot
sleep 3

# Check
echo ""
echo "Checking results..."
if sudo systemctl is-active clawdbot > /dev/null; then
    echo "✅ Clawdbot service is active"
else
    echo "❌ Clawdbot service failed"
fi

if sudo ss -tlnp | grep -q 8080; then
    echo "✅ Port 8080 is listening"
else
    echo "❌ Port 8080 not listening"
fi

# Test
sleep 2
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ Health check passed"
    curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/health
else
    echo "❌ Health check failed"
    echo "Logs:"
    sudo journalctl -u clawdbot -n 10 --no-pager
fi

echo ""
echo "Done!"
