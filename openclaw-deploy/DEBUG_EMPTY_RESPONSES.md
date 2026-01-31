# 🔍 Debug Empty Responses

## Problem
Endpoints return empty responses or don't respond from outside the EC2.

## Most Likely Cause
**AWS Security Group is blocking external access.**

---

## Step 1: Run Tests on EC2

SSH into EC2 and run:

```bash
cd ~/openclaw-deploy
sudo ./TEST_ALL.sh
```

This will tell us if the issue is:
- Services not working (localhost fails)
- Network blocking (localhost works, external fails)

---

## Step 2: Test Manually on EC2

```bash
# Test 1: Check what OpenClaw returns
curl -v http://localhost:18789/health 2>&1

# Test 2: Check Clawdbot
curl -v http://localhost:8080/health 2>&1

# Test 3: Check if services are actually listening
sudo netstat -tlnp | grep -E "(18789|8080)"
```

---

## Step 3: Fix AWS Security Group (Most Important)

The security group for EC2 `44.222.228.231` must allow inbound traffic:

### Go to AWS Console:

1. **Open AWS Console** → EC2 → Instances
2. **Find your OpenClaw instance** (44.222.228.231)
3. **Click on the Security Group name** (looks like `sg-xxxxxxxx`)
4. **Click "Edit inbound rules"**
5. **Add these rules:**

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| Custom TCP | TCP | 18789 | 0.0.0.0/0 | OpenClaw Gateway |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Clawdbot API |
| Custom TCP | TCP | 18789 | ::/0 | OpenClaw Gateway (IPv6) |
| Custom TCP | TCP | 8080 | ::/0 | Clawdbot API (IPv6) |

6. **Click "Save rules"**

> ⚠️ **For production**, change `0.0.0.0/0` to your specific IP or use a load balancer

---

## Step 4: Test From Your Local Machine

After fixing security group, run on your laptop:

```bash
# Test OpenClaw
curl -v http://44.222.228.231:18789/health

# Test Clawdbot
curl -v http://44.222.228.231:8080/health

# Test with verbose to see headers
curl -v http://44.222.228.231:8080/health 2>&1 | grep -E "(HTTP|Content|Status)"
```

---

## Step 5: If Still Empty

### Check if services are really running:

```bash
# On EC2
ps aux | grep -E "(openclaw|clawdbot)"
sudo systemctl status openclaw --no-pager
sudo systemctl status clawdbot --no-pager
```

### Check OpenClaw specifically:

The OpenClaw health endpoint might return HTML instead of JSON.

```bash
# What does OpenClaw actually return?
curl http://localhost:18789/health
curl http://localhost:18789/

# Check if it's the control panel HTML
curl -s http://localhost:18789/health | head -20
```

**Note:** OpenClaw might serve its control panel UI at `/health`. Check if you get HTML instead of JSON.

### Check Clawdbot:

```bash
# Should return JSON
curl http://localhost:8080/health | python3 -m json.tool

# If empty, check logs
sudo journalctl -u clawdbot -n 50 --no-pager
```

---

## Common Issues & Fixes

### Issue: "Connection refused" from local machine

**Fix:** Security group not allowing the ports. Add inbound rules for 18789 and 8080.

### Issue: "Connection timeout" from local machine

**Fix:** Either:
- Security group blocking
- EC2 doesn't have public IP assigned
- Wrong IP address

### Issue: Empty `{}` response

**Fix:** Service is running but health check endpoint not properly configured. Check:
```bash
# Restart services
sudo systemctl restart openclaw
sudo systemctl restart clawdbot
```

### Issue: HTML response instead of JSON

**Fix:** OpenClaw serves its UI. Try different endpoints:
```bash
# OpenClaw might have different health endpoint
curl http://44.222.228.231:18789/api/health
curl http://44.222.228.231:18789/status
```

---

## Quick Fix Commands

```bash
# On EC2 - Fix everything

# 1. Restart services
sudo systemctl restart openclaw
sudo systemctl restart clawdbot

# 2. Check if listening
sudo ss -tlnp | grep -E "(18789|8080)"

# 3. Test local
curl http://localhost:8080/health

# 4. Get public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4

# 5. Test external (from EC2)
curl http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/health
```

---

## Test Script for Local Machine

Save this as `test-from-local.sh` on your laptop:

```bash
#!/bin/bash
IP="44.222.228.231"

echo "Testing OpenClaw + Clawdbot from local machine"
echo "=============================================="
echo ""

echo "1. Testing OpenClaw (port 18789)..."
curl -s --max-time 5 http://$IP:18789/health | head -5
echo ""

echo "2. Testing Clawdbot (port 8080)..."
curl -s --max-time 5 http://$IP:8080/health | head -5
echo ""

echo "3. Testing Chat endpoint..."
curl -s --max-time 5 -X POST http://$IP:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"hello"}' | head -5
echo ""

echo "Done!"
```

Run it:
```bash
chmod +x test-from-local.sh
./test-from-local.sh
```

---

## Need More Help?

If still not working, run these and share the output:

```bash
# On EC2
sudo ./TEST_ALL.sh 2>&1

# From local machine
curl -v http://44.222.228.231:8080/health 2>&1
```
