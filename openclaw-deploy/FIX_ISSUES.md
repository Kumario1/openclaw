# 🔧 Fix Issues Found in Diagnostics

## Problems Identified

1. ❌ **Backend URL is wrong** - Set to `localhost:8000` instead of `54.221.139.68:8000`
2. ❌ **Services stuck in "activating"** - Not fully started
3. ❌ **Clawdbot not running** - Port 8080 not listening
4. ❌ **Backend not reachable** - Wrong URL + Security group likely blocking

---

## 🔥 Quick Fix (Run These Commands)

SSH into EC2 and run:

```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231
```

### Step 1: Stop Services
```bash
sudo systemctl stop openclaw
sudo systemctl stop clawdbot
```

### Step 2: Fix Backend URL
```bash
# Set correct backend URL
export BACKEND_URL="http://54.221.139.68:8000"

# Update service files
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/openclaw.service
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/clawdbot.service

# Update AGENTS.md
sed -i "s|localhost:8000|54.221.139.68:8000|g" ~/.openclaw/workspace/AGENTS.md

# Reload systemd
sudo systemctl daemon-reload
```

### Step 3: Fix Clawdbot Setup
```bash
# Check if Clawdbot files exist
ls -la /opt/clawdbot/

# If not, copy them
sudo mkdir -p /opt/clawdbot
sudo cp ~/openclaw-deploy/openclaw/clawdbot_server.py /opt/clawdbot/
sudo cp ~/openclaw-deploy/openclaw/clawdbot_backend_client.py /opt/clawdbot/

# Fix permissions
sudo chown -R ubuntu:ubuntu /opt/clawdbot

# Create virtual environment if not exists
if [ ! -d "/opt/clawdbot/venv" ]; then
    cd /opt/clawdbot
    python3 -m venv venv
    source venv/bin/activate
    pip install fastapi uvicorn httpx pydantic
fi
```

### Step 4: Start Services
```bash
# Start OpenClaw
sudo systemctl start openclaw
sleep 5

# Start Clawdbot
sudo systemctl start clawdbot
sleep 5

# Check status
sudo systemctl status openclaw --no-pager
sudo systemctl status clawdbot --no-pager
```

### Step 5: Verify
```bash
# Check ports
sudo ss -tlnp | grep -E "(18789|8080)"

# Test Clawdbot
curl http://localhost:8080/health

# Test backend connection
curl http://54.221.139.68:8000/health/live
```

---

## 🛠️ If Clawdbot Still Won't Start

Try running it manually to see errors:

```bash
# Run manually to see errors
cd /opt/clawdbot
source venv/bin/activate
python clawdbot_server.py

# If it works, stop with Ctrl+C and try systemd again
# If it fails, check the error message
```

---

## 🔒 Backend Security Group Fix

Your backend EC2 (54.221.139.68) needs to allow connections from OpenClaw EC2 (44.222.228.231):

1. Go to AWS Console → EC2 → Security Groups
2. Find the security group for your backend (54.221.139.68)
3. Add inbound rule:
   - Type: Custom TCP
   - Port: 8000
   - Source: `44.222.228.231/32`
   - Description: OpenClaw Server

---

## 📋 Complete Fix Script

Save this as `fix-all.sh` and run it:

```bash
#!/bin/bash
set -e

echo "🔧 Fixing OpenClaw Issues"
echo "========================="

# Stop services
echo "1. Stopping services..."
sudo systemctl stop openclaw 2>/dev/null || true
sudo systemctl stop clawdbot 2>/dev/null || true

# Fix backend URL
echo "2. Fixing backend URL..."
export BACKEND_URL="http://54.221.139.68:8000"
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/openclaw.service
sudo sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" /etc/systemd/system/clawdbot.service
sed -i "s|localhost:8000|54.221.139.68:8000|g" ~/.openclaw/workspace/AGENTS.md 2>/dev/null || true

# Setup Clawdbot
echo "3. Setting up Clawdbot..."
sudo mkdir -p /opt/clawdbot
sudo cp ~/openclaw-deploy/openclaw/clawdbot_server.py /opt/clawdbot/ 2>/dev/null || true
sudo cp ~/openclaw-deploy/openclaw/clawdbot_backend_client.py /opt/clawdbot/ 2>/dev/null || true
sudo chown -R ubuntu:ubuntu /opt/clawdbot

# Create venv if needed
if [ ! -d "/opt/clawdbot/venv" ]; then
    echo "   Creating Python virtual environment..."
    cd /opt/clawdbot
    python3 -m venv venv
    source venv/bin/activate
    pip install fastapi uvicorn httpx pydantic
fi

# Reload systemd
echo "4. Reloading systemd..."
sudo systemctl daemon-reload

# Start services
echo "5. Starting services..."
sudo systemctl start openclaw
sleep 3
sudo systemctl start clawdbot
sleep 3

# Check status
echo ""
echo "6. Checking status..."
sudo systemctl is-active openclaw && echo "✅ OpenClaw running" || echo "❌ OpenClaw failed"
sudo systemctl is-active clawdbot && echo "✅ Clawdbot running" || echo "❌ Clawdbot failed"

echo ""
echo "7. Testing endpoints..."
sleep 2
curl -s http://localhost:8080/health && echo "✅ Clawdbot health check passed" || echo "❌ Clawdbot health check failed"

echo ""
echo "========================="
echo "✅ Fix script complete!"
echo ""
echo "If Clawdbot still shows ❌, check logs:"
echo "  sudo journalctl -u clawdbot -f"
echo ""
echo "Make sure backend security group allows port 8000 from 44.222.228.231"
```

Run it:
```bash
cd ~/openclaw-deploy
chmod +x fix-all.sh
./fix-all.sh
```

---

## 🧪 After Fix - Test Again

```bash
# Re-run diagnostics
cd ~/openclaw-deploy
sudo ./scripts/diagnose.sh
```

Expected results:
- ✅ OpenClaw service is active
- ✅ Clawdbot service is active
- ✅ Port 18789 listening
- ✅ Port 8080 listening
- ✅ Health checks return JSON
- ⚠️ Backend may still fail until security group is fixed

---

## 📞 Still Having Issues?

Check these logs:

```bash
# OpenClaw logs
sudo journalctl -u openclaw -n 50 --no-pager

# Clawdbot logs
sudo journalctl -u clawdbot -n 50 --no-pager

# Test Clawdbot manually
cd /opt/clawdbot
source venv/bin/activate
python clawdbot_server.py
```

Share the error messages if you need help!
