#!/bin/bash
#
# Fix SSH key mismatch - use default id_ed25519 key
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Fix SSH Key Mismatch"
echo "================================================"
echo ""

# Use the default id_ed25519 key (what SSH offers by default)
SSH_PUB_KEY=$(cat ~/.ssh/id_ed25519.pub)
if [ -z "$SSH_PUB_KEY" ]; then
    echo -e "${RED}ERROR: Could not find ~/.ssh/id_ed25519.pub${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Using your default SSH key (id_ed25519)${NC}"
echo "  $SSH_PUB_KEY"
echo ""

# Create temporary file with the correct SSH key
TEMP_KEY="/tmp/kasper_correct_key_$$.pub"
echo "$SSH_PUB_KEY" > "$TEMP_KEY"

echo -e "${YELLOW}Uploading correct SSH key to VPS...${NC}"
echo "Enter root password:"
scp "$TEMP_KEY" root@31.97.217.189:/tmp/kasper_authorized_keys

# Create fix script
FIX_SCRIPT=$(cat <<'EOF'
#!/bin/bash
set -e

echo "Replacing SSH key with correct one..."

# Replace authorized_keys with correct key
mv /tmp/kasper_authorized_keys /home/kasper/.ssh/authorized_keys

# Set correct permissions
chown kasper:kasper /home/kasper/.ssh/authorized_keys
chmod 600 /home/kasper/.ssh/authorized_keys

echo ""
echo "New SSH key installed:"
cat /home/kasper/.ssh/authorized_keys
echo ""
echo "✓ SSH key updated!"
EOF
)

# Save fix script
TEMP_SCRIPT="/tmp/fix_key_$$.sh"
echo "$FIX_SCRIPT" > "$TEMP_SCRIPT"

echo ""
echo -e "${YELLOW}Installing correct key on VPS...${NC}"
echo "Enter root password again:"

# Upload and run
scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/fix_key.sh
ssh root@31.97.217.189 'bash /tmp/fix_key.sh && rm /tmp/fix_key.sh'

# Clean up
rm "$TEMP_KEY"
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${GREEN}  Testing SSH Connection${NC}"
echo "================================================"
echo ""

sleep 2

# Test with default key
if ssh -o ConnectTimeout=5 -o BatchMode=yes kasper@31.97.217.189 'echo "SSH working!"' 2>/dev/null; then
    echo -e "${GREEN}✓✓✓ SUCCESS! SSH key authentication working!${NC}"
    echo ""
    echo "You can now use:"
    echo "  ssh kasper@31.97.217.189"
    echo "  ./scripts/deploy_prod.sh"
else
    echo -e "${RED}Still having issues. Try manually:${NC}"
    echo "  ssh kasper@31.97.217.189"
fi

echo ""
