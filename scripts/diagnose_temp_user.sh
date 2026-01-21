#!/bin/bash
#
# Diagnose temp user SSH issue
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEMP_USER="aabb94_30a3dc0e"

echo "================================================"
echo "  Diagnose Temp User: $TEMP_USER"
echo "================================================"
echo ""

# Create diagnostic script
DIAG_SCRIPT=$(cat <<'EOFDIAG'
#!/bin/bash

TEMP_USER="__TEMP_USER__"

echo "=== Checking temp user: $TEMP_USER ==="
echo ""

echo "1. User exists?"
id $TEMP_USER || echo "User does not exist"

echo ""
echo "2. Home directory:"
ls -la /home/ | grep $TEMP_USER || echo "No home directory"

echo ""
echo "3. SSH directory:"
ls -la /home/$TEMP_USER/.ssh/ 2>/dev/null || echo "No .ssh directory"

echo ""
echo "4. Authorized keys file:"
if [ -f /home/$TEMP_USER/.ssh/authorized_keys ]; then
    ls -la /home/$TEMP_USER/.ssh/authorized_keys
    echo ""
    echo "Content:"
    cat /home/$TEMP_USER/.ssh/authorized_keys
else
    echo "authorized_keys file does not exist!"
fi

echo ""
echo "5. Kasper's SSH key for comparison:"
cat /home/kasper/.ssh/authorized_keys

echo ""
echo "=== Fixing SSH key ==="

# Copy kasper's key to temp user
mkdir -p /home/$TEMP_USER/.ssh
cp /home/kasper/.ssh/authorized_keys /home/$TEMP_USER/.ssh/authorized_keys
chown -R $TEMP_USER:$TEMP_USER /home/$TEMP_USER/.ssh
chmod 700 /home/$TEMP_USER/.ssh
chmod 600 /home/$TEMP_USER/.ssh/authorized_keys

echo "✓ SSH key copied from kasper to $TEMP_USER"
echo ""
echo "Verification:"
ls -la /home/$TEMP_USER/.ssh/
cat /home/$TEMP_USER/.ssh/authorized_keys

EOFDIAG
)

# Replace placeholder
DIAG_SCRIPT="${DIAG_SCRIPT//__TEMP_USER__/$TEMP_USER}"

# Save to temp file
TEMP_SCRIPT="/tmp/diag_temp_user_$$.sh"
echo "$DIAG_SCRIPT" > "$TEMP_SCRIPT"

echo -e "${YELLOW}Running diagnostics on VPS...${NC}"
echo "Enter root password:"

# Upload and run
scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/diag_temp.sh
ssh root@31.97.217.189 'bash /tmp/diag_temp.sh && rm /tmp/diag_temp.sh'

# Clean up
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${GREEN}  Testing SSH Connection${NC}"
echo "================================================"
echo ""

sleep 2

echo "Try SSH now (with passphrase, not password):"
echo "  ssh $TEMP_USER@31.97.217.189"
echo ""
