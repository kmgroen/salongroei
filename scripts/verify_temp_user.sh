#!/bin/bash
#
# Verify temp user was created correctly
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEMP_USER="aabb94_7b559f3d"

echo "================================================"
echo "  Verify Temp User: $TEMP_USER"
echo "================================================"
echo ""

# Create verification script
VERIFY_SCRIPT=$(cat <<'EOFVERIFY'
#!/bin/bash

TEMP_USER="__TEMP_USER__"

echo "=== Verification Report for: $TEMP_USER ==="
echo ""

echo "1. Does user exist?"
if id $TEMP_USER &>/dev/null; then
    echo "✓ YES"
    id $TEMP_USER
else
    echo "✗ NO - User does not exist!"
    exit 1
fi

echo ""
echo "2. Home directory ownership:"
ls -ld /home/$TEMP_USER

echo ""
echo "3. SSH directory:"
if [ -d /home/$TEMP_USER/.ssh ]; then
    ls -ld /home/$TEMP_USER/.ssh
    echo ""
    echo "Authorized keys file:"
    ls -l /home/$TEMP_USER/.ssh/authorized_keys
    echo ""
    echo "Key content:"
    cat /home/$TEMP_USER/.ssh/authorized_keys
else
    echo "✗ SSH directory does not exist!"
fi

echo ""
echo "4. Sudoers file:"
if [ -f /etc/sudoers.d/temp_${TEMP_USER} ]; then
    echo "✓ Sudoers file exists"
    ls -l /etc/sudoers.d/temp_${TEMP_USER}
else
    echo "✗ Sudoers file missing!"
fi

echo ""
echo "5. Groups:"
groups $TEMP_USER

echo ""
echo "=== Testing SSH from VPS to VPS ==="
su - $TEMP_USER -c "ssh -o StrictHostKeyChecking=no -o BatchMode=yes localhost exit 2>&1" && echo "✓ SSH key works!" || echo "✗ SSH key doesn't work"

EOFVERIFY
)

# Replace placeholder
VERIFY_SCRIPT="${VERIFY_SCRIPT//__TEMP_USER__/$TEMP_USER}"

# Save to temp file
TEMP_SCRIPT="/tmp/verify_temp_$$.sh"
echo "$VERIFY_SCRIPT" > "$TEMP_SCRIPT"

echo -e "${YELLOW}Running verification on VPS...${NC}"
echo "Enter root password:"

# Upload and run
scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/verify_temp.sh
ssh root@31.97.217.189 'bash /tmp/verify_temp.sh && rm /tmp/verify_temp.sh'

# Clean up
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${YELLOW}Now testing from your Mac...${NC}"
echo "================================================"
echo ""

echo "Attempting SSH connection (should prompt for passphrase, NOT password)..."
ssh -v -o ConnectTimeout=5 $TEMP_USER@31.97.217.189 'echo "SUCCESS!"' 2>&1 | grep -E "debug1: Offering|Authenticat|Permission denied" | head -20

echo ""
