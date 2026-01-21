#!/bin/bash
#
# Check and fix SSH server configuration for public key auth
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Check SSH Server Configuration"
echo "================================================"
echo ""

# Create diagnostic and fix script
REMOTE_SCRIPT=$(cat <<'EOF'
#!/bin/bash

echo "=== SSH Server Configuration Check ==="
echo ""

echo "1. Checking sshd_config settings:"
echo "-----------------------------------"
grep -E "^#?PubkeyAuthentication|^#?AuthorizedKeysFile|^#?PasswordAuthentication" /etc/ssh/sshd_config

echo ""
echo "2. Checking kasper user home directory permissions:"
echo "---------------------------------------------------"
ls -la /home/ | grep kasper
ls -la /home/kasper/

echo ""
echo "3. Checking SSH key file:"
echo "-------------------------"
ls -la /home/kasper/.ssh/
cat /home/kasper/.ssh/authorized_keys

echo ""
echo "4. Testing SSH key format:"
echo "--------------------------"
ssh-keygen -l -f /home/kasper/.ssh/authorized_keys || echo "Key format issue detected"

echo ""
echo "=== Applying Fix ==="
echo ""

# Ensure PubkeyAuthentication is enabled
if grep -q "^#PubkeyAuthentication" /etc/ssh/sshd_config || ! grep -q "^PubkeyAuthentication" /etc/ssh/sshd_config; then
    echo "Enabling PubkeyAuthentication..."
    # Remove any commented or existing entries
    sed -i '/^#\?PubkeyAuthentication/d' /etc/ssh/sshd_config
    # Add at the end
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
    echo "✓ PubkeyAuthentication enabled"
fi

# Ensure AuthorizedKeysFile is set correctly (or using default)
if ! grep -q "^#\?AuthorizedKeysFile" /etc/ssh/sshd_config; then
    echo "Setting AuthorizedKeysFile..."
    echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
    echo "✓ AuthorizedKeysFile configured"
fi

# Fix home directory permissions (must not be writable by others)
chmod 755 /home/kasper
echo "✓ Fixed /home/kasper permissions"

# Test sshd config
echo ""
echo "Testing sshd configuration..."
sshd -t
if [ $? -eq 0 ]; then
    echo "✓ SSH config is valid"
    echo ""
    echo "Restarting SSH service..."
    systemctl restart sshd || systemctl restart ssh
    echo "✓ SSH service restarted"
else
    echo "✗ SSH config has errors!"
    exit 1
fi

echo ""
echo "=== Final Configuration ==="
grep -E "^PubkeyAuthentication|^AuthorizedKeysFile" /etc/ssh/sshd_config

echo ""
echo "✓ All fixes applied!"
EOF
)

# Save to temp file
TEMP_SCRIPT="/tmp/check_ssh_$$.sh"
echo "$REMOTE_SCRIPT" > "$TEMP_SCRIPT"

echo -e "${YELLOW}Running SSH diagnostics and fix on VPS...${NC}"
echo "Enter root password:"
echo ""

# Upload and run
scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/check_ssh.sh
ssh root@31.97.217.189 'bash /tmp/check_ssh.sh && rm /tmp/check_ssh.sh'

# Clean up
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${GREEN}  Testing SSH Connection (Wait 5 seconds)${NC}"
echo "================================================"
echo ""

sleep 5

if ssh -o ConnectTimeout=10 -o BatchMode=yes kasper@31.97.217.189 'echo "SSH key working!"' 2>/dev/null; then
    echo -e "${GREEN}✓✓✓ SUCCESS! SSH key authentication is now working!${NC}"
    echo ""
    echo "You can now use:"
    echo "  ssh kasper@31.97.217.189"
    echo "  ./scripts/deploy_prod.sh"
else
    echo -e "${YELLOW}Still testing... try manually:${NC}"
    echo "  ssh kasper@31.97.217.189"
    echo ""
    echo "If it still asks for password, check SSH client verbose output:"
    echo "  ssh -vvv kasper@31.97.217.189"
fi

echo ""
