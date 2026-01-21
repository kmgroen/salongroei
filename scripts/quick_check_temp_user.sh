#!/bin/bash
#
# Quick check of latest temp user
#

TEMP_USER="aabb94_1297adb2"

echo "Checking $TEMP_USER via kasper user..."

ssh -o ConnectTimeout=10 kasper@31.97.217.189 << EOFREMOTE
echo "=== User Info ==="
id $TEMP_USER 2>&1

echo ""
echo "=== Home Directory ==="
sudo ls -la /home/$TEMP_USER 2>&1

echo ""
echo "=== SSH Directory ==="
sudo ls -la /home/$TEMP_USER/.ssh/ 2>&1

echo ""
echo "=== Authorized Keys ==="
sudo cat /home/$TEMP_USER/.ssh/authorized_keys 2>&1

echo ""
echo "=== Comparing with Kasper Key ==="
echo "Kasper key:"
cat ~/.ssh/authorized_keys
echo ""
echo "Temp user key:"
sudo cat /home/$TEMP_USER/.ssh/authorized_keys

echo ""
echo "=== Match? ==="
if diff <(cat ~/.ssh/authorized_keys) <(sudo cat /home/$TEMP_USER/.ssh/authorized_keys) > /dev/null 2>&1; then
    echo "✓ Keys MATCH"
else
    echo "✗ Keys DO NOT MATCH"
fi

EOFREMOTE
