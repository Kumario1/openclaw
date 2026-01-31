#!/bin/bash
# Quick configuration script for OpenClaw + Clawdbot

set -e

echo "🔧 OpenClaw + Clawdbot Configuration"
echo "====================================="
echo ""

# Get backend URL
read -p "Enter your backend URL (e.g., http://54.123.45.67:8000): " BACKEND_URL

if [ -z "$BACKEND_URL" ]; then
    echo "❌ Error: Backend URL is required"
    exit 1
fi

echo ""
echo "📝 Configuration:"
echo "   Backend URL: $BACKEND_URL"
echo ""

# Update files
export BACKEND_URL

# Update AGENTS.md
sed -i "s|\\\${BACKEND_URL}|$BACKEND_URL|g" config/AGENTS.md 2>/dev/null || \
sed -i.bak "s|\\\${BACKEND_URL}|$BACKEND_URL|g" config/AGENTS.md

# Update service files
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/openclaw.service 2>/dev/null || \
sed -i.bak "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/openclaw.service

sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/clawdbot.service 2>/dev/null || \
sed -i.bak "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/clawdbot.service

# Update .env.example
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" .env.example 2>/dev/null || \
sed -i.bak "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" .env.example

echo "✅ Configuration updated!"
echo ""
echo "Next steps:"
echo "1. Copy this folder to your EC2 instance"
echo "2. Run: sudo ./scripts/install.sh"
echo "3. Add API keys to /etc/environment"
echo "4. Start services with: sudo systemctl start openclaw clawdbot"
