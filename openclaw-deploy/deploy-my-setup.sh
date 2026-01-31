#!/bin/bash
# Your Personal Deployment Script
# Pre-configured with your EC2 details

set -e

# Your Configuration
OPENCLAW_IP="44.222.228.231"
BACKEND_IP="54.221.139.68"
KEY_PATH="/Users/princekumar/Documents/EC2 Key Pair.pem"
BACKEND_URL="http://54.221.139.68:8000"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying OpenClaw to YOUR EC2 Setup${NC}"
echo "=========================================="
echo "OpenClaw IP: $OPENCLAW_IP"
echo "Backend IP:  $BACKEND_IP"
echo "Backend URL: $BACKEND_URL"
echo ""

# Check if key exists
if [ ! -f "$KEY_PATH" ]; then
    echo "❌ SSH key not found: $KEY_PATH"
    exit 1
fi

# Fix key permissions
echo "🔧 Setting correct permissions on SSH key..."
chmod 400 "$KEY_PATH"

# Check if deployment folder exists
if [ ! -d "openclaw-deploy" ]; then
    echo "❌ openclaw-deploy folder not found"
    echo "Make sure you're running this from /Users/princekumar/openclaw"
    exit 1
fi

echo -e "${YELLOW}📦 Copying files to EC2...${NC}"
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no -r openclaw-deploy "ubuntu@$OPENCLAW_IP:~" || {
    echo "❌ Failed to copy files"
    exit 1
}
echo -e "${GREEN}✅ Files copied${NC}"
echo ""

echo -e "${YELLOW}⚙️  Running installation on EC2...${NC}"
echo "   (This will take 5-10 minutes)"
echo ""

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "ubuntu@$OPENCLAW_IP" << EOF
    set -e
    
    cd ~/openclaw-deploy
    export BACKEND_URL="$BACKEND_URL"
    
    echo "   Configuring backend URL: \$BACKEND_URL"
    
    # Update configs with your backend URL
    sed -i "s|\\\${BACKEND_URL}|\$BACKEND_URL|g" config/AGENTS.md
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" scripts/openclaw.service
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" scripts/clawdbot.service
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" .env.example
    
    # Run installer
    echo "   Installing OpenClaw and Clawdbot..."
    chmod +x scripts/install.sh
    sudo BACKEND_URL=\$BACKEND_URL ./scripts/install.sh
    
    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
EOF

echo ""
echo -e "${GREEN}✅ Deployment finished!${NC}"
echo ""
echo "=========================================="
echo "📋 NEXT STEPS:"
echo ""
echo "1. SSH into your EC2 instance:"
echo "   ssh -i \"$KEY_PATH\" ubuntu@$OPENCLAW_IP"
echo ""
echo "2. Add your AI API keys:"
echo "   sudo nano /etc/environment"
echo "   Add:"
echo "   ANTHROPIC_API_KEY=sk-ant-..."
echo "   OPENAI_API_KEY=sk-..."
echo ""
echo "3. Reload environment:"
echo "   source /etc/environment"
echo ""
echo "4. Run OpenClaw onboarding:"
echo "   openclaw onboard"
echo ""
echo "5. Start the services:"
echo "   sudo systemctl start openclaw"
echo "   sudo systemctl start clawdbot"
echo ""
echo "6. Verify everything works:"
echo "   curl http://$OPENCLAW_IP:18789/health"
echo "   curl http://$OPENCLAW_IP:8080/health"
echo ""
echo "7. Update your frontend .env:"
echo "   VITE_OPENCLAW_URL=ws://$OPENCLAW_IP:18789"
echo "   VITE_CLAWDBOT_URL=http://$OPENCLAW_IP:8080"
echo ""
echo "=========================================="
echo "📖 For detailed instructions, see:"
echo "   openclaw-deploy/DEPLOY_NOW.md"
echo "=========================================="
