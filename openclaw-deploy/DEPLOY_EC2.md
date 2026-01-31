# 🚀 Deploy OpenClaw to EC2 - Step by Step

## Prerequisites

Before you start, you need:
1. ✅ AWS Account
2. ✅ Backend EC2 instance running (Instance #2)
3. ✅ Backend EC2 IP address (e.g., `54.123.45.67`)
4. ✅ SSH key pair (.pem file)

---

## Step 1: Launch EC2 Instance #1 (OpenClaw)

### 1.1 Create Instance in AWS Console

1. Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2/)
2. Click **Launch Instance**
3. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `OpenClaw-Server` |
| **AMI** | Ubuntu 24.04 LTS |
| **Instance Type** | t3.medium (2 vCPU, 4 GB RAM) |
| **Key Pair** | Your existing key pair |
| **Storage** | 30 GB |

### 1.2 Configure Security Group

Create new security group:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | My IP | SSH access |
| Custom TCP | 18789 | Anywhere | OpenClaw Gateway |
| Custom TCP | 8080 | Anywhere | Clawdbot API |

> ⚠️ **For production**: Replace "Anywhere" with your frontend IP/domain

### 1.3 Launch Instance

Click **Launch Instance** and note the **Public IP address** (e.g., `54.321.67.89`)

---

## Step 2: Deploy OpenClaw to EC2

### Option A: Quick Deploy (Recommended)

Run this on your local machine:

```bash
# 1. Set your variables
OPENCLAW_IP="YOUR_OPENCLAW_EC2_IP"        # e.g., 54.321.67.89
BACKEND_IP="YOUR_BACKEND_EC2_IP"          # e.g., 54.123.45.67
KEY_PATH="~/path/to/your-key.pem"         # e.g., ~/.ssh/aws-key.pem

# 2. Copy deployment package
scp -i $KEY_PATH -r openclaw-deploy ubuntu@$OPENCLAW_IP:~/

# 3. SSH into instance
ssh -i $KEY_PATH ubuntu@$OPENCLAW_IP
```

Once inside the EC2 instance:

```bash
# 4. Go to deployment folder
cd ~/openclaw-deploy

# 5. Configure backend URL
export BACKEND_URL="http://$BACKEND_IP:8000"

# 6. Update configurations
sed -i "s|\\\${BACKEND_URL}|$BACKEND_URL|g" config/AGENTS.md
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/openclaw.service
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/clawdbot.service

# 7. Run installer
chmod +x scripts/install.sh
sudo ./scripts/install.sh

# 8. Add API keys
sudo nano /etc/environment
```

Add these lines (replace with your actual keys):
```bash
ANTHROPIC_API_KEY=sk-ant-api03-YOUR-KEY-HERE
OPENAI_API_KEY=sk-proj-YOUR-KEY-HERE
```

Save (Ctrl+O, Enter, Ctrl+X)

```bash
# 9. Reload environment
source /etc/environment

# 10. Run OpenClaw onboarding
openclaw onboard
# Follow the prompts to set up your AI provider

# 11. Start services
sudo systemctl start openclaw
sudo systemctl start clawdbot

# 12. Check status
sudo systemctl status openclaw
sudo systemctl status clawdbot

# 13. Test connections
curl http://localhost:18789/health
curl http://localhost:8080/health
```

---

### Option B: One-Line Deploy Script

Create this script on your local machine:

```bash
#!/bin/bash
# deploy-openclaw.sh

OPENCLAW_IP=${1:-"YOUR_OPENCLAW_IP"}
BACKEND_IP=${2:-"YOUR_BACKEND_IP"}
KEY_PATH=${3:-"~/.ssh/your-key.pem"}

if [ "$OPENCLAW_IP" = "YOUR_OPENCLAW_IP" ] || [ "$BACKEND_IP" = "YOUR_BACKEND_IP" ]; then
    echo "Usage: ./deploy-openclaw.sh <openclaw-ip> <backend-ip> <key-path>"
    echo "Example: ./deploy-openclaw.sh 54.321.67.89 54.123.45.67 ~/.ssh/aws.pem"
    exit 1
fi

echo "🚀 Deploying OpenClaw to EC2..."
echo "   OpenClaw IP: $OPENCLAW_IP"
echo "   Backend IP: $BACKEND_IP"
echo ""

# Copy files
echo "📦 Copying files..."
scp -i $KEY_PATH -r openclaw-deploy ubuntu@$OPENCLAW_IP:~/

# Run setup remotely
echo "⚙️  Running setup..."
ssh -i $KEY_PATH ubuntu@$OPENCLAW_IP << EOF
    cd ~/openclaw-deploy
    export BACKEND_URL="http://$BACKEND_IP:8000"
    
    # Update configs
    sed -i "s|\\\${BACKEND_URL}|\$BACKEND_URL|g" config/AGENTS.md
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" scripts/openclaw.service
    sed -i "s|BACKEND_URL=.*|BACKEND_URL=\$BACKEND_URL|g" scripts/clawdbot.service
    
    # Install
    chmod +x scripts/install.sh
    sudo BACKEND_URL=\$BACKEND_URL ./scripts/install.sh
    
    echo ""
    echo "✅ Installation complete!"
    echo ""
    echo "Next steps:"
    echo "1. SSH into instance: ssh -i $KEY_PATH ubuntu@$OPENCLAW_IP"
    echo "2. Add API keys: sudo nano /etc/environment"
    echo "3. Run onboarding: openclaw onboard"
    echo "4. Start services: sudo systemctl start openclaw clawdbot"
EOF

echo ""
echo "🎉 Deployment script finished!"
```

Make it executable and run:
```bash
chmod +x deploy-openclaw.sh
./deploy-openclaw.sh 54.321.67.89 54.123.45.67 ~/.ssh/aws.pem
```

---

## Step 3: Verify Deployment

### Test from EC2 Instance

```bash
# SSH into OpenClaw EC2
ssh -i your-key.pem ubuntu@YOUR_OPENCLAW_IP

# Run verification
sudo ~/openclaw-deploy/scripts/verify-connections.sh
```

Expected output:
```
🔍 Verifying Connections...
===========================

1️⃣  OpenClaw Gateway (Port 18789)
   Testing OpenClaw Health... ✅ Connected

2️⃣  Clawdbot API Server (Port 8080)
   Testing Clawdbot Health... ✅ Connected

3️⃣  Backend API Connection
   Testing Backend API... ✅ Connected

4️⃣  Backend Client Tool
   Testing backend_client.py... ✅ Working
```

### Test from Your Local Machine

```bash
# Test OpenClaw
curl http://YOUR_OPENCLAW_IP:18789/health

# Test Clawdbot API
curl http://YOUR_OPENCLAW_IP:8080/health

# Test chat endpoint
curl -X POST http://YOUR_OPENCLAW_IP:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the dashboard"}'
```

---

## Step 4: Update Frontend

In your frontend `.env` file:

```bash
# .env
VITE_OPENCLAW_URL=ws://YOUR_OPENCLAW_IP:18789
VITE_CLAWDBOT_URL=http://YOUR_OPENCLAW_IP:8080
```

In your frontend code:

```javascript
const OPENCLAW_URL = import.meta.env.VITE_OPENCLAW_URL;

// Connect to OpenClaw
const ws = new WebSocket(OPENCLAW_URL);

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'message',
    content: 'Hello from frontend!'
  }));
};

ws.onmessage = (event) => {
  const response = JSON.parse(event.data);
  console.log('Bot says:', response.content);
};
```

---

## Step 5: Backend Security Group Update

Make sure your **Backend EC2 (Instance #2)** security group allows connections from OpenClaw EC2:

1. Go to AWS Console → EC2 → Security Groups
2. Find the security group attached to your Backend EC2
3. Add inbound rule:
   - Type: Custom TCP
   - Port: 8000
   - Source: **Custom** → Enter OpenClaw EC2's security group ID, or
   - Source: **My IP** → Enter OpenClaw EC2's private IP

---

## Useful Commands

### View Logs
```bash
# OpenClaw logs
sudo journalctl -u openclaw -f

# Clawdbot logs
sudo journalctl -u clawdbot -f

# All logs
sudo journalctl -u openclaw -u clawdbot -f
```

### Restart Services
```bash
sudo systemctl restart openclaw
sudo systemctl restart clawdbot
```

### Check Status
```bash
sudo systemctl status openclaw
sudo systemctl status clawdbot
```

### Update Configuration
```bash
# Edit AGENTS.md
nano ~/.openclaw/workspace/AGENTS.md

# Edit OpenClaw config
nano ~/.openclaw/openclaw.json

# Restart after changes
sudo systemctl restart openclaw
```

---

## Troubleshooting

### ❌ "Permission denied (publickey)"
```bash
# Fix key permissions
chmod 400 your-key.pem
```

### ❌ "Could not resolve host"
```bash
# Check internet connectivity on EC2
ping google.com

# Check DNS
sudo systemd-resolve --status
```

### ❌ "Failed to start openclaw.service"
```bash
# Check detailed error
sudo journalctl -u openclaw -n 50

# Check if openclaw is installed
which openclaw
openclaw --version

# Reinstall if needed
sudo npm install -g openclaw@latest
```

### ❌ "Backend connection failed"
```bash
# Test backend from OpenClaw EC2
curl http://YOUR_BACKEND_IP:8000/health/live

# Check backend URL config
grep BACKEND_URL /etc/systemd/system/openclaw.service
grep BACKEND_URL /etc/systemd/system/clawdbot.service
```

### ❌ "Port already in use"
```bash
# Find process using port
sudo lsof -i :18789
sudo lsof -i :8080

# Kill if needed
sudo kill -9 <PID>
```

---

## Summary

| Step | What | Where |
|------|------|-------|
| 1 | Launch EC2 | AWS Console |
| 2 | Copy files | `scp -r openclaw-deploy ubuntu@IP:~/` |
| 3 | Configure | Set `BACKEND_URL` |
| 4 | Install | `sudo ./scripts/install.sh` |
| 5 | Add API keys | `/etc/environment` |
| 6 | Onboard | `openclaw onboard` |
| 7 | Start | `sudo systemctl start openclaw clawdbot` |
| 8 | Verify | `curl http://IP:18789/health` |

---

## Next Steps

- [ ] Test frontend connection
- [ ] Add HTTPS (via load balancer or CloudFront)
- [ ] Set up monitoring (CloudWatch)
- [ ] Configure auto-start on boot (already done via systemd)
