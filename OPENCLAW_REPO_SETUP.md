# 🤖 OpenClaw Separate Repository Setup

Separate your **OpenClaw AI Assistant** into its own repository for independent development and deployment.

---

## Why Separate Repos?

```
┌─────────────────────────────┐         ┌─────────────────────────────┐
│   Repo 1: openclaw-lpl      │         │   Repo 2: transition-os     │
│   (AI Assistant)            │         │   (Backend System)          │
│                             │         │                             │
│   • OpenClaw config         │  HTTP   │   • FastAPI backend         │
│   • Skills/Agents           │  API    │   • Database models         │
│   • Deployment scripts      │◄───────►│   • Business logic          │
│   • AI prompts (AGENTS.md)  │         │   • API endpoints           │
│                             │         │                             │
│   Deploy to: EC2 Instance   │         │   Deploy to: EC2/RDS        │
│   (Clawdbot Server)         │         │   (Backend API)             │
└─────────────────────────────┘         └─────────────────────────────┘
```

### Benefits

- ✅ **Independent Development**: Work on AI prompts without touching backend code
- ✅ **AI-Friendly**: Give AI access to just the OpenClaw repo for configuration changes
- ✅ **Separate Deployment**: Update AI logic without redeploying backend
- ✅ **Version Control**: Track AI prompt changes separately from business logic
- ✅ **Team Separation**: Frontend/backend team vs. AI/prompt engineering team

---

## Repository Structure

### Repo 1: `openclaw-lpl` (New Repository)

```
openclaw-lpl/
├── README.md                    # Quick start guide
├── DEPLOY.md                    # EC2 deployment instructions
├── .env.example                 # Environment template
├── package.json                 # If extending with custom code
│
├── config/                      # OpenClaw configuration
│   ├── openclaw.json           # Main config
│   └── AGENTS.md               # AI assistant instructions
│
├── skills/                      # Custom skills for Transition OS
│   └── transition-os/
│       ├── SKILL.md            # Skill definition
│       └── tools.py            # Custom tools (optional)
│
├── scripts/                     # Deployment scripts
│   ├── install.sh              # One-line install
│   ├── setup-openclaw.sh       # Configuration script
│   └── clawdbot.service        # Systemd service file
│
└── src/                         # Custom extensions (optional)
    └── backend_client.py       # API client for Transition OS
```

### Repo 2: `transition-os` (Your Existing Repo)

```
transition-os/                  # No changes needed!
├── backend/                    # Your existing backend
│   ├── main.py
│   ├── models.py
│   └── routers/
├── frontend/
└── ...
```

The backend repo **doesn't need to know about OpenClaw**. It just exposes REST APIs.

---

## How It Works

```
User (WhatsApp/Slack/Web)
    │
    ▼
┌─────────────────────────────┐
│   OpenClaw Server           │  ← Repo: openclaw-lpl
│   (EC2 Instance A)          │     Deployed separately
│                             │
│   • Receives user message   │
│   • Processes with AI       │
│   • Determines intent       │
└──────────┬──────────────────┘
           │
           │ HTTP API Call
           │ GET /api/transitions
           │ POST /api/tasks/123/complete
           ▼
┌─────────────────────────────┐
│   Transition OS Backend     │  ← Repo: transition-os
│   (EC2 Instance B)          │     Your existing backend
│                             │
│   • Validates request       │
│   • Applies business rules  │
│   • Updates database        │
└──────────┬──────────────────┘
           │
           │ SQL Queries
           ▼
┌─────────────────────────────┐
│   Database                  │
│   (SQLite/RDS)              │
└─────────────────────────────┘
```

---

## Step 1: Create the OpenClaw Repository

### 1.1 Create New Repo on GitHub

```bash
# Create new repository: openclaw-lpl
github.com → New Repository → Name: openclaw-lpl
```

### 1.2 Initialize with Files

Create these files locally, then push:

#### `README.md`

```markdown
# 🤖 OpenClaw for LPL Transition OS

AI Assistant for advisor onboarding and transitions.

## Quick Start

```bash
# 1. Clone on EC2
git clone https://github.com/YOUR_USERNAME/openclaw-lpl.git
cd openclaw-lpl

# 2. Run install script
chmod +x scripts/install.sh
sudo ./scripts/install.sh

# 3. Configure
export BACKEND_URL="http://YOUR_BACKEND_EC2_IP:8000"
nano config/AGENTS.md  # Add backend URL

# 4. Start
sudo systemctl start openclaw
```

## Configuration

Edit `config/AGENTS.md` to customize AI behavior.

## Connecting to Backend

This assistant connects to Transition OS backend via REST API.
Backend must be running at: `http://backend-ip:8000`
```

#### `DEPLOY.md`

```markdown
# Deploy OpenClaw to EC2

## Prerequisites

- AWS Account
- Backend API already deployed (transition-os)
- SSH key pair

## Launch EC2 Instance

1. **AMI**: Ubuntu 24.04 LTS
2. **Instance Type**: t3.medium
3. **Security Groups**:
   - SSH (22) from My IP
   - Custom TCP (18789) from Anywhere
4. **Storage**: 30 GB

## Deploy

```bash
ssh -i "key.pem" ubuntu@<ec2-ip>

git clone https://github.com/YOUR_USERNAME/openclaw-lpl.git
cd openclaw-lpl
sudo ./scripts/install.sh
```

## Configure Backend URL

```bash
export BACKEND_URL="http://YOUR_BACKEND_IP:8000"
echo "BACKEND_URL=$BACKEND_URL" | sudo tee -a /etc/environment
sudo systemctl restart openclaw
```
```

---

## Step 2: Create Installation Script

#### `scripts/install.sh`

```bash
#!/bin/bash
set -e

echo "🤖 Installing OpenClaw for LPL Transition OS..."

# Update system
apt-get update && apt-get upgrade -y

# Install Node.js 22+
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs git

# Install OpenClaw
npm install -g openclaw@latest

# Create config directory
mkdir -p ~/.openclaw/workspace

# Copy config
cp config/AGENTS.md ~/.openclaw/workspace/AGENTS.md
cp config/openclaw.json ~/.openclaw/openclaw.json

# Install systemd service
cp scripts/clawdbot.service /etc/systemd/system/openclaw.service
systemctl daemon-reload
systemctl enable openclaw

echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Set BACKEND_URL in /etc/systemd/system/openclaw.service"
echo "2. Run: sudo systemctl start openclaw"
echo "3. Run: openclaw onboard"
```

#### `scripts/clawdbot.service`

```ini
[Unit]
Description=OpenClaw Gateway for LPL
After=network.target

[Service]
Type=simple
User=ubuntu
Environment="PATH=/usr/bin:/usr/local/bin"
Environment="BACKEND_URL=http://CHANGE_ME:8000"
Environment="NODE_ENV=production"
WorkingDirectory=/home/ubuntu/openclaw-lpl
ExecStart=/usr/bin/openclaw gateway --port 18789
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

---

## Step 3: Create Configuration Files

#### `config/AGENTS.md`

```markdown
# OpenClaw - LPL Transition OS Assistant

You are Clawdbot, an AI assistant for Transition OS, a system that manages 
advisor onboarding and household transitions for LPL Financial.

## Backend Connection

All data operations go through the Transition OS backend API.

Base URL: http://CHANGE_ME_BACKEND_IP:8000

## Core Capabilities

### 1. View Dashboard & Status
When users ask about status, dashboard, or "what's left":
- Call: GET /api/transitions
- Show: Total households, open tasks, NIGO issues

### 2. Household Information
When users ask about households or clients:
- List: GET /api/transitions
- Details: GET /api/transitions/{id}

### 3. Task Management
When users want to complete tasks:
- Complete: POST /api/tasks/{id}/complete
- Always ask for confirmation before completing

### 4. Document Validation
When users ask about documents or NIGO:
- Validate: POST /documents/validate
- Report defects clearly

### 5. Meeting Preparation
When users have meetings:
- Get pack: GET /households/{id}/meeting-pack

## Response Style

- Be professional but friendly
- Use emojis for visual clarity
- Include specific numbers (task counts, dates)
- Always cite the source (which API was called)
- Never claim to access database directly

## Example Interactions

User: "What's the status?"
Response: "📊 Dashboard: 15 households, 34 open tasks, 5 NIGO issues..."

User: "Complete task 123"
Response: "I'll mark task 123 as complete. Confirm? [Yes/No]"
```

#### `config/openclaw.json`

```json
{
  "agent": {
    "model": "anthropic/claude-opus-4-5",
    "name": "Clawdbot"
  },
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0"
  },
  "channels": {
    "webchat": {
      "enabled": true
    }
  },
  "skills": {
    "enabled": ["transition-os"]
  }
}
```

---

## Step 4: Create Backend Client (Optional)

If you want custom tools beyond OpenClaw's built-in HTTP capabilities:

#### `src/backend_client.py`

```python
#!/usr/bin/env python3
"""Backend API client for OpenClaw integration."""

import os
import json
import httpx

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")

class TransitionOSClient:
    def __init__(self):
        self.base_url = BACKEND_URL
    
    def list_households(self):
        """GET /api/transitions"""
        r = httpx.get(f"{self.base_url}/api/transitions")
        return r.json()
    
    def get_household(self, household_id: int):
        """GET /api/transitions/{id}"""
        r = httpx.get(f"{self.base_url}/api/transitions/{household_id}")
        return r.json()
    
    def complete_task(self, task_id: int, note: str = None):
        """POST /api/tasks/{id}/complete"""
        data = {"status": "COMPLETED", "note": note}
        r = httpx.post(f"{self.base_url}/api/tasks/{task_id}/complete", json=data)
        return r.json()

if __name__ == "__main__":
    import sys
    client = TransitionOSClient()
    
    if sys.argv[1] == "list":
        print(json.dumps(client.list_households(), indent=2))
    elif sys.argv[1] == "get":
        print(json.dumps(client.get_household(int(sys.argv[2])), indent=2))
    elif sys.argv[1] == "complete":
        print(json.dumps(client.complete_task(int(sys.argv[2])), indent=2))
```

---

## Step 5: Deploy to EC2

### 5.1 On Your Local Machine

```bash
# Create and push to new repo
cd openclaw-lpl
git init
git add .
git commit -m "Initial OpenClaw setup"
git remote add origin https://github.com/YOUR_USERNAME/openclaw-lpl.git
git push -u origin main
```

### 5.2 On EC2 Instance

```bash
ssh -i "key.pem" ubuntu@<openclaw-ec2-ip>

# Clone the repo
git clone https://github.com/YOUR_USERNAME/openclaw-lpl.git
cd openclaw-lpl

# Run installer
chmod +x scripts/install.sh
sudo ./scripts/install.sh

# Edit configuration with your backend IP
export BACKEND_IP="http://YOUR_BACKEND_EC2_IP:8000"
sed -i "s|CHANGE_ME_BACKEND_IP:8000|$BACKEND_IP|g" ~/.openclaw/workspace/AGENTS.md
sed -i "s|CHANGE_ME:8000|$BACKEND_IP|g" /etc/systemd/system/openclaw.service

# Configure OpenClaw
openclaw onboard

# Start service
sudo systemctl start openclaw

# Check status
sudo systemctl status openclaw
sudo journalctl -u openclaw -f
```

---

## Development Workflow

### Making Changes to OpenClaw

```bash
# On your local machine
cd openclaw-lpl

# Edit AI prompts
nano config/AGENTS.md

# Edit configuration
nano config/openclaw.json

# Commit and push
git add .
git commit -m "Update AI prompts for better task handling"
git push

# On EC2 (pull changes)
ssh ubuntu@<ec2-ip>
cd openclaw-lpl
git pull
sudo systemctl restart openclaw
```

### AI-Assisted Development

Since OpenClaw is in its own repo, you can give an AI access to just this repo:

```
AI, help me improve the AGENTS.md to handle document validation better.
The backend has these endpoints:
- POST /documents/validate
- GET /households/{id}/documents

Update the prompts to guide users through document workflows.
```

The AI can modify `config/AGENTS.md` without touching your backend code.

---

## Connecting Frontend to OpenClaw

Your frontend (in the main repo) connects to OpenClaw via WebSocket:

```javascript
// frontend/src/api/openclaw.js
const OPENCLAW_URL = 'ws://OPENCLAW_EC2_IP:18789';

const ws = new WebSocket(OPENCLAW_URL);

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'message',
    content: 'What is the dashboard status?'
  }));
};

ws.onmessage = (event) => {
  const response = JSON.parse(event.data);
  displayMessage(response.content);
};
```

---

## Security Checklist

- [ ] Backend security group only allows port 8000 from OpenClaw EC2 IP
- [ ] OpenClaw EC2 has HTTPS in production (via load balancer or reverse proxy)
- [ ] API keys or JWT tokens between OpenClaw and Backend
- [ ] Regular security updates: `sudo apt-get update && sudo apt-get upgrade`
- [ ] CloudWatch or logging for audit trails

---

## Summary

You now have:

1. **Separate Repo** (`openclaw-lpl`) for AI assistant configuration
2. **One-command deployment** (`scripts/install.sh`)
3. **Independent development** - modify AI without touching backend
4. **Clean separation** - backend team and AI team can work independently

The architecture:
```
openclaw-lpl (AI config) ──► EC2 Instance A ──► Backend API ──► Database
      ▲                                              ▲
      │                                              │
   AI edits                                     Business logic
```
