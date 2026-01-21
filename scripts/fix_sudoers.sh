#!/bin/bash
#
# Fix kasper sudoers file - correct syntax and add missing commands
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Fix kasper Sudoers Configuration"
echo "================================================"
echo ""

# Create the correct sudoers file
SUDOERS_CONTENT=$(cat <<'EOF'
# Deployment user - Limited sudo permissions for salongroei.com
# User: kasper

# User management (for creating temporary SSH users)
kasper ALL=(ALL) NOPASSWD: /usr/sbin/useradd
kasper ALL=(ALL) NOPASSWD: /usr/sbin/userdel
kasper ALL=(ALL) NOPASSWD: /usr/sbin/usermod
kasper ALL=(ALL) NOPASSWD: /usr/bin/getent

# File operations
kasper ALL=(ALL) NOPASSWD: /bin/mkdir
kasper ALL=(ALL) NOPASSWD: /bin/cp
kasper ALL=(ALL) NOPASSWD: /bin/mv
kasper ALL=(ALL) NOPASSWD: /bin/chown
kasper ALL=(ALL) NOPASSWD: /bin/chmod
kasper ALL=(ALL) NOPASSWD: /bin/rm
kasper ALL=(ALL) NOPASSWD: /bin/cat
kasper ALL=(ALL) NOPASSWD: /bin/ls
kasper ALL=(ALL) NOPASSWD: /usr/bin/find
kasper ALL=(ALL) NOPASSWD: /usr/bin/tee

# Nginx operations
kasper ALL=(ALL) NOPASSWD: /usr/sbin/nginx
kasper ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
kasper ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
kasper ALL=(ALL) NOPASSWD: /bin/systemctl status nginx
kasper ALL=(ALL) NOPASSWD: /bin/systemctl is-active nginx
kasper ALL=(ALL) NOPASSWD: /usr/bin/ln

# SSL/Certbot
kasper ALL=(ALL) NOPASSWD: /usr/bin/certbot

# Temporary user management (at command for auto-deletion)
kasper ALL=(ALL) NOPASSWD: /usr/bin/at

# Docker (if using containers)
kasper ALL=(ALL) NOPASSWD: /usr/bin/docker
kasper ALL=(ALL) NOPASSWD: /usr/local/bin/docker-compose
EOF
)

# Save to temp file
TEMP_FILE="/tmp/kasper_sudoers_$$.tmp"
echo "$SUDOERS_CONTENT" > "$TEMP_FILE"

echo -e "${YELLOW}Uploading corrected sudoers file...${NC}"
echo "Enter root password:"
scp "$TEMP_FILE" root@31.97.217.189:/tmp/kasper_sudoers.tmp

# Create fix script
FIX_SCRIPT=$(cat <<'EOF'
#!/bin/bash
set -e

echo "Backing up old sudoers file..."
cp /etc/sudoers.d/kasper /etc/sudoers.d/kasper.backup 2>/dev/null || true

echo "Installing new sudoers file..."
mv /tmp/kasper_sudoers.tmp /etc/sudoers.d/kasper
chmod 440 /etc/sudoers.d/kasper

echo "Testing sudoers syntax..."
visudo -c -f /etc/sudoers.d/kasper

if [ $? -eq 0 ]; then
    echo "✓ Sudoers file is valid!"
    echo ""
    echo "Testing kasper user sudo access..."
    su - kasper -c "sudo -n mkdir -p /tmp/test_sudo && sudo -n rm -rf /tmp/test_sudo"
    echo "✓ Sudo access working!"
else
    echo "✗ Sudoers file has errors, restoring backup"
    mv /etc/sudoers.d/kasper.backup /etc/sudoers.d/kasper
    exit 1
fi
EOF
)

# Save fix script
TEMP_SCRIPT="/tmp/fix_sudoers_$$.sh"
echo "$FIX_SCRIPT" > "$TEMP_SCRIPT"

echo ""
echo -e "${YELLOW}Installing corrected sudoers file on VPS...${NC}"
echo "Enter root password again:"

# Upload and run
scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/fix_sudoers.sh
ssh root@31.97.217.189 'bash /tmp/fix_sudoers.sh && rm /tmp/fix_sudoers.sh'

# Clean up
rm "$TEMP_FILE"
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${GREEN}  Sudoers File Fixed!${NC}"
echo "================================================"
echo ""
echo "The kasper user now has proper sudo permissions."
echo "Try creating a temp user again with:"
echo "  ./scripts/deploy_prod.sh"
echo ""
