#!/bin/bash
# Force OpenClaw to restart with correct bind address

echo "🔧 Force Restarting OpenClaw"
echo "============================="

# Kill any running openclaw processes
echo "1. Killing any running OpenClaw processes..."
sudo pkill -f openclaw 2>/dev/null || true
sleep 2

# Stop service
echo "2. Stopping service..."
sudo systemctl stop openclaw
sleep 2

# Verify it's stopped
sudo ss -tlnp | grep 18789 && echo "⚠️  Still running, forcing kill..." && sudo kill -9 $(sudo lsof -t -i:18789) 2>/dev/null || true

# Update config file
echo "3. Updating config to bind to 0.0.0.0..."
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "agent": {
    "name": "Clawdbot",
    "description": "AI assistant for LPL Transition OS"
  },
  "models": {
    "default": "anthropic/claude-sonnet-4",
    "fast": "anthropic/claude-haiku",
    "powerful": "anthropic/claude-opus-4-5",
    "gpt4": "openai/gpt-4o",
    "gpt4-mini": "openai/gpt-4o-mini",
    "local": "ollama/llama3.2"
  },
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0",
    "verbose": false
  },
  "channels": {
    "webchat": {
      "enabled": true
    }
  },
  "skills": {
    "enabled": ["transition-os"]
  },
  "tools": {
    "allowed": ["backend_client"]
  },
  "security": {
    "dmPolicy": "pairing"
  }
}
EOF

echo "4. New config:"
cat ~/.openclaw/openclaw.json | grep -A3 '"gateway"'

# Start service
echo ""
echo "5. Starting OpenClaw..."
sudo systemctl start openclaw

# Wait for it to start
sleep 5

# Check status
echo ""
echo "6. Checking if it's listening on 0.0.0.0..."
sudo ss -tlnp | grep 18789

# Test
echo ""
echo "7. Testing..."
sleep 2

if sudo ss -tlnp | grep -q "0.0.0.0:18789"; then
    echo "✅ SUCCESS! OpenClaw is now listening on 0.0.0.0:18789"
    echo ""
    echo "Test from outside:"
    echo "  curl http://44.222.228.231:18789/health"
else
    echo "❌ Still not listening on 0.0.0.0"
    echo "Current status:"
    sudo ss -tlnp | grep 18789
    echo ""
    echo "Check logs:"
    sudo journalctl -u openclaw -n 20 --no-pager
fi
