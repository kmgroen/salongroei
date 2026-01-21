#!/bin/bash
#
# VPS Setup for Temporary User Creation
# Run this script ONCE on your VPS to prepare for temp user functionality
#

set -e

echo "================================================"
echo "  Salongroei VPS - Temp User Setup"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
    echo "Usage: sudo bash setup_vps_temp_users.sh"
    exit 1
fi

echo -e "${YELLOW}[1/5] Creating /opt/salongroei directory...${NC}"
mkdir -p /opt/salongroei
chmod 755 /opt/salongroei
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

echo -e "${YELLOW}[2/5] Generating secret prefix for temp usernames...${NC}"
if [ -f /opt/salongroei/.temp_user_prefix ]; then
    EXISTING_PREFIX=$(cat /opt/salongroei/.temp_user_prefix)
    echo -e "${YELLOW}Existing prefix found: ${EXISTING_PREFIX}${NC}"
    read -p "Keep existing prefix? [Y/n]: " keep_prefix
    if [[ ! "$keep_prefix" =~ ^[Nn]$ ]]; then
        echo -e "${GREEN}✓ Keeping existing prefix${NC}"
    else
        openssl rand -hex 3 > /opt/salongroei/.temp_user_prefix
        NEW_PREFIX=$(cat /opt/salongroei/.temp_user_prefix)
        echo -e "${GREEN}✓ New prefix generated: ${NEW_PREFIX}${NC}"
    fi
else
    openssl rand -hex 3 > /opt/salongroei/.temp_user_prefix
    NEW_PREFIX=$(cat /opt/salongroei/.temp_user_prefix)
    echo -e "${GREEN}✓ Prefix generated: ${NEW_PREFIX}${NC}"
fi
chmod 600 /opt/salongroei/.temp_user_prefix
echo ""

echo -e "${YELLOW}[3/5] Installing 'at' command for scheduled user deletion...${NC}"
if ! command -v at &> /dev/null; then
    # Detect OS and install
    if [ -f /etc/debian_version ]; then
        apt-get update -qq
        apt-get install -y at
    elif [ -f /etc/redhat-release ]; then
        yum install -y at
    else
        echo -e "${RED}ERROR: Unable to detect OS. Please install 'at' manually.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 'at' installed${NC}"
else
    echo -e "${GREEN}✓ 'at' already installed${NC}"
fi

# Ensure atd service is running
systemctl enable atd 2>/dev/null || true
systemctl start atd 2>/dev/null || true
echo -e "${GREEN}✓ atd service enabled and started${NC}"
echo ""

echo -e "${YELLOW}[4/5] Creating temp user log file...${NC}"
touch /tmp/temp_users.log
chmod 644 /tmp/temp_users.log
echo -e "${GREEN}✓ Log file created${NC}"
echo ""

echo -e "${YELLOW}[5/5] Verifying Docker installation (optional)...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓ Docker installed: ${DOCKER_VERSION}${NC}"

    # Check if docker group exists
    if getent group docker > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker group exists${NC}"
    else
        echo -e "${YELLOW}⚠ Docker group not found (temp users won't have docker access)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Docker not installed (temp users won't have docker access)${NC}"
fi
echo ""

echo "================================================"
echo -e "${GREEN}  Setup Complete!${NC}"
echo "================================================"
echo ""
echo "Your VPS is now ready for temporary user creation."
echo ""
echo "Prefix stored in: /opt/salongroei/.temp_user_prefix"
echo "Temp usernames will be: $(cat /opt/salongroei/.temp_user_prefix)_XXXXXXXX"
echo ""
echo "You can now use the deployment script options:"
echo "  - Option 7: Create temporary SSH user"
echo "  - Option 8: Create firefighter SSH user"
echo ""
