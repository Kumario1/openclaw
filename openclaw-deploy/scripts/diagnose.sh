#!/bin/bash
# Quick Diagnostics Script for OpenClaw

echo "🔍 OpenClaw Diagnostics - $(date)"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo "1️⃣  Checking Services..."
echo "-------------------------"
OPENCLAW_STATUS=$(sudo systemctl is-active openclaw 2>/dev/null)
CLAWDBOT_STATUS=$(sudo systemctl is-active clawdbot 2>/dev/null)

if [ "$OPENCLAW_STATUS" = "active" ]; then
    print_status 0 "OpenClaw service is running"
else
    print_status 1 "OpenClaw service is $OPENCLAW_STATUS"
fi

if [ "$CLAWDBOT_STATUS" = "active" ]; then
    print_status 0 "Clawdbot service is running"
else
    print_status 1 "Clawdbot service is $CLAWDBOT_STATUS"
fi
echo ""

echo "2️⃣  Checking Ports..."
echo "---------------------"
OPENCLAW_PORT=$(sudo ss -tlnp 2>/dev/null | grep 18789)
CLAWDBOT_PORT=$(sudo ss -tlnp 2>/dev/null | grep 8080)

if [ -n "$OPENCLAW_PORT" ]; then
    print_status 0 "Port 18789 (OpenClaw) is listening"
    echo "   $OPENCLAW_PORT"
else
    print_status 1 "Port 18789 (OpenClaw) is NOT listening"
fi

if [ -n "$CLAWDBOT_PORT" ]; then
    print_status 0 "Port 8080 (Clawdbot) is listening"
    echo "   $CLAWDBOT_PORT"
else
    print_status 1 "Port 8080 (Clawdbot) is NOT listening"
fi
echo ""

echo "3️⃣  Testing Local Endpoints..."
echo "-------------------------------"
OPENCLAW_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/health 2>/dev/null)
CLAWDBOT_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null)

if [ "$OPENCLAW_HEALTH" = "200" ]; then
    print_status 0 "OpenClaw health check (localhost:18789)"
    curl -s http://localhost:18789/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:18789/health
else
    print_status 1 "OpenClaw health check failed (HTTP $OPENCLAW_HEALTH)"
fi

if [ "$CLAWDBOT_HEALTH" = "200" ]; then
    print_status 0 "Clawdbot health check (localhost:8080)"
    curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/health
else
    print_status 1 "Clawdbot health check failed (HTTP $CLAWDBOT_HEALTH)"
fi
echo ""

echo "4️⃣  Testing Backend Connection..."
echo "----------------------------------"
BACKEND_URL=$(grep "BACKEND_URL" /etc/systemd/system/openclaw.service 2>/dev/null | cut -d'=' -f3 | tr -d '"' || echo "http://54.221.139.68:8000")
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" $BACKEND_URL/health/live 2>/dev/null)

if [ "$BACKEND_HEALTH" = "200" ]; then
    print_status 0 "Backend is reachable ($BACKEND_URL)"
else
    print_status 1 "Backend is NOT reachable ($BACKEND_HEALTH)"
    echo -e "${YELLOW}   Check backend security group allows port 8000 from this EC2${NC}"
fi
echo ""

echo "5️⃣  Testing Backend Client Tool..."
echo "-----------------------------------"
if [ -f ~/openclaw-tools/backend_client.py ]; then
    print_status 0 "Backend client tool exists"
    
    # Test list command
    BACKEND_LIST=$(python3 ~/openclaw-tools/backend_client.py list 2>&1)
    if echo "$BACKEND_LIST" | grep -q "error"; then
        print_status 1 "Backend client list command failed"
    else
        print_status 0 "Backend client can connect to API"
    fi
else
    print_status 1 "Backend client tool not found"
fi
echo ""

echo "6️⃣  System Information..."
echo "--------------------------"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "unknown")
echo "Public IP: $PUBLIC_IP"
echo "OpenClaw:  ws://$PUBLIC_IP:18789"
echo "Clawdbot:  http://$PUBLIC_IP:8080"
echo "Backend:   $BACKEND_URL"
echo ""

echo "========================================"

# Summary
if [ "$OPENCLAW_STATUS" = "active" ] && [ "$CLAWDBOT_STATUS" = "active" ] && [ "$OPENCLAW_HEALTH" = "200" ] && [ "$CLAWDBOT_HEALTH" = "200" ]; then
    echo -e "${GREEN}🎉 All systems operational!${NC}"
    echo ""
    echo "Test from your local machine:"
    echo "  curl http://$PUBLIC_IP:18789/health"
    echo "  curl http://$PUBLIC_IP:8080/health"
else
    echo -e "${YELLOW}⚠️  Some issues detected. Check details above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  Start services:  sudo systemctl start openclaw clawdbot"
    echo "  View logs:       sudo journalctl -u openclaw -f"
    echo "  Check backend:   curl $BACKEND_URL/health/live"
fi

echo ""
