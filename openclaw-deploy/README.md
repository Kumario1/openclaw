# 🤖 OpenClaw + Clawdbot Server

**Hybrid AI Assistant for LPL Transition OS**

This deployment combines:
- **OpenClaw Gateway** (port 18789) - AI chat with multiple models
- **Clawdbot API Server** (port 8080) - REST API for backend integration

## Quick Deploy to EC2

```bash
# 1. Clone on EC2
git clone https://github.com/YOUR_USERNAME/openclaw-deploy.git
cd openclaw-deploy

# 2. Set your backend URL
export BACKEND_URL="http://YOUR_BACKEND_EC2_IP:8000"

# 3. Run install script
chmod +x scripts/install.sh
sudo ./scripts/install.sh

# 4. Add your API keys
sudo nano /etc/environment
# Add:
# ANTHROPIC_API_KEY=sk-ant-api03-...
# OPENAI_API_KEY=sk-proj-...

# 5. Run OpenClaw onboarding
openclaw onboard

# 6. Start services
sudo systemctl start openclaw
sudo systemctl start clawdbot

# 7. Check status
curl http://localhost:18789/health
curl http://localhost:8080/health
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EC2 Instance                             │
│  ┌─────────────────────┐    ┌──────────────────────────┐   │
│  │  OpenClaw Gateway   │    │  Clawdbot API Server     │   │
│  │  Port: 18789        │    │  Port: 8080              │   │
│  │  • WebSocket chat   │    │  • REST API endpoints    │   │
│  │  • Multi-model AI   │    │  • Direct backend calls  │   │
│  │  • AGENTS.md prompts│    │  • CORS enabled          │   │
│  └──────────┬──────────┘    └──────────┬───────────────┘   │
│             │                          │                    │
│             └──────────┬───────────────┘                    │
│                        │                                    │
│                        ▼                                    │
│            ┌─────────────────────┐                         │
│            │  Backend Client     │                         │
│            │  (Python/httpx)     │                         │
│            └──────────┬──────────┘                         │
└───────────────────────┼─────────────────────────────────────┘
                        │
                        │ HTTP API
                        ▼
            ┌─────────────────────┐
            │  Transition OS      │
            │  Backend            │
            │  Port: 8000         │
            └──────────┬──────────┘
                       │
                       │ SQL
                       ▼
            ┌─────────────────────┐
            │  Database           │
            │  (SQLite/Postgres)  │
            └─────────────────────┘
```

## Available AI Models

| Model Key | Provider | Model | Use Case |
|-----------|----------|-------|----------|
| `default` | Anthropic | claude-sonnet-4 | Balanced |
| `fast` | Anthropic | claude-haiku | Quick responses |
| `powerful` | Anthropic | claude-opus-4-5 | Complex analysis |
| `gpt4` | OpenAI | gpt-4o | Alternative powerful |
| `gpt4-mini` | OpenAI | gpt-4o-mini | Fast GPT |
| `local` | Ollama | llama3.2 | Offline/local |

## API Endpoints

### OpenClaw Gateway (WebSocket)
- `ws://ec2-ip:18789` - WebSocket chat interface

### Clawdbot API Server (REST)
- `GET /health` - Health check
- `POST /chat` - Natural language chat
- `GET /households` - List households
- `GET /households/{id}` - Get household details
- `POST /tasks/{id}/complete` - Complete task
- `POST /documents/validate` - Validate document
- `GET /households/{id}/meeting-pack` - Meeting pack

## Configuration

### Backend URL
Edit in `/etc/systemd/system/openclaw.service`:
```ini
Environment="BACKEND_URL=http://YOUR_BACKEND_IP:8000"
```

Then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart openclaw clawdbot
```

### AI Prompts
Edit `~/.openclaw/workspace/AGENTS.md` to customize behavior.

## Environment Variables

Add to `/etc/environment`:
```bash
# Required
BACKEND_URL=http://your-backend-ip:8000

# For AI models
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...

# Optional
BACKEND_API_KEY=your-secret-key
LOG_LEVEL=INFO
```

## Monitoring

```bash
# View logs
sudo journalctl -u openclaw -f
sudo journalctl -u clawdbot -f

# Check status
sudo systemctl status openclaw
sudo systemctl status clawdbot
```

## Security Group (AWS EC2)

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | My IP | SSH access |
| Custom TCP | 18789 | Anywhere | OpenClaw Gateway |
| Custom TCP | 8080 | Anywhere | Clawdbot API |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| OpenClaw won't start | Run `openclaw doctor` |
| Can't connect to backend | Check `BACKEND_URL` and security groups |
| CORS errors | Already enabled for all origins (restrict in production) |
| Model errors | Check API keys in `/etc/environment` |

## Frontend Integration

```javascript
// Connect to OpenClaw WebSocket
const ws = new WebSocket('ws://EC2_IP:18789');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'message',
    content: 'Show me the dashboard'
  }));
};

// Or use REST API
const response = await fetch('http://EC2_IP:8080/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ message: 'Show me the dashboard' })
});
```
