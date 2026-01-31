# 🔍 Verify Everything is Working

## Quick Health Check (Run These First)

SSH into your EC2 and run these commands:

```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231
```

### 1️⃣ Check Services Are Running

```bash
# Check OpenClaw service
sudo systemctl status openclaw

# Check Clawdbot service
sudo systemctl status clawdbot

# Quick check - both should say "active (running)"
sudo systemctl is-active openclaw
sudo systemctl is-active clawdbot
```

**✅ Expected:** Green text saying "active (running)"
**❌ If failed:** Red text or "inactive"

---

### 2️⃣ Check Ports Are Listening

```bash
# See what's running on ports 18789 and 8080
sudo ss -tlnp | grep -E "(18789|8080)"

# Or use netstat
sudo netstat -tlnp | grep -E "(18789|8080)"
```

**✅ Expected:** See both ports listed with processes
**❌ If failed:** No output means services aren't listening

---

### 3️⃣ Test Local Endpoints (On EC2)

```bash
# Test OpenClaw Gateway
curl -s http://localhost:18789/health | python3 -m json.tool

# Test Clawdbot API
curl -s http://localhost:8080/health | python3 -m json.tool

# Test chat endpoint
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "hello"}' | python3 -m json.tool
```

**✅ Expected:** JSON responses with status "healthy"
**❌ If failed:** Connection refused or error message

---

### 4️⃣ Test Backend Connection

```bash
# Test backend is reachable
curl -s http://54.221.139.68:8000/health/live

# Test backend client tool
python3 ~/openclaw-tools/backend_client.py list

# Or get help
python3 ~/openclaw-tools/backend_client.py
```

**✅ Expected:** Backend returns JSON data
**❌ If failed:** Connection refused or timeout

---

### 5️⃣ Check Logs for Errors

```bash
# OpenClaw logs (last 50 lines)
sudo journalctl -u openclaw -n 50 --no-pager

# Clawdbot logs (last 50 lines)
sudo journalctl -u clawdbot -n 50 --no-pager

# Real-time logs (press Ctrl+C to exit)
sudo journalctl -u openclaw -u clawdbot -f
```

**✅ Expected:** Logs show startup messages, no errors
**❌ If failed:** Error messages in red

---

### 6️⃣ Test from Your Local Machine

Open a NEW terminal on your local machine (don't use SSH):

```bash
# Test OpenClaw Gateway from outside
curl -s http://44.222.228.231:18789/health | python3 -m json.tool

# Test Clawdbot API from outside
curl -s http://44.222.228.231:8080/health | python3 -m json.tool

# Test chat endpoint
curl -s -X POST http://44.222.228.231:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me the dashboard"}' | python3 -m json.tool
```

**✅ Expected:** Same JSON responses as on EC2
**❌ If failed:** Connection timeout or refused

---

### 7️⃣ Run Automated Verification Script

On the EC2 instance:

```bash
cd ~/openclaw-deploy
sudo ./scripts/verify-connections.sh
```

This will test all connections and give you a summary.

---

## 📊 What Success Looks Like

### Services Status
```
$ sudo systemctl status openclaw
● openclaw.service - OpenClaw Gateway
   Loaded: loaded (/etc/systemd/system/openclaw.service)
   Active: active (running) since Mon 2024-01-31 10:00:00 UTC

$ sudo systemctl status clawdbot
● clawdbot.service - Clawdbot API Server
   Loaded: loaded (/etc/systemd/system/clawdbot.service)
   Active: active (running) since Mon 2024-01-31 10:00:00 UTC
```

### Health Check Responses

**OpenClaw (Port 18789):**
```json
{
  "status": "healthy",
  "service": "openclaw-gateway",
  "version": "2026.1.29"
}
```

**Clawdbot API (Port 8080):**
```json
{
  "status": "healthy",
  "service": "clawdbot-server",
  "backend_connected": "http://54.221.139.68:8000"
}
```

**Chat Response:**
```json
{
  "response": "I'm Clawdbot, your Transition OS assistant...",
  "session_id": "default",
  "actions_taken": ["provided_help"],
  "data": null
}
```

---

## 🐛 Common Issues & Fixes

### Issue: "inactive (dead)" for services

**Fix:**
```bash
# Check why it failed
sudo journalctl -u openclaw -n 20

# Try starting manually
sudo systemctl start openclaw
sudo systemctl start clawdbot

# Check for errors
openclaw doctor
```

### Issue: "Connection refused" from local machine

**Fix:**
1. Check AWS Security Group allows ports 18789 and 8080
2. Verify services are running on EC2
3. Check if EC2 has public IP assigned

```bash
# On EC2, check public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

### Issue: "Backend connection failed"

**Fix:**
```bash
# Test backend directly
curl http://54.221.139.68:8000/health/live

# If that fails, backend security group is blocking OpenClaw IP
# Add inbound rule: Port 8000 from 44.222.228.231/32
```

### Issue: "command not found: openclaw"

**Fix:**
```bash
# Reinstall OpenClaw
sudo npm install -g openclaw@latest

# Check path
which openclaw
```

### Issue: Ports not listening

**Fix:**
```bash
# Check what ports are in use
sudo lsof -i :18789
sudo lsof -i :8080

# If nothing shows, services aren't started
sudo systemctl start openclaw
sudo systemctl start clawdbot

# If ports are blocked by something else
sudo ss -tlnp | grep 18789
sudo kill -9 <PID>  # if needed
```

---

## 🔥 Quick Diagnostic Script

Save this as `diagnose.sh` on EC2 and run it:

```bash
#!/bin/bash
echo "🔍 OpenClaw Diagnostics"
echo "======================="
echo ""

echo "1. Checking services..."
sudo systemctl is-active openclaw && echo "✅ OpenClaw running" || echo "❌ OpenClaw not running"
sudo systemctl is-active clawdbot && echo "✅ Clawdbot running" || echo "❌ Clawdbot not running"
echo ""

echo "2. Checking ports..."
sudo ss -tlnp | grep -E "(18789|8080)" && echo "✅ Ports listening" || echo "❌ Ports not listening"
echo ""

echo "3. Testing local endpoints..."
curl -s http://localhost:18789/health > /dev/null && echo "✅ OpenClaw (local)" || echo "❌ OpenClaw (local)"
curl -s http://localhost:8080/health > /dev/null && echo "✅ Clawdbot (local)" || echo "❌ Clawdbot (local)"
echo ""

echo "4. Testing backend..."
curl -s http://54.221.139.68:8000/health/live > /dev/null && echo "✅ Backend reachable" || echo "❌ Backend not reachable"
echo ""

echo "5. Public IP:"
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
echo ""

echo "======================="
echo "To test from outside, run:"
echo "curl http://44.222.228.231:18789/health"
echo "curl http://44.222.228.231:8080/health"
```

Make it executable:
```bash
chmod +x diagnose.sh
./diagnose.sh
```

---

## ✅ Final Checklist

- [ ] Services show "active (running)"
- [ ] Ports 18789 and 8080 are listening
- [ ] Local health checks return JSON
- [ ] Backend is reachable from EC2
- [ ] External health checks work (from your laptop)
- [ ] Chat endpoint responds
- [ ] No errors in logs

---

## 🆘 Still Not Working?

Share the output of these commands:

```bash
# On EC2
sudo systemctl status openclaw --no-pager
sudo systemctl status clawdbot --no-pager
sudo journalctl -u openclaw -n 20 --no-pager
sudo ss -tlnp | grep -E "(18789|8080)"
curl -v http://localhost:18789/health 2>&1 | tail -20
```

And from your local machine:
```bash
curl -v http://44.222.228.231:18789/health 2>&1 | tail -20
```
