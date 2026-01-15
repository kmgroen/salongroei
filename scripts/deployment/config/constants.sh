#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                        SALONGROEI.COM DEPLOYMENT CONFIGURATION                            ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝

# Server configuration
export SERVER_USER="root"
export SERVER="31.97.217.189"
export SERVER_PATH="/var/www/salongroei"
export DOMAIN="salongroei.com"

# SSH configuration
export SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;36m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export WHITE='\033[1;37m'
export NC='\033[0m'
