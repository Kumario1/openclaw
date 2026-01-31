# 🤖 OpenClaw for LPL Transition OS

AI Assistant for advisor onboarding and transitions.

## Quick Deploy

```bash
# 1. Clone on EC2
git clone https://github.com/YOUR_USERNAME/openclaw-lpl.git
cd openclaw-lpl

# 2. Install (one command)
chmod +x scripts/install.sh && sudo ./scripts/install.sh

# 3. Configure backend URL
export BACKEND_URL="http://YOUR_BACKEND_EC2_IP:8000"
sudo sed -i "s|CHANGE_ME:8000|$BACKEND_URL|g" /etc/systemd/system/openclaw.service

# 4. Configure OpenClaw
openclaw onboard

# 5. Start
sudo systemctl start openclaw
```

## Status Check

```bash
# Check if running
curl http://localhost:18789/health

# View logs
sudo journalctl -u openclaw -f
```

## Configuration

- Main config: `~/.openclaw/openclaw.json`
- AI prompts: `~/.openclaw/workspace/AGENTS.md`
- Backend URL: Edit `/etc/systemd/system/openclaw.service`

## Architecture

```
User → OpenClaw (this repo) → Backend API → Database
```

See [DEPLOY.md](DEPLOY.md) for full details.
