#!/bin/bash
#
# VPS Setup - Create Deployment User
# Creates a non-root user with limited sudo permissions for safe deployments
# Run this ONCE on your VPS as root to set up the deployment user
#

set -e

echo "================================================"
echo "  Salongroei VPS - Deployment User Setup"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Usage: ssh root@your-vps 'bash -s' < setup_vps_deploy_user.sh"
    exit 1
fi

# Configuration
DEPLOY_USER="kasper"
DEPLOY_USER_HOME="/home/${DEPLOY_USER}"

echo -e "${BLUE}This script will create user: ${DEPLOY_USER}${NC}"
echo -e "${BLUE}With limited sudo permissions for deployment only${NC}"
echo ""
read -p "Continue? [Y/n]: " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled"
    exit 0
fi
echo ""

echo -e "${YELLOW}[1/7] Creating user: ${DEPLOY_USER}${NC}"
if id "$DEPLOY_USER" &>/dev/null; then
    echo -e "${GREEN}✓ User already exists${NC}"
else
    useradd -m -s /bin/bash "$DEPLOY_USER"
    echo -e "${GREEN}✓ User created${NC}"
fi
echo ""

echo -e "${YELLOW}[2/7] Setting up SSH key authentication...${NC}"
echo "Please paste your PUBLIC SSH key (the content of your local ~/.ssh/id_rsa.pub or similar):"
echo -e "${BLUE}Tip: On your local Mac, run: cat ~/.ssh/id_rsa.pub | pbcopy${NC}"
echo ""
read -p "SSH Public Key: " ssh_public_key

if [ -z "$ssh_public_key" ]; then
    echo -e "${RED}ERROR: No SSH key provided${NC}"
    exit 1
fi

mkdir -p "${DEPLOY_USER_HOME}/.ssh"
echo "$ssh_public_key" > "${DEPLOY_USER_HOME}/.ssh/authorized_keys"
chown -R ${DEPLOY_USER}:${DEPLOY_USER} "${DEPLOY_USER_HOME}/.ssh"
chmod 700 "${DEPLOY_USER_HOME}/.ssh"
chmod 600 "${DEPLOY_USER_HOME}/.ssh/authorized_keys"
echo -e "${GREEN}✓ SSH key added${NC}"
echo ""

echo -e "${YELLOW}[3/7] Creating limited sudo permissions...${NC}"
cat > "/etc/sudoers.d/${DEPLOY_USER}" <<SUDOERS
# Deployment user - Limited sudo permissions for salongroei.com
# User: ${DEPLOY_USER}
# Created: $(date)

# User management (for creating temporary SSH users)
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/sbin/useradd *
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/sbin/userdel *
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/sbin/usermod *
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/getent passwd

# File system operations
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/mkdir -p /var/www/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/mkdir -p /opt/salongroei*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/chown -R www-data\:www-data /var/www/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/chown -R * /home/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/chmod -R * /var/www/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/chmod -R * /home/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/chmod -R * /opt/salongroei*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/chmod * /etc/sudoers.d/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/rm -f /etc/sudoers.d/temp_*

# Nginx operations
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/sbin/nginx -t
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/systemctl status nginx
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/systemctl is-active nginx
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*

# SSL/Certbot
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/certbot *

# Temporary user management (at command for auto-deletion)
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/at *

# Read-only operations (for debugging)
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/cat /opt/salongroei/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/ls *
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/find /var/www/*
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/find /opt/salongroei/*

# Sudoers file management (for temp users)
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/sudoers.d/temp_*

# Docker (if using containers in the future)
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/docker *
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/bin/docker compose *
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/local/bin/docker-compose *

# File writing for configs
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/cat > /etc/nginx/sites-available/*
SUDOERS

chmod 440 "/etc/sudoers.d/${DEPLOY_USER}"
echo -e "${GREEN}✓ Sudo permissions configured${NC}"
echo ""

echo -e "${YELLOW}[4/7] Creating /opt/salongroei directory...${NC}"
mkdir -p /opt/salongroei
chmod 755 /opt/salongroei
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

echo -e "${YELLOW}[5/7] Generating secret prefix for temp usernames...${NC}"
if [ -f /opt/salongroei/.temp_user_prefix ]; then
    EXISTING_PREFIX=$(cat /opt/salongroei/.temp_user_prefix)
    echo -e "${YELLOW}Existing prefix found: ${EXISTING_PREFIX}${NC}"
    echo -e "${GREEN}✓ Keeping existing prefix${NC}"
else
    openssl rand -hex 3 > /opt/salongroei/.temp_user_prefix
    NEW_PREFIX=$(cat /opt/salongroei/.temp_user_prefix)
    echo -e "${GREEN}✓ Prefix generated: ${NEW_PREFIX}${NC}"
fi
chmod 644 /opt/salongroei/.temp_user_prefix
echo ""

echo -e "${YELLOW}[6/7] Installing 'at' command for scheduled user deletion...${NC}"
if ! command -v at &> /dev/null; then
    if [ -f /etc/debian_version ]; then
        apt-get update -qq
        apt-get install -y at
    elif [ -f /etc/redhat-release ]; then
        yum install -y at
    fi
    echo -e "${GREEN}✓ 'at' installed${NC}"
else
    echo -e "${GREEN}✓ 'at' already installed${NC}"
fi
systemctl enable atd 2>/dev/null || true
systemctl start atd 2>/dev/null || true
echo ""

echo -e "${YELLOW}[7/7] Creating temp user log file...${NC}"
touch /tmp/temp_users.log
chmod 644 /tmp/temp_users.log
echo -e "${GREEN}✓ Log file created${NC}"
echo ""

echo "================================================"
echo -e "${GREEN}  Setup Complete!${NC}"
echo "================================================"
echo ""
echo -e "Deployment user created: ${GREEN}${DEPLOY_USER}${NC}"
echo "SSH: ssh ${DEPLOY_USER}@$(hostname -I | awk '{print $1}')"
echo ""
echo -e "${YELLOW}IMPORTANT: Test SSH login before disconnecting root!${NC}"
echo "Open a new terminal and run:"
echo -e "  ${BLUE}ssh ${DEPLOY_USER}@$(hostname -I | awk '{print $1}')${NC}"
echo ""
echo "If successful, update your local deployment config:"
echo "  SERVER_USER=${DEPLOY_USER}"
echo ""
