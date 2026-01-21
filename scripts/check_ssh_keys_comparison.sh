#!/bin/bash
#
# Compare SSH keys - local, kasper, and temp user
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

TEMP_USER="aabb94_30a3dc0e"
OUTPUT_FILE="/tmp/ssh_key_comparison_$$.txt"

echo "================================================"
echo "  SSH Key Comparison Report"
echo "================================================"
echo ""

# Get local SSH public key
LOCAL_KEY=$(cat ~/.ssh/id_ed25519.pub)

echo -e "${YELLOW}Generating comparison report...${NC}"
echo ""

# Create comparison script
COMPARE_SCRIPT=$(cat <<'EOFCOMPARE'
#!/bin/bash

TEMP_USER="__TEMP_USER__"
LOCAL_KEY="__LOCAL_KEY__"

echo "==============================================="
echo "  SSH Key Comparison Report"
echo "  Generated: $(date)"
echo "==============================================="
echo ""

echo "1. LOCAL KEY (from your Mac):"
echo "---------------------------------------------"
echo "$LOCAL_KEY"
echo ""

echo "2. KASPER USER KEY (on VPS):"
echo "---------------------------------------------"
if [ -f /home/kasper/.ssh/authorized_keys ]; then
    cat /home/kasper/.ssh/authorized_keys
else
    echo "ERROR: Kasper authorized_keys not found!"
fi
echo ""

echo "3. TEMP USER KEY (on VPS):"
echo "---------------------------------------------"
if [ -f /home/$TEMP_USER/.ssh/authorized_keys ]; then
    cat /home/$TEMP_USER/.ssh/authorized_keys
else
    echo "ERROR: Temp user authorized_keys not found!"
fi
echo ""

echo "4. COMPARISON:"
echo "---------------------------------------------"
KASPER_KEY=$(cat /home/kasper/.ssh/authorized_keys 2>/dev/null)
TEMP_KEY=$(cat /home/$TEMP_USER/.ssh/authorized_keys 2>/dev/null)

if [ "$LOCAL_KEY" = "$KASPER_KEY" ]; then
    echo "✓ LOCAL matches KASPER"
else
    echo "✗ LOCAL does NOT match KASPER"
fi

if [ "$LOCAL_KEY" = "$TEMP_KEY" ]; then
    echo "✓ LOCAL matches TEMP_USER"
else
    echo "✗ LOCAL does NOT match TEMP_USER"
fi

if [ "$KASPER_KEY" = "$TEMP_KEY" ]; then
    echo "✓ KASPER matches TEMP_USER"
else
    echo "✗ KASPER does NOT match TEMP_USER"
fi
echo ""

echo "5. TEMP USER INFO:"
echo "---------------------------------------------"
echo "User exists: $(id $TEMP_USER 2>/dev/null && echo 'YES' || echo 'NO')"
echo "Home dir: $(ls -ld /home/$TEMP_USER 2>/dev/null | awk '{print $1, $3, $4}')"
echo "SSH dir: $(ls -ld /home/$TEMP_USER/.ssh 2>/dev/null | awk '{print $1, $3, $4}')"
echo "Auth keys: $(ls -l /home/$TEMP_USER/.ssh/authorized_keys 2>/dev/null | awk '{print $1, $3, $4, $5}')"
echo ""

echo "6. SSHD CONFIGURATION:"
echo "---------------------------------------------"
echo "PubkeyAuthentication: $(grep -E '^PubkeyAuthentication' /etc/ssh/sshd_config || echo 'default (yes)')"
echo "PasswordAuthentication: $(grep -E '^PasswordAuthentication' /etc/ssh/sshd_config || echo 'default (yes)')"
echo ""

EOFCOMPARE
)

# Replace placeholders
COMPARE_SCRIPT="${COMPARE_SCRIPT//__TEMP_USER__/$TEMP_USER}"
COMPARE_SCRIPT="${COMPARE_SCRIPT//__LOCAL_KEY__/$LOCAL_KEY}"

# Save to temp file
TEMP_SCRIPT="/tmp/compare_keys_$$.sh"
echo "$COMPARE_SCRIPT" > "$TEMP_SCRIPT"

echo -e "${YELLOW}Connecting to VPS and generating report...${NC}"
echo "Enter root password:"

# Upload and run, save output
scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/compare_keys.sh
ssh root@31.97.217.189 'bash /tmp/compare_keys.sh && rm /tmp/compare_keys.sh' | tee "$OUTPUT_FILE"

# Clean up
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${GREEN}  Report saved to: $OUTPUT_FILE${NC}"
echo "================================================"
echo ""
