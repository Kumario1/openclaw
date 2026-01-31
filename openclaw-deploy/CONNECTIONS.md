# 🔌 Connection Guide

This document explains how all components connect to each other.

## Architecture Overview

```
┌──────────────┐         WebSocket/HTTP         ┌──────────────────────────┐
│              │  ────────────────────────────> │  EC2 Instance 1:         │
│   Frontend   │    ws://OPENCLAW_IP:18789      │  OpenClaw + Clawdbot     │
│  (Browser)   │    http://OPENCLAW_IP:8080     │  • Port 18789 (Gateway)  │
│              │  <──────────────────────────── │  • Port 8080 (API)       │
└──────────────┘                                └───────────┬──────────────┘
                                                            │
                                                            │ HTTP API
                                                            │ (backend_client)
                                                            ▼
                                            ┌──────────────────────────┐
                                            │  EC2 Instance 2:         │
                                            │  Transition OS Backend   │
                                            │  Port: 8000              │
                                            └───────────┬──────────────┘
                                                        │ SQL
                                                        ▼
                                            ┌──────────────────────────┐
                                            │  Database                │
                                            │  (SQLite/PostgreSQL)     │
                                            └──────────────────────────┘
```

## Component Details

### 1️⃣ Frontend → OpenClaw/Clawdbot

**Your frontend connects to EC2 Instance 1:**

```javascript
// Option A: WebSocket (Real-time chat)
const ws = new WebSocket('ws://OPENCLAW_EC2_IP:18789');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'message',
    content: 'Show me the dashboard'
  }));
};

// Option B: REST API (HTTP requests)
const response = await fetch('http://OPENCLAW_EC2_IP:8080/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ 
    message: 'Show me the dashboard',
    session_id: 'user-123'
  })
});
const data = await response.json();
console.log(data.response);
```

**What you need:**
- OpenClaw EC2 Public IP address
- Security group allows port 18789 and/or 8080
- CORS is already enabled in Clawdbot server

---

### 2️⃣ OpenClaw/Clawdbot → Backend

**EC2 Instance 1 connects to EC2 Instance 2:**

```python
# This happens automatically via backend_client.py
BACKEND_URL=http://BACKEND_EC2_IP:8000

# The client makes calls like:
GET  http://BACKEND_EC2_IP:8000/api/transitions
POST http://BACKEND_EC2_IP:8000/api/tasks/123/complete
```

**What you need:**
- Set `BACKEND_URL` in install script or service files
- Backend security group allows port 8000 from OpenClaw EC2 IP

---

### 3️⃣ Backend → Database

**This is your existing setup:**
```
FastAPI → SQLAlchemy → SQLite/PostgreSQL
```

No changes needed here.

---

## AWS Security Group Configuration

### EC2 Instance 1 (OpenClaw/Clawdbot)

| Type | Protocol | Port Range | Source | Purpose |
|------|----------|------------|--------|---------|
| SSH | TCP | 22 | My IP | Admin access |
| Custom TCP | TCP | 18789 | Anywhere | OpenClaw Gateway |
| Custom TCP | TCP | 8080 | Anywhere | Clawdbot API |

### EC2 Instance 2 (Backend)

| Type | Protocol | Port Range | Source | Purpose |
|------|----------|------------|--------|---------|
| SSH | TCP | 22 | My IP | Admin access |
| Custom TCP | TCP | 8000 | EC2 Instance 1 IP | Backend API |

**⚠️ Important:** Only allow port 8000 from EC2 Instance 1's IP or security group, not from anywhere!

---

## Connection Verification

### On OpenClaw EC2 Instance:

```bash
# Run verification script
sudo ./scripts/verify-connections.sh
```

### Manual Tests:

```bash
# 1. Test OpenClaw Gateway
curl http://localhost:18789/health

# 2. Test Clawdbot API
curl http://localhost:8080/health

# 3. Test Backend from OpenClaw EC2
curl http://BACKEND_EC2_IP:8000/health/live

# 4. Test backend client
python3 ~/openclaw-tools/backend_client.py list
```

### From Your Local Machine:

```bash
# Test from outside (replace with actual EC2 IP)
curl http://OPENCLAW_EC2_IP:18789/health
curl http://OPENCLAW_EC2_IP:8080/health
```

---

## Troubleshooting Connections

### ❌ "Connection refused" from Frontend

**Problem:** Can't connect to OpenClaw from browser

**Solutions:**
1. Check OpenClaw is running: `sudo systemctl status openclaw`
2. Check security group allows port 18789/8080
3. Verify EC2 instance has public IP
4. Check CORS settings in `clawdbot_server.py`

### ❌ "Backend connection failed"

**Problem:** OpenClaw can't reach backend

**Solutions:**
1. Verify `BACKEND_URL` is correct
2. Check backend security group allows port 8000 from OpenClaw EC2
3. Test manually: `curl $BACKEND_URL/health/live`
4. Check backend is running

### ❌ CORS errors in browser

**Problem:** Frontend can't access API due to CORS

**Solutions:**
1. Clawdbot server already has CORS enabled for all origins
2. For production, update `allow_origins` in `clawdbot_server.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-frontend-domain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## Configuration Summary

### Files to Update with Your IPs:

1. **Before deployment:**
   ```bash
   ./configure.sh
   # Enter your backend EC2 IP
   ```

2. **On OpenClaw EC2 (if needed):**
   ```bash
   # Edit service file
   sudo nano /etc/systemd/system/openclaw.service
   # Change: BACKEND_URL=http://YOUR_BACKEND_IP:8000
   
   sudo systemctl daemon-reload
   sudo systemctl restart openclaw
   ```

3. **Frontend environment:**
   ```bash
   # .env file in your frontend
   VITE_OPENCLAW_URL=ws://YOUR_OPENCLAW_EC2_IP:18789
   VITE_CLAWDBOT_URL=http://YOUR_OPENCLAW_EC2_IP:8080
   ```

---

## Quick Start Checklist

- [ ] Deploy Backend on EC2 Instance 2
- [ ] Note Backend EC2 IP address
- [ ] Run `./configure.sh` and enter Backend IP
- [ ] Deploy OpenClaw on EC2 Instance 1
- [ ] Note OpenClaw EC2 IP address
- [ ] Update frontend with OpenClaw IP
- [ ] Configure security groups
- [ ] Test connections
