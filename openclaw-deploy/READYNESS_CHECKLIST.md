# ✅ OpenClaw Deployment - Readiness Checklist

## 📦 Package Contents

### Configuration Files
- [x] `config/openclaw.json` - Multi-model AI configuration (6 models)
- [x] `config/AGENTS.md` - AI prompts with ${BACKEND_URL} placeholder
- [x] `.env.example` - Environment variable template
- [x] `.gitignore` - Git ignore rules

### Scripts
- [x] `scripts/install.sh` - Main installation script for EC2
- [x] `scripts/openclaw.service` - Systemd service for OpenClaw (port 18789)
- [x] `scripts/clawdbot.service` - Systemd service for Clawdbot API (port 8080)
- [x] `scripts/verify-connections.sh` - Post-install verification

### Python Application
- [x] `openclaw/clawdbot_server.py` - FastAPI server with CORS
- [x] `openclaw/clawdbot_backend_client.py` - Backend API client
- [x] `src/backend_client.py` - CLI tool for backend calls

### Deployment Tools
- [x] `configure.sh` - Local configuration script
- [x] `quick-deploy.sh` - One-command EC2 deploy script

### Documentation
- [x] `README.md` - Quick start guide
- [x] `DEPLOY_EC2.md` - Detailed EC2 deployment guide
- [x] `CONNECTIONS.md` - Architecture and connection guide
- [x] `READYNESS_CHECKLIST.md` - This file

---

## 🔧 Pre-Deployment Requirements

### AWS Setup
- [ ] AWS Account with EC2 access
- [ ] EC2 Instance #1 (OpenClaw): Ubuntu 24.04, t3.medium, 30GB
- [ ] EC2 Instance #2 (Backend): Running with backend on port 8000
- [ ] SSH Key Pair (.pem file)
- [ ] Security Group for OpenClaw: Ports 22, 18789, 8080
- [ ] Security Group for Backend: Port 8000 (OpenClaw IP only)

### API Keys
- [ ] Anthropic API Key (for Claude models) - OR
- [ ] OpenAI API Key (for GPT models) - OR
- [ ] Both (recommended for flexibility)

### Information Needed
- [ ] OpenClaw EC2 Public IP (e.g., 54.321.67.89)
- [ ] Backend EC2 IP (e.g., 54.123.45.67)
- [ ] SSH Key Path (e.g., ~/.ssh/aws.pem)

---

## 🚀 Deployment Steps

### Option 1: Quick Deploy (Recommended)
```bash
# On your local machine
cd /Users/princekumar/openclaw
./openclaw-deploy/quick-deploy.sh <OPENCLAW_IP> <BACKEND_IP> <KEY_PATH>
```

### Option 2: Manual Deploy
```bash
# 1. Configure locally
./openclaw-deploy/configure.sh

# 2. Copy to EC2
scp -r openclaw-deploy ubuntu@<OPENCLAW_IP>:~/

# 3. SSH and install
ssh ubuntu@<OPENCLAW_IP>
cd ~/openclaw-deploy
sudo ./scripts/install.sh
```

---

## ⚙️ Post-Installation Steps

### 1. Add API Keys
```bash
sudo nano /etc/environment
```
Add:
```
ANTHROPIC_API_KEY=sk-ant-api03-...
OPENAI_API_KEY=sk-proj-...
```

### 2. Run Onboarding
```bash
source /etc/environment
openclaw onboard
```

### 3. Start Services
```bash
sudo systemctl start openclaw
sudo systemctl start clawdbot
```

### 4. Verify Installation
```bash
# From EC2
curl http://localhost:18789/health
curl http://localhost:8080/health
sudo ./scripts/verify-connections.sh

# From local machine
curl http://<OPENCLAW_IP>:18789/health
curl http://<OPENCLAW_IP>:8080/health
```

---

## 🔍 Verification Checklist

### Services
- [ ] OpenClaw Gateway running on port 18789
- [ ] Clawdbot API running on port 8080
- [ ] Both services enabled (start on boot)
- [ ] No errors in logs: `sudo journalctl -u openclaw -u clawdbot`

### Connectivity
- [ ] OpenClaw can reach Backend on port 8000
- [ ] Frontend can reach OpenClaw on port 18789
- [ ] Frontend can reach Clawdbot API on port 8080
- [ ] Backend security group restricts port 8000 to OpenClaw IP

### API Endpoints
- [ ] `GET /health` returns 200 on both ports
- [ ] `POST /chat` responds correctly
- [ ] Backend client can list households
- [ ] AI models respond (test with a simple query)

---

## 🔒 Security Checklist

- [ ] Backend port 8000 NOT exposed to public (only OpenClaw IP)
- [ ] API keys stored in `/etc/environment` (not in code)
- [ ] SSH key permissions set to 400: `chmod 400 key.pem`
- [ ] CORS configured for production (if needed)
- [ ] Regular security updates: `sudo apt-get update && sudo apt-get upgrade`

---

## 🐛 Common Issues & Solutions

### "Connection refused" from frontend
- Check security group allows ports 18789/8080
- Verify services are running: `sudo systemctl status openclaw`

### "Backend connection failed"
- Verify `BACKEND_URL` is correct in service files
- Test from EC2: `curl http://<BACKEND_IP>:8000/health/live`
- Check backend security group allows OpenClaw IP

### "Permission denied (publickey)"
- Fix key permissions: `chmod 400 your-key.pem`
- Verify using correct user: `ubuntu@` not `ec2-user@`

### "openclaw: command not found"
- Reinstall: `sudo npm install -g openclaw@latest`
- Check PATH: `which openclaw`

---

## 📊 What Gets Installed on EC2

| Component | Location | Port | Purpose |
|-----------|----------|------|---------|
| OpenClaw | `~/.openclaw/` | 18789 | AI Gateway |
| Clawdbot | `/opt/clawdbot/` | 8080 | REST API |
| Backend Client | `~/openclaw-tools/` | - | CLI tool |
| Config | `~/.openclaw/workspace/` | - | AGENTS.md |
| Services | `/etc/systemd/system/` | - | Auto-start |

---

## 🎯 Success Criteria

- [ ] ✅ Both services respond to health checks
- [ ] ✅ Can chat with AI through WebSocket (port 18789)
- [ ] ✅ Can use REST API (port 8080)
- [ ] ✅ Backend data accessible (households, tasks, etc.)
- [ ] ✅ Frontend can connect from browser
- [ ] ] Multiple AI models available

---

## 📝 Notes

- The `install.sh` script sets everything up automatically
- API keys are NOT included (you must add them after install)
- Backend URL is configured via placeholder `${BACKEND_URL}`
- All scripts have error handling (`set -e`)
- Services auto-start on boot via systemd

---

**Status: READY FOR DEPLOYMENT** ✅
