# Deploy OpenClaw to EC2

## Architecture

OpenClaw runs on its own EC2 instance and connects to your Transition OS backend via REST API.

```
┌─────────────────────┐      HTTP API      ┌─────────────────────┐
│   EC2 Instance 1    │  ───────────────►  │   EC2 Instance 2    │
│   🤖 OpenClaw       │                    │   🔧 Backend        │
│   Port: 18789       │                    │   Port: 8000        │
└─────────────────────┘                    └──────────┬──────────┘
       ▲                                              │
       │ WebSocket                                    │ SQL
       │                                              ▼
┌──────┴──────┐                              ┌─────────────────┐
│  Frontend   │                              │   Database      │
└─────────────┘                              └─────────────────┘
```

## Launch EC2 Instance

| Setting | Value |
|---------|-------|
| **AMI** | Ubuntu 24.04 LTS |
| **Instance Type** | t3.medium (minimum) |
| **Storage** | 30 GB |
| **Security Group** | Create new |

### Security Group Rules

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | My IP | SSH access |
| Custom TCP | 18789 | Anywhere | OpenClaw Gateway |
| Custom TCP | 8080 | Anywhere | HTTP API (optional) |

## Deploy Steps

```bash
# SSH into EC2
ssh -i "key.pem" ubuntu@<EC2_PUBLIC_IP>

# Clone this repo
git clone https://github.com/YOUR_USERNAME/openclaw-lpl.git
cd openclaw-lpl

# Run install script
sudo ./scripts/install.sh

# Configure backend connection
export BACKEND_URL="http://YOUR_BACKEND_IP:8000"

# Update AGENTS.md with backend URL
sed -i "s|CHANGE_ME_BACKEND_IP:8000|$BACKEND_URL|g" ~/.openclaw/workspace/AGENTS.md

# Update service file
sudo sed -i "s|CHANGE_ME:8000|$BACKEND_URL|g" /etc/systemd/system/openclaw.service
sudo systemctl daemon-reload

# Run OpenClaw onboarding
openclaw onboard

# Start service
sudo systemctl start openclaw

# Check status
sudo systemctl status openclaw
```

## Test Connection

```bash
# Test OpenClaw
curl http://localhost:18789/health

# Test from local machine
curl http://<EC2_IP>:18789/health

# Test backend connection (from OpenClaw EC2)
curl $BACKEND_URL/health/live
```

## Configuration

### Edit AI Prompts

```bash
nano ~/.openclaw/workspace/AGENTS.md
```

### Environment Variables

```bash
# Add to /etc/environment
sudo nano /etc/environment

BACKEND_URL=http://your-backend-ip:8000
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
```

## Update Deployment

```bash
# On EC2
cd ~/openclaw-lpl
git pull
sudo systemctl restart openclaw
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't connect | Check security group allows port 18789 |
| Backend 403 | Check CORS settings in backend |
| OpenClaw won't start | Run `openclaw doctor` |
| Changes not applied | Restart: `sudo systemctl restart openclaw` |
