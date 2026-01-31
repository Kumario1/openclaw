#!/bin/bash
# Fix SSH key issues and deploy

set -e

OPENCLAW_IP="44.222.228.231"
KEY_PATH="/Users/princekumar/Documents/EC2 Key Pair.pem"

echo "🔧 Fixing SSH Key Permissions..."
echo "================================="

# Fix key permissions
chmod 400 "$KEY_PATH"
echo "✅ Key permissions set to 400"

# Check key format
echo ""
echo "🔍 Checking SSH key..."
head -1 "$KEY_PATH"

# Test SSH connection first
echo ""
echo "🧪 Testing SSH connection..."
if ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "ubuntu@$OPENCLAW_IP" "echo 'SSH works!'" 2>/dev/null; then
    echo "✅ SSH connection successful"
else
    echo "❌ SSH connection failed"
    echo ""
    echo "Possible issues:"
    echo "1. Wrong SSH key (should be 'EC2 Key Pair.pem')"
    echo "2. EC2 instance not running"
    echo "3. Security group doesn't allow SSH from your IP"
    echo "4. Wrong username (should be 'ubuntu')"
    echo ""
    echo "Try this command manually:"
    echo "ssh -i \"$KEY_PATH\" ubuntu@$OPENCLAW_IP"
    exit 1
fi

# Try tar method instead of scp
echo ""
echo "📦 Copying files using tar+ssh method..."
cd /Users/princekumar/openclaw

tar czf - openclaw-deploy 2>/dev/null | \
    ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "ubuntu@$OPENCLAW_IP" \
    "tar xzf - -C ~ && echo 'Files extracted successfully'"

if [ $? -eq 0 ]; then
    echo "✅ Files copied successfully"
else
    echo "❌ Failed to copy files"
    echo "Try the GitHub method in MANUAL_DEPLOY.md"
    exit 1
fi

echo ""
echo "✅ File transfer complete!"
echo ""
echo "Next steps:"
echo "1. SSH into EC2: ssh -i \"$KEY_PATH\" ubuntu@$OPENCLAW_IP"
echo "2. Follow the steps in MANUAL_DEPLOY.md"
