#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                        SALONGROEI.COM DEPLOYMENT CONFIGURATION                            ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝

# Server configuration
 : "${SERVER_USER:=kasper}"
 : "${SERVER:=31.97.217.189}"
 : "${SERVER_PATH:=/var/www/salongroei}"
 : "${DOMAIN:=salongroei.com}"
 : "${SSH_PORT:=22}"
 # Use default SSH key (~/.ssh/id_ed25519) - don't override
 : "${SSH_IDENTITY_FILE:=}"
 # Use sudo for non-root users
 if [ "${SERVER_USER}" != "root" ]; then
     : "${REMOTE_SUDO:=sudo}"
 else
     : "${REMOTE_SUDO:=}"
 fi

export SERVER_USER
export SERVER
export SERVER_PATH
export DOMAIN
export SSH_PORT
export SSH_IDENTITY_FILE
export REMOTE_SUDO

# SSH configuration
 : "${SSH_STRICT_HOST_KEY_CHECKING:=accept-new}"
 : "${SSH_KNOWN_HOSTS_FILE:=${HOME}/.ssh/known_hosts}"

export SSH_OPTIONS="-o StrictHostKeyChecking=${SSH_STRICT_HOST_KEY_CHECKING} -o UserKnownHostsFile=${SSH_KNOWN_HOSTS_FILE} -o IdentitiesOnly=yes -o LogLevel=ERROR"

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;36m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export WHITE='\033[1;37m'
export NC='\033[0m'
