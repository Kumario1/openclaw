#!/bin/bash
# Connection Verification Script
# Run this on the OpenClaw/Clawdbot EC2 instance

set -e

echo "🔍 Verifying Connections..."
echo "==========================="
echo ""

# Get Backend URL from environment or service file
BACKEND_URL=$(grep "BACKEND_URL" /etc/systemd/system/openclaw.service 2>/dev/null | cut -d'=' -f3 | tr -d '"' || echo "")
CLAWDBOT_URL=$(grep "BACKEND_URL" /etc/systemd/system/clawdbot.service 2>/dev/null | cut -d'=' -f3 | tr -d '"' || echo "")

echo "📋 Configuration:"
echo "   Backend URL (OpenClaw): $BACKEND_URL"
echo "   Backend URL (Clawdbot): $CLAWDBOT_URL"
echo ""

# Function to test connection
test_connection() {
    local name=$1
    local url=$2
    local timeout=5
    
    echo -n "   Testing $name... "
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        echo "✅ Connected"
        return 0
    else
        echo "❌ Failed"
        return 1
    fi
}

# Test 1: OpenClaw Gateway
echo "1️⃣  OpenClaw Gateway (Port 18789)"
test_connection "OpenClaw Health" "http://localhost:18789/health" || true
echo ""

# Test 2: Clawdbot API Server
echo "2️⃣  Clawdbot API Server (Port 8080)"
test_connection "Clawdbot Health" "http://localhost:8080/health" || true
echo ""

# Test 3: Backend Connection
echo "3️⃣  Backend API Connection"
if [ -n "$BACKEND_URL" ]; then
    test_connection "Backend API" "$BACKEND_URL/health/live" || \
    test_connection "Backend Root" "$BACKEND_URL/" || true
else
    echo "   ⚠️  BACKEND_URL not configured"
fi
echo ""

# Test 4: Backend Client Tool
echo "4️⃣  Backend Client Tool"
if [ -f ~/openclaw-tools/backend_client.py ]; then
    echo -n "   Testing backend_client.py... "
    if python3 ~/openclaw-tools/backend_client.py list > /dev/null 2>&1; then
        echo "✅ Working"
    else
        echo "❌ Failed (backend may be down or URL incorrect)"
    fi
else
    echo "   ⚠️  backend_client.py not found"
fi
echo ""

# Show public IP
echo "5️⃣  Network Information"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "unknown")
echo "   OpenClaw/Clawdbot Public IP: $PUBLIC_IP"
echo "   OpenClaw WebSocket: ws://$PUBLIC_IP:18789"
echo "   Clawdbot REST API: http://$PUBLIC_IP:8080"
echo ""

# Summary
echo "==========================="
echo "📊 Summary:"
echo ""
echo "Frontend should connect to:"
echo "   WebSocket: ws://$PUBLIC_IP:18789"
echo "   REST API:  http://$PUBLIC_IP:8080"
echo ""
echo "Backend should allow connections from this EC2's security group"
echo "   Backend URL: $BACKEND_URL"
echo ""
