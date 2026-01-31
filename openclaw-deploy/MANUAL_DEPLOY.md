# 🔧 Manual Deployment Guide

## SSH Key Troubleshooting

The "Permission denied (publickey)" error usually means:
1. Wrong SSH key file
2. Key permissions are too open
3. Wrong username (should be `ubuntu` for Ubuntu AMIs)
4. EC2 instance not ready yet

---

## Step 1: Fix SSH Key Issues

### Check Key Permissions
```bash
# Fix permissions
chmod 400 "/Users/princekumar/Documents/EC2 Key Pair.pem"

# Verify
ls -la "/Users/princekumar/Documents/EC2 Key Pair.pem"
# Should show: -r--------@ 1 princekumar  staff  1674 Jan 31 03:00
```

### Test SSH Connection First
```bash
# Test basic SSH connection
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=10 \
  ubuntu@44.222.228.231

# If this fails, check:
# 1. Is the EC2 instance running? Check AWS Console
# 2. Is the public IP correct? 44.222.228.231
# 3. Is the security group allowing SSH (port 22) from your IP?
```

### Common Fixes
```bash
# If you have multiple keys, specify explicitly
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  -o IdentitiesOnly=yes \
  ubuntu@44.222.228.231

# Add verbose output to see what's happening
ssh -v -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  ubuntu@44.222.228.231
```

---

## Step 2: Alternative File Transfer Methods

### Method A: GitHub Upload

1. **Create a new GitHub repository** (e.g., `openclaw-lpl`)

2. **Upload the files:**
```bash
cd /Users/princekumar/openclaw/openclaw-deploy

# Initialize git
git init
git add .
git commit -m "Initial OpenClaw deployment"

# Add your GitHub repo
git remote add origin https://github.com/YOUR_USERNAME/openclaw-lpl.git
git push -u origin main
```

3. **Clone on EC2:**
```bash
# SSH into EC2 first
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  ubuntu@44.222.228.231

# Clone the repo
git clone https://github.com/YOUR_USERNAME/openclaw-lpl.git
cd openclaw-lpl
```

### Method B: Zip and Upload

1. **Create zip on your local machine:**
```bash
cd /Users/princekumar/openclaw
zip -r openclaw-deploy.zip openclaw-deploy/
```

2. **Use AWS S3 or any file transfer:**
```bash
# Option 1: Upload to S3 and download on EC2
aws s3 cp openclaw-deploy.zip s3://your-bucket/

# On EC2:
aws s3 cp s3://your-bucket/openclaw-deploy.zip ~/
unzip openclaw-deploy.zip
```

3. **Or use a simple HTTP server temporarily:**
```bash
# On your local machine
cd /Users/princekumar/openclaw
python3 -m http.server 8080 &

# Then on EC2:
curl -O http://YOUR_LOCAL_IP:8080/openclaw-deploy.zip
unzip openclaw-deploy.zip
```

### Method C: Copy-Paste (Last Resort)

1. **SSH into EC2:**
```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  ubuntu@44.222.228.231
```

2. **Create files manually:**
```bash
# Create directory
mkdir -p ~/openclaw-deploy/config
mkdir -p ~/openclaw-deploy/scripts
mkdir -p ~/openclaw-deploy/openclaw
mkdir -p ~/openclaw-deploy/src

# Then copy-paste each file content using nano
nano ~/openclaw-deploy/config/openclaw.json
# Paste content, save with Ctrl+O, Enter, Ctrl+X
```

---

## Step 3: Full Manual Deployment Steps

Once you have the files on EC2, run these commands:

### SSH into EC2
```bash
ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  ubuntu@44.222.228.231
```

### Set Environment Variables
```bash
export BACKEND_URL="http://54.221.139.68:8000"
export BACKEND_IP="54.221.139.68"
```

### Update Configuration Files
```bash
cd ~/openclaw-deploy

# Update AGENTS.md
sed -i "s|\\\${BACKEND_URL}|$BACKEND_URL|g" config/AGENTS.md

# Update service files
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/openclaw.service
sed -i "s|BACKEND_URL=.*|BACKEND_URL=$BACKEND_URL|g" scripts/clawdbot.service
```

### Run Installation
```bash
# Make install script executable
chmod +x scripts/install.sh

# Run installer (takes 5-10 minutes)
sudo BACKEND_URL=$BACKEND_URL ./scripts/install.sh
```

### Add API Keys
```bash
sudo nano /etc/environment
```
Add:
```
ANTHROPIC_API_KEY=sk-ant-api03-YOUR-KEY-HERE
OPENAI_API_KEY=sk-proj-YOUR-KEY-HERE
BACKEND_URL=http://54.221.139.68:8000
```

### Start Services
```bash
# Reload environment
source /etc/environment

# Run onboarding
openclaw onboard

# Start services
sudo systemctl start openclaw
sudo systemctl start clawdbot

# Check status
sudo systemctl status openclaw
sudo systemctl status clawdbot
```

---

## Step 4: Verify Installation

```bash
# Test OpenClaw
curl http://localhost:18789/health

# Test Clawdbot API
curl http://localhost:8080/health

# Test backend connection
curl http://54.221.139.68:8000/health/live

# Run verification script
sudo ./scripts/verify-connections.sh
```

---

## Step 5: Test from Local Machine

```bash
# Test OpenClaw Gateway
curl http://44.222.228.231:18789/health

# Test Clawdbot API
curl http://44.222.228.231:8080/health
```

---

## 🔥 Quick Fix: One-Liner Copy

If SSH works but SCP doesn't, try this:

```bash
# Use tar and SSH pipe
tar czf - openclaw-deploy | \
  ssh -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  ubuntu@44.222.228.231 "tar xzf - -C ~"
```

---

## ⚠️ Security Group Check

Make sure your OpenClaw EC2 security group allows SSH (port 22) from your IP:

1. Go to AWS Console → EC2 → Instances
2. Click on your OpenClaw instance (44.222.228.231)
3. Click on the Security Group
4. Check Inbound Rules:
   - Type: SSH
   - Port: 22
   - Source: Should be your IP (or 0.0.0.0/0 for testing)

If your IP changed, update the security group rule!

---

## 📞 Still Having Issues?

Try these commands and share the output:

```bash
# Test SSH verbose
ssh -v -i "/Users/princekumar/Documents/EC2 Key Pair.pem" \
  ubuntu@44.222.228.231 2>&1 | head -50

# Check instance status
aws ec2 describe-instances \
  --instance-ids i-YOUR_INSTANCE_ID \
  --query 'Reservations[0].Instances[0].State.Name'
```
