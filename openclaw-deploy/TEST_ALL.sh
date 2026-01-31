#!/bin/bash
# Comprehensive Connection Test

echo "🔍 COMPREHENSIVE CONNECTION TEST"
echo "================================="
echo ""

# IPs
OPENCLAW_IP="44.222.228.231"
BACKEND_IP="54.221.139.68"

echo "OpenClaw IP: $OPENCLAW_IP"
echo "Backend IP: $BACKEND_IP"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_endpoint() {
    local name=$1
    local url=$2
    local timeout=5
    
    echo -n "Testing $name... "
    response=$(curl -s --max-time $timeout "$url" 2>&1)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time $timeout "$url" 2>/dev/null)
    
    if [ "$http_code" = "200" ]; then
        if [ -n "$response" ] && [ "$response" != "{}" ]; then
            echo -e "${GREEN}✅ OK (HTTP $http_code)${NC}"
            echo "   Response: $response"
        else
            echo -e "${YELLOW}⚠️  Empty response (HTTP $http_code)${NC}"
        fi
    elif [ "$http_code" = "000" ]; then
        echo -e "${RED}❌ Connection failed${NC}"
    else
        echo -e "${RED}❌ HTTP $http_code${NC}"
        echo "   Response: $response"
    fi
    echo ""
}

echo "1️⃣  LOCALHOST TESTS (On EC2)"
echo "------------------------------"
test_endpoint "OpenClaw (localhost:18789)" "http://localhost:18789/health"
test_endpoint "Clawdbot (localhost:8080)" "http://localhost:8080/health"
test_endpoint "Chat API (localhost)" "http://localhost:8080/chat"
test_endpoint "Backend (localhost:8000)" "http://localhost:8000/health/live"

echo ""
echo "2️⃣  EXTERNAL IP TESTS (From EC2 to itself)"
echo "--------------------------------------------"
test_endpoint "OpenClaw (external IP)" "http://$OPENCLAW_IP:18789/health"
test_endpoint "Clawdbot (external IP)" "http://$OPENCLAW_IP:8080/health"

echo ""
echo "3️⃣  PORT LISTENING CHECK"
echo "-------------------------"
echo "Ports listening:"
sudo ss -tlnp | grep -E "(18789|8080)" || echo "No ports found"
echo ""

echo "4️⃣  SERVICE STATUS"
echo "-------------------"
sudo systemctl is-active openclaw && echo -e "${GREEN}✅ OpenClaw active${NC}" || echo -e "${RED}❌ OpenClaw not active${NC}"
sudo systemctl is-active clawdbot && echo -e "${GREEN}✅ Clawdbot active${NC}" || echo -e "${RED}❌ Clawdbot not active${NC}"
echo ""

echo "5️⃣  CURL VERBOSE TEST"
echo "---------------------"
echo "Testing with verbose output (OpenClaw):"
curl -v --max-time 5 http://localhost:18789/health 2>&1 | head -30
echo ""

echo "Testing with verbose output (Clawdbot):"
curl -v --max-time 5 http://localhost:8080/health 2>&1 | head -30
echo ""

echo "================================="
echo "NEXT STEPS:"
echo ""
echo "If localhost works but external doesn't:"
echo "  → Check AWS Security Group allows ports 18789/8080"
echo ""
echo "If getting empty responses:"
echo "  → Check service logs: sudo journalctl -u openclaw -f"
echo "  → Check if service is actually running"
echo ""
echo "To test from your local machine:"
echo "  curl http://$OPENCLAW_IP:18789/health"
echo "  curl http://$OPENCLAW_IP:8080/health"
