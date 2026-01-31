# 🚀 DEPLOY NOW - Your Configuration

## Your Credentials (Pre-configured)

| Setting | Value |
|---------|-------|
| **OpenClaw EC2 IP** | `44.222.228.231` |
| **Backend EC2 IP** | `54.221.139.68` |
| **SSH Key Path** | `/Users/princekumar/Documents/EC2 Key Pair.pem` |

---

## ⚡ Option 1: One-Command Deploy (Recommended)

Run this on your local machine:

```bash
cd /Users/princekumar/openclaw

# Deploy with your credentials
./openclaw-deploy/quick-deploy.sh \
  "44.222.228.231" \
  "54.221.139.68" \
  "/Users/princekumar/Documents/EC2 Key Pair.pem"
```

---

## ⚙️ Option 2: Manual Step-by-Step

### Step 1: Fix SSH Key Permissions
```bash
chmod 400 "/Users/princekumar/Documents/EC2 Key Pair.pem"
```

### Step 2: Copy Files to EC2
```bash
cd /Users/princekumar/openclaw

scp -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  -r openclaw-deploy \
  ubuntu@44.222.228.231:~/
```

### Step 3: SSH into OpenClaw EC2
```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  ubuntu@44.222.228.231
```

### Step 4: Configure and Install
```bash
cd ~/openclaw-deploy

# Set backend URL
export BACKEND_URL="http://54.221.139.68:8000"

# Update configurations
sed -i "s|\\\${BACKEND_URL}|$BACKEND_URL|g" config/AGENTS.md
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/openclaw.service
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/clawdbot.service

# Run installer (this will take 5-10 minutes)
sudo BACKEND_URL=$BACKEND_URL ./scripts/install.sh
```

---

## 🔧 Post-Installation (Run on EC2)

### Step 5: Add Your API Keys
```bash
sudo nano /etc/environment
```

Add these lines (replace with your actual keys):
```bash
ANTHROPIC_API_KEY=sk-ant-api03-YOUR-ANTHROPIC-KEY-HERE
OPENAI_API_KEY=sk-proj-YOUR-OPENAI-KEY-HERE
BACKEND_URL=http://54.221.139.68:8000
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

### Step 6: Reload Environment
```bash
source /etc/environment
```

### Step 7: Run OpenClaw Onboarding
```bash
openclaw onboard
```
Follow the prompts to configure your AI provider.

### Step 8: Start Services
```bash
sudo systemctl start openclaw
sudo systemctl start clawdbot
```

### Step 9: Verify Everything Works
```bash
# Check OpenClaw
curl http://localhost:18789/health

# Check Clawdbot API
curl http://localhost:8080/health

# Check backend connection
curl http://54.221.139.68:8000/health/live

# Run full verification
sudo ./scripts/verify-connections.sh
```

---

## 🌐 Test from Your Local Machine

```bash
# Test OpenClaw Gateway
curl http://44.222.228.231:18789/health

# Test Clawdbot API
curl http://44.222.228.231:8080/health

# Test chat endpoint
curl -X POST http://44.222.228.231:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the dashboard"}'
```

---

## 📝 Update Your Frontend

In your frontend `.env` file:

```bash
VITE_OPENCLAW_URL=ws://44.222.228.231:18789
VITE_CLAWDBOT_URL=http://44.222.228.231:8080
```

In your frontend code:
```javascript
const ws = new WebSocket(import.meta.env.VITE_OPENCLAW_URL);

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'message',
    content: 'Hello from frontend!'
  }));
};

ws.onmessage = (event) => {
  const response = JSON.parse(event.data);
  console.log('Bot:', response.content);
};
```

---

## 🔒 AWS Security Group Configuration

### For OpenClaw EC2 (44.222.228.231):

| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| SSH | TCP | 22 | My IP | Your local machine |
| Custom TCP | TCP | 18789 | Anywhere | OpenClaw Gateway |
| Custom TCP | TCP | 8080 | Anywhere | Clawdbot API |

> **Note**: In production, change "Anywhere" to your frontend IP/domain

### For Backend EC2 (54.221.139.68):

Add this inbound rule to your backend security group:

| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| Custom TCP | TCP | 8000 | `44.222.228.231/32` | OpenClaw Server Only |

> **Important**: Port 8000 should ONLY be accessible from 44.222.228.231, not from the internet!

---

## 🆘 Troubleshooting

### "Permission denied (publickey)"
```bash
# Fix key permissions
chmod 400 "/Users/princekumar/Documents/EC2 Key Pair.pem"
```

### "Connection refused" on port 18789/8080
```bash
# Check if services are running
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231
sudo systemctl status openclaw
sudo systemctl status clawdbot

# Check AWS security group allows these ports
```

### "Backend connection failed"
```bash
# SSH into OpenClaw and test
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231
curl http://54.221.139.68:8000/health/live

# If this fails, check backend security group
```

### View Logs
```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231
sudo journalctl -u openclaw -f
sudo journalctl -u clawdbot -f
```

---

## ✅ Success Checklist

After deployment, verify:

- [ ] `curl http://44.222.228.231:18789/health` returns `{"status": "healthy"}`
- [ ] `curl http://44.222.228.231:8080/health` returns backend connected
- [ ] Frontend can connect to WebSocket `ws://44.222.228.231:18789`
- [ ] Frontend can call API `http://44.222.228.231:8080/chat`
- [ ] Backend security group restricts port 8000 to 44.222.228.231 only

---

## 📞 Quick Commands Reference

```bash
# SSH into OpenClaw
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" ubuntu@44.222.228.231

# View logs
sudo journalctl -u openclaw -u clawdbot -f

# Restart services
sudo systemctl restart openclaw clawdbot

# Check status
sudo systemctl status openclaw
sudo systemctl status clawdbot
```

---

**Ready to deploy? Run the quick-deploy command above!** 🚀
