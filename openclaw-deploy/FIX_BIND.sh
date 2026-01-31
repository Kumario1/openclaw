#!/bin/bash
# Fix OpenClaw bind address

echo "🔧 Fixing OpenClaw Bind Address"
echo "================================"

# Stop services
sudo systemctl stop openclaw
sudo systemctl stop clawdbot

# Check current OpenClaw config
echo "1. Current OpenClaw config:"
cat ~/.openclaw/openclaw.json | grep -A5 gateway
echo ""

# Fix the config to bind to 0.0.0.0
echo "2. Updating config to bind to 0.0.0.0..."
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

echo "3. Updated config:"
cat ~/.openclaw/openclaw.json | grep -A5 gateway
echo ""

# Restart services
echo "4. Restarting services..."
sudo systemctl start openclaw
sleep 5
sudo systemctl start clawdbot
sleep 3

# Check ports
echo ""
echo "5. Checking ports..."
sudo ss -tlnp | grep -E "(18789|8080)"

echo ""
echo "================================"
echo "OpenClaw should now listen on 0.0.0.0:18789"
echo "Test: curl http://44.222.228.231:18789/health"
