# 🤖 Clawdbot EC2 Setup Guide

This guide walks you through setting up **Clawdbot** (your AI assistant) on an **AWS EC2** instance, connecting it to your **Transition OS backend**, and enabling your **frontend** to communicate with it.

## Architecture Overview

```
┌─────────────┐      HTTP/WebSocket      ┌─────────────────────────────────────────┐
│             │  ──────────────────────> │                                         │
│  Frontend   │   Chat/API requests      │  🤖 Clawdbot Server (EC2)              │
│  (Local/    │                          │  • openclaw/clawdbot_server.py         │
│   Deployed) │  <────────────────────── │  • Natural language processing         │
│             │    JSON responses        │  • Backend API client                  │
└─────────────┘                          │                                         │
                                         └─────────────────┬───────────────────────┘
                                                           │
                                                           │ HTTP API calls
                                                           │ (via backend_client)
                                                           ▼
                                         ┌─────────────────────────────────────────┐
                                         │  🔧 Transition OS Backend              │
                                         │  • FastAPI + SQLAlchemy                │
                                         │  • SQLite/PostgreSQL                   │
                                         │  • Business logic & validation         │
                                         └─────────────────┬───────────────────────┘
                                                           │
                                                           │ SQL queries
                                                           ▼
                                         ┌─────────────────────────────────────────┐
                                         │  🗄️ Database                           │
                                         │  • SQLite (local) or                   │
                                         │  • PostgreSQL (RDS)                    │
                                         └─────────────────────────────────────────┘
```

## Key Principle: Security

**Important**: Clawdbot NEVER talks directly to the database. It always goes through the backend API:

```
Clawdbot → Backend API → Database
```

This ensures:
- ✅ Audit trails are preserved
- ✅ Business rules are enforced
- ✅ RBAC (Role-Based Access Control) works
- ✅ No direct database exposure

---

## Step 1: Deploy the Backend

First, ensure your Transition OS backend is deployed and accessible.

### Option A: Backend on EC2 (Same Instance)

If running both on the same EC2 instance:

```bash
# Backend runs on port 8000 (localhost only)
uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

### Option B: Backend on Separate Server

If your backend is elsewhere (e.g., AWS App Runner, another EC2):

```bash
# Note the backend URL
export BACKEND_URL="http://your-backend-ip:8000"
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for full backend deployment instructions.

---

## Step 2: Deploy Clawdbot Server on EC2

### 2.1 Launch an EC2 Instance

1. Go to AWS Console → EC2 → Launch Instance
2. **Name**: `Clawdbot-Server`
3. **OS**: Ubuntu 24.04 LTS
4. **Instance Type**: `t3.micro` (or larger for production)
5. **Security Group**: Create new with these rules:
   - SSH (port 22) from My IP
   - Custom TCP (port 8080) from Anywhere (or your frontend IP)
6. **Key Pair**: Create or select existing
7. Launch

### 2.2 Connect and Setup

```bash
# SSH into your EC2 instance
ssh -i "your-key.pem" ubuntu@<your-ec2-public-ip>

# Clone your repository
git clone <your-repo-url>
cd LPLHackathon-1

# Run the setup script
chmod +x openclaw/ec2-clawdbot-setup.sh
./openclaw/ec2-clawdbot-setup.sh
```

### 2.3 Install Python Dependencies

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt
pip install httpx  # Required for backend client
```

### 2.4 Configure Environment

```bash
# Copy environment template
cp openclaw/.env.example openclaw/.env

# Edit the file
nano openclaw/.env
```

Update with your values:

```env
# Backend URL (required)
# If backend is on same EC2: http://localhost:8000
# If backend is elsewhere: http://backend-server-ip:8000
BACKEND_URL=http://localhost:8000

# Clawdbot Server Configuration
CLAWDBOT_HOST=0.0.0.0
CLAWDBOT_PORT=8080

# Logging
LOG_LEVEL=INFO
```

### 2.5 Start the Server (Manual)

Test the server:

```bash
python openclaw/clawdbot_server.py
```

You should see:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🤖 Clawdbot Server (EC2)                                ║
║                                                           ║
║   Backend: http://localhost:8000                          ║
║   Port:    8080                                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

Test the health endpoint:

```bash
curl http://localhost:8080/health
```

### 2.6 Install as Systemd Service (Production)

For production, run Clawdbot as a systemd service:

```bash
# Update the service file with correct paths
sudo cp openclaw/clawdbot.service /etc/systemd/system/

# Edit the service file if needed
sudo nano /etc/systemd/system/clawdbot.service

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable clawdbot
sudo systemctl start clawdbot

# Check status
sudo systemctl status clawdbot

# View logs
sudo journalctl -u clawdbot -f
```

---

## Step 3: Configure the Frontend

### 3.1 Environment Variables

In your frontend directory:

```bash
cd frontend
cp .env.example .env
```

Edit `.env`:

```env
# URL of your Clawdbot server on EC2
VITE_CLAWDBOT_URL=http://<your-ec2-public-ip>:8080

# Backend URL (if frontend connects directly)
VITE_BACKEND_URL=http://<backend-ip>:8000
```

### 3.2 Use the Clawdbot Service

Import and use the service in your components:

```jsx
import { clawdbotService } from './api/clawdbotService';

// In your component
async function handleSendMessage(message) {
  try {
    const response = await clawdbotService.chat(message);
    console.log('Bot response:', response.response);
    console.log('Data:', response.data);
  } catch (error) {
    console.error('Error:', error.message);
  }
}

// Or use the React component
import ClawdbotChat from './components/ClawdbotChat';

function App() {
  return (
    <div>
      <ClawdbotChat />
    </div>
  );
}
```

---

## API Endpoints

Your Clawdbot server exposes these endpoints:

### Chat Interface
- `POST /chat` - Natural language interaction
  ```json
  {
    "message": "What's the status of the Smith household?",
    "session_id": "user-123",
    "context": {}
  }
  ```

### Data Endpoints (Direct API)
- `GET /health` - Health check
- `GET /households` - List all households
- `GET /households/{id}` - Get household details
- `POST /tasks/{id}/complete` - Complete a task
- `GET /households/{id}/meeting-pack` - Generate meeting pack
- `POST /documents/validate` - Validate document
- `GET /predictions/eta/{workflow_id}` - Get ETA

---

## Testing the Connection

### 1. Test Backend is Accessible

```bash
# From EC2 instance
curl http://localhost:8000/health/live
```

### 2. Test Clawdbot Server

```bash
# From EC2 instance
curl http://localhost:8080/health

# From your local machine
curl http://<ec2-public-ip>:8080/health
```

### 3. Test Chat Endpoint

```bash
curl -X POST http://<ec2-public-ip>:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the dashboard"}'
```

### 4. Test from Frontend

Open your frontend and try sending a message to Clawdbot.

---

## Troubleshooting

### Connection Refused

**Problem**: Can't connect to Clawdbot server

**Solutions**:
1. Check security group allows port 8080
2. Verify server is running: `sudo systemctl status clawdbot`
3. Check logs: `sudo journalctl -u clawdbot -f`

### Backend Connection Failed

**Problem**: Clawdbot can't connect to backend

**Solutions**:
1. Verify backend is running
2. Check `BACKEND_URL` in environment
3. Test from EC2: `curl http://localhost:8000/health/live`

### CORS Errors

**Problem**: Frontend gets CORS errors

**Solution**: The Clawdbot server already has CORS enabled for all origins in development. For production, update the `allow_origins` in `clawdbot_server.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-frontend-domain.com"],  # Update this
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## Production Considerations

### 1. Use HTTPS

For production, put Clawdbot behind a load balancer or use a reverse proxy with SSL:

```
Frontend (HTTPS) → Load Balancer (HTTPS) → Clawdbot (HTTP on localhost)
```

### 2. Authentication

Add API key authentication:

1. Set `BACKEND_API_KEY` environment variable
2. Frontend sends `Authorization: Bearer <token>` header
3. Clawdbot validates and forwards to backend

### 3. Database

Use PostgreSQL on RDS instead of SQLite for production:

```env
BACKEND_URL=http://backend-server:8000
DATABASE_URL=postgresql://user:pass@rds-endpoint:5432/dbname
```

### 4. Monitoring

Set up CloudWatch or similar for monitoring:

```bash
# View logs
sudo journalctl -u clawdbot -f

# Check resource usage
htop
```

---

## File Reference

| File | Purpose |
|------|---------|
| `openclaw/clawdbot_server.py` | FastAPI server that runs on EC2 |
| `openclaw/clawdbot_backend_client.py` | Client for backend API communication |
| `openclaw/clawdbot.service` | Systemd service configuration |
| `openclaw/ec2-clawdbot-setup.sh` | EC2 setup script |
| `openclaw/.env.example` | Environment template for EC2 |
| `frontend/src/api/clawdbotService.js` | Frontend API client |
| `frontend/src/components/ClawdbotChat.jsx` | React chat component |
| `frontend/.env.example` | Environment template for frontend |

---

## Next Steps

1. **Customize the chat handler** in `clawdbot_server.py` to handle more intents
2. **Add authentication** for production security
3. **Integrate OpenClaw** if you want advanced AI capabilities
4. **Add more skills** by extending the backend client

---

## Support

For issues or questions:
1. Check the logs: `sudo journalctl -u clawdbot -f`
2. Test individual components
3. Review the architecture in `ARCHITECTURE.md`
