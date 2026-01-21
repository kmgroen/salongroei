#!/bin/bash
#
# Automated VPS Deployment User Setup
# Runs with password authentication - creates kasper user with limited sudo
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

echo "================================================"
echo "  Salongroei - Automated Deploy User Setup"
echo "================================================"
echo ""

# Read SSH public key from local machine
SSH_PUB_KEY=$(cat ~/.ssh/salongroei_vps.pub)
if [ -z "$SSH_PUB_KEY" ]; then
    echo -e "${RED}ERROR: Could not find ~/.ssh/salongroei_vps.pub${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found SSH public key:${NC}"
echo "  $SSH_PUB_KEY"
echo ""

# Create the remote setup script with embedded SSH key
REMOTE_SCRIPT=$(cat <<'REMOTE_EOF'
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Starting setup on VPS..."

# Configuration
DEPLOY_USER="kasper"
SSH_PUB_KEY="__SSH_KEY_PLACEHOLDER__"

echo -e "${YELLOW}[1/7] Creating user: ${DEPLOY_USER}${NC}"
if id "$DEPLOY_USER" &>/dev/null; then
    echo -e "${GREEN}✓ User already exists${NC}"
else
    useradd -m -s /bin/bash "$DEPLOY_USER"
    echo -e "${GREEN}✓ User created${NC}"
fi

echo -e "${YELLOW}[2/7] Setting up SSH key authentication...${NC}"
mkdir -p /home/${DEPLOY_USER}/.ssh
echo "$SSH_PUB_KEY" > /home/${DEPLOY_USER}/.ssh/authorized_keys
chown -R ${DEPLOY_USER}:${DEPLOY_USER} /home/${DEPLOY_USER}/.ssh
chmod 700 /home/${DEPLOY_USER}/.ssh
chmod 600 /home/${DEPLOY_USER}/.ssh/authorized_keys
echo -e "${GREEN}✓ SSH key added${NC}"

echo -e "${YELLOW}[3/7] Creating limited sudo permissions...${NC}"
cat > /etc/sudoers.d/${DEPLOY_USER} << 'SUDOERS'
# Deployment user - Limited sudo permissions for salongroei.com
kasper ALL=(ALL) NOPASSWD: /usr/sbin/useradd *
kasper ALL=(ALL) NOPASSWD: /usr/sbin/userdel *
kasper ALL=(ALL) NOPASSWD: /usr/sbin/usermod *
kasper ALL=(ALL) NOPASSWD: /usr/bin/getent passwd
kasper ALL=(ALL) NOPASSWD: /bin/mkdir -p /var/www/*
kasper ALL=(ALL) NOPASSWD: /bin/mkdir -p /opt/salongroei*
kasper ALL=(ALL) NOPASSWD: /bin/chown -R www-data:www-data /var/www/*
kasper ALL=(ALL) NOPASSWD: /bin/chown -R * /home/*
kasper ALL=(ALL) NOPASSWD: /bin/chmod -R * /var/www/*
kasper ALL=(ALL) NOPASSWD: /bin/chmod -R * /home/*
kasper ALL=(ALL) NOPASSWD: /bin/chmod -R * /opt/salongroei*
kasper ALL=(ALL) NOPASSWD: /bin/chmod * /etc/sudoers.d/*
kasper ALL=(ALL) NOPASSWD: /bin/rm -f /etc/sudoers.d/temp_*
kasper ALL=(ALL) NOPASSWD: /usr/sbin/nginx -t
kasper ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
kasper ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
kasper ALL=(ALL) NOPASSWD: /bin/systemctl status nginx
kasper ALL=(ALL) NOPASSWD: /bin/systemctl is-active nginx
kasper ALL=(ALL) NOPASSWD: /usr/bin/ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*
kasper ALL=(ALL) NOPASSWD: /usr/bin/certbot *
kasper ALL=(ALL) NOPASSWD: /usr/bin/at *
kasper ALL=(ALL) NOPASSWD: /bin/cat /opt/salongroei/*
kasper ALL=(ALL) NOPASSWD: /bin/cat > /etc/nginx/sites-available/*
kasper ALL=(ALL) NOPASSWD: /bin/ls *
kasper ALL=(ALL) NOPASSWD: /usr/bin/find /var/www/*
kasper ALL=(ALL) NOPASSWD: /usr/bin/find /opt/salongroei/*
kasper ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/sudoers.d/temp_*
kasper ALL=(ALL) NOPASSWD: /usr/bin/docker *
kasper ALL=(ALL) NOPASSWD: /usr/bin/docker compose *
kasper ALL=(ALL) NOPASSWD: /usr/local/bin/docker-compose *
SUDOERS

chmod 440 /etc/sudoers.d/${DEPLOY_USER}
echo -e "${GREEN}✓ Sudo permissions configured${NC}"

echo -e "${YELLOW}[4/7] Creating /opt/salongroei directory...${NC}"
mkdir -p /opt/salongroei
chmod 755 /opt/salongroei
echo -e "${GREEN}✓ Directory created${NC}"

echo -e "${YELLOW}[5/7] Generating secret prefix for temp usernames...${NC}"
if [ -f /opt/salongroei/.temp_user_prefix ]; then
    EXISTING_PREFIX=$(cat /opt/salongroei/.temp_user_prefix)
    echo -e "${GREEN}✓ Keeping existing prefix: ${EXISTING_PREFIX}${NC}"
else
    openssl rand -hex 3 > /opt/salongroei/.temp_user_prefix
    NEW_PREFIX=$(cat /opt/salongroei/.temp_user_prefix)
    echo -e "${GREEN}✓ Prefix generated: ${NEW_PREFIX}${NC}"
fi
chmod 644 /opt/salongroei/.temp_user_prefix

echo -e "${YELLOW}[6/7] Installing 'at' command...${NC}"
if ! command -v at &> /dev/null; then
    apt-get update -qq
    apt-get install -y at
    echo -e "${GREEN}✓ 'at' installed${NC}"
else
    echo -e "${GREEN}✓ 'at' already installed${NC}"
fi
systemctl enable atd 2>/dev/null || true
systemctl start atd 2>/dev/null || true

echo -e "${YELLOW}[7/7] Creating temp user log file...${NC}"
touch /tmp/temp_users.log
chmod 644 /tmp/temp_users.log
echo -e "${GREEN}✓ Log file created${NC}"

echo ""
echo "================================================"
echo -e "${GREEN}  Setup Complete!${NC}"
echo "================================================"
echo ""
echo "Deployment user: ${DEPLOY_USER}"
echo "Temp user prefix: $(cat /opt/salongroei/.temp_user_prefix)"
echo ""
REMOTE_EOF
)

# Replace placeholder with actual SSH key
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SSH_KEY_PLACEHOLDER__/$SSH_PUB_KEY}"

# Save to temporary file
TEMP_SCRIPT="/tmp/salongroei_setup_$$.sh"
echo "$REMOTE_SCRIPT" > "$TEMP_SCRIPT"
chmod +x "$TEMP_SCRIPT"

echo -e "${YELLOW}Copying setup script to VPS...${NC}"
echo "You'll need to enter your root password"
echo ""

scp "$TEMP_SCRIPT" root@31.97.217.189:/tmp/vps_setup.sh

echo ""
echo -e "${YELLOW}Running setup on VPS...${NC}"
echo "Enter root password again:"
echo ""

ssh root@31.97.217.189 'bash /tmp/vps_setup.sh && rm /tmp/vps_setup.sh'

# Clean up local temp file
rm "$TEMP_SCRIPT"

echo ""
echo "================================================"
echo -e "${GREEN}  All Done!${NC}"
echo "================================================"
echo ""
echo -e "${YELLOW}Testing SSH access with kasper user...${NC}"
echo ""

sleep 2

if ssh -o ConnectTimeout=5 -o BatchMode=yes kasper@31.97.217.189 exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH key authentication working!${NC}"
    echo ""
    echo "You can now use: ssh kasper@31.97.217.189"
    echo "Or run: ./scripts/deploy_prod.sh"
else
    echo -e "${YELLOW}⚠ SSH test didn't work yet, but setup should be complete.${NC}"
    echo "Try manually: ssh kasper@31.97.217.189"
fi

echo ""
