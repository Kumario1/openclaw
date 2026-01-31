#!/bin/bash
# EC2 Setup Script for Clawdbot Server
# Run this on your EC2 instance to set up the Clawdbot server

set -e

echo "=========================================="
echo "🤖 Clawdbot Server - EC2 Setup"
echo "=========================================="

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Python and pip
echo "🐍 Installing Python..."
sudo apt-get install -y python3 python3-pip python3-venv

# Install Node.js (for OpenClaw if needed)
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Create app directory
APP_DIR="/opt/clawdbot"
echo "📁 Creating app directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown ubuntu:ubuntu $APP_DIR

# Copy application files (assumes they are cloned/copied to the server)
# In practice, you would clone your repo here
# git clone <your-repo> $APP_DIR

echo ""
echo "=========================================="
echo "✅ System dependencies installed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Copy your application files to $APP_DIR"
echo "2. Create a Python virtual environment:"
echo "   cd $APP_DIR"
echo "   python3 -m venv venv"
echo "   source venv/bin/activate"
echo "   pip install -r backend/requirements.txt"
echo "   pip install httpx  # Additional dependency for backend client"
echo ""
echo "3. Configure environment variables:"
echo "   cp openclaw/.env.example openclaw/.env"
echo "   nano openclaw/.env  # Edit with your backend URL"
echo ""
echo "4. Start the server:"
echo "   python openclaw/clawdbot_server.py"
echo ""
echo "Or install as a systemd service (see clawdbot.service)"
echo "=========================================="
