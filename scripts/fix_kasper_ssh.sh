#!/bin/bash
#
# Fix kasper user SSH key authentication
# Properly uploads SSH key and sets permissions
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Fix kasper SSH Key Authentication"
echo "================================================"
echo ""

# Read SSH public key from local machine
SSH_PUB_KEY=$(cat ~/.ssh/salongroei_vps.pub)
if [ -z "$SSH_PUB_KEY" ]; then
    echo -e "${RED}ERROR: Could not find ~/.ssh/salongroei_vps.pub${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found SSH public key${NC}"
echo ""

# Create temporary file with the SSH key
TEMP_KEY="/tmp/kasper_key_$$.pub"
echo "$SSH_PUB_KEY" > "$TEMP_KEY"

echo -e "${YELLOW}Copying SSH key to VPS...${NC}"
echo "Enter root password:"
scp "$TEMP_KEY" root@31.97.217.189:/tmp/kasper_authorized_keys

# Create fix script
FIX_SCRIPT=$(cat <<'EOF'
#!/bin/bash
set -e

echo "Fixing kasper user SSH setup..."

# Clean up and recreate SSH directory
rm -rf /home/kasper/.ssh
mkdir -p /home/kasper/.ssh

# Move the key file
mv /tmp/kasper_authorized_keys /home/kasper/.ssh/authorized_keys

# Set correct ownership and permissions
chown -R kasper:kasper /home/kasper/.ssh
chmod 700 /home/kasper/.ssh
chmod 600 /home/kasper/.ssh/authorized_keys

# Verify
echo ""
echo "SSH key installed:"
cat /home/kasper/.ssh/authorized_keys
echo ""
echo "Permissions:"
ls -la /home/kasper/.ssh/
echo ""
echo "✓ Fixed!"
EOF
)

# Save fix script to temp file
TEMP_SCRIPT="/tmp/fix_script_$$.sh"
echo "$FIX_SCRIPT" > "$TEMP_SCRIPT"

echo ""
echo -e "${YELLOW}Running fix script on VPS...${NC}"
echo "Enter root password again:"

# Upload and run fix script
scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/fix_kasper.sh
ssh root@31.97.217.189 'bash /tmp/fix_kasper.sh && rm /tmp/fix_kasper.sh'

# Clean up local temp files
rm "$TEMP_KEY"
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${GREEN}  Testing SSH Connection${NC}"
echo "================================================"
echo ""

sleep 2

# Test SSH connection
if ssh -o ConnectTimeout=5 -o BatchMode=yes kasper@31.97.217.189 'echo "SSH key authentication working!"' 2>/dev/null; then
    echo -e "${GREEN}✓ SUCCESS! SSH key authentication is working${NC}"
    echo ""
    echo "You can now use:"
    echo "  ssh kasper@31.97.217.189"
    echo "  ./scripts/deploy_prod.sh"
else
    echo -e "${RED}✗ Still having issues${NC}"
    echo ""
    echo "Let's check SSH server config. Run this:"
    echo "  ssh root@31.97.217.189 'grep -E \"PubkeyAuthentication|AuthorizedKeysFile\" /etc/ssh/sshd_config'"
fi

echo ""
