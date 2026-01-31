#!/bin/bash
# Quick Deploy Script for OpenClaw to EC2
# Usage: ./quick-deploy.sh <openclaw-ip> <backend-ip> [key-path]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arguments
OPENCLAW_IP=${1:-""}
BACKEND_IP=${2:-""}
KEY_PATH=${3:-"~/.ssh/id_rsa"}

# Validate inputs
if [ -z "$OPENCLAW_IP" ] || [ -z "$BACKEND_IP" ]; then
    echo -e "${RED}Usage: ./quick-deploy.sh <openclaw-ip> <backend-ip> [key-path]${NC}"
    echo ""
    echo "Example:"
    echo "  ./quick-deploy.sh 54.321.67.89 54.123.45.67 ~/.ssh/aws.pem"
    echo ""
    echo "Get your IPs from AWS EC2 Console:"
    echo "  - OpenClaw IP: Your new EC2 instance public IP"
    echo "  - Backend IP: Your existing backend EC2 public/private IP"
    exit 1
fi

echo -e "${GREEN}🚀 OpenClaw Quick Deploy${NC}"
echo "=========================="
echo "OpenClaw EC2 IP: $OPENCLAW_IP"
echo "Backend EC2 IP:  $BACKEND_IP"
echo "SSH Key:         $KEY_PATH"
echo ""

# Expand tilde in key path
KEY_PATH="${KEY_PATH/#\~/$HOME}"

# Check if key exists
if [ ! -f "$KEY_PATH" ]; then
    echo -e "${RED}❌ SSH key not found: $KEY_PATH${NC}"
    exit 1
fi

# Check if deployment folder exists
if [ ! -d "openclaw-deploy" ]; then
    echo -e "${RED}❌ openclaw-deploy folder not found in current directory${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Step 1: Copying files to EC2...${NC}"
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no -r openclaw-deploy "ubuntu@$OPENCLAW_IP:~/" || {
    echo -e "${RED}❌ Failed to copy files${NC}"
    exit 1
}
echo -e "${GREEN}✅ Files copied${NC}"
echo ""

echo -e "${YELLOW}⚙️  Step 2: Running installation on EC2...${NC}"
echo "   (This may take 5-10 minutes)"
echo ""

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "ubuntu@$OPENCLAW_IP" << EOF
    set -e
    
    cd ~/openclaw-deploy
    export BACKEND_URL="http://$BACKEND_IP:8000"
    
    echo "   Configuring backend URL: \$BACKEND_URL"
    
    # Update configs
    sed -i "s|\\\${BACKEND_URL}|\$BACKEND_URL|g" config/AGENTS.md 2>/dev/null || true
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" scripts/openclaw.service
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" scripts/clawdbot.service
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" .env.example
    
    # Run installer
    echo "   Running install script..."
    chmod +x scripts/install.sh
    sudo BACKEND_URL=\$BACKEND_URL ./scripts/install.sh
    
    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
EOF

echo ""
echo -e "${GREEN}✅ Deployment finished!${NC}"
echo ""
echo "=========================="
echo "📋 NEXT STEPS:"
echo ""
echo "1. SSH into your EC2 instance:"
echo "   ssh -i $KEY_PATH ubuntu@$OPENCLAW_IP"
echo ""
echo "2. Add your AI API keys:"
echo "   sudo nano /etc/environment"
echo "   Add:"
echo "   ANTHROPIC_API_KEY=sk-ant-..."
echo "   OPENAI_API_KEY=sk-..."
echo ""
echo "3. Run OpenClaw onboarding:"
echo "   source /etc/environment"
echo "   openclaw onboard"
echo ""
echo "4. Start the services:"
echo "   sudo systemctl start openclaw"
echo "   sudo systemctl start clawdbot"
echo ""
echo "5. Verify everything works:"
echo "   curl http://$OPENCLAW_IP:18789/health"
echo "   curl http://$OPENCLAW_IP:8080/health"
echo ""
echo "6. Update your frontend .env:"
echo "   VITE_OPENCLAW_URL=ws://$OPENCLAW_IP:18789"
echo "   VITE_CLAWDBOT_URL=http://$OPENCLAW_IP:8080"
echo ""
echo "=========================="
