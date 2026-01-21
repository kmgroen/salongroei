#!/bin/bash
#
# Temporary SSH User Creation
# Creates a read-only SSH user with 1-hour expiration for debugging
# Uses secret prefix from /opt/salongroei/.temp_user_prefix for security
#

# Get the secret prefix from VPS
get_user_prefix() {
    local prefix=$(ssh_exec "cat /opt/salongroei/.temp_user_prefix 2>/dev/null")
    if [ -z "$prefix" ]; then
        echo -e "${RED}ERROR: Secret prefix not found on server${NC}"
        echo "Run on VPS as root: openssl rand -hex 3 > /opt/salongroei/.temp_user_prefix && chmod 600 /opt/salongroei/.temp_user_prefix"
        return 1
    fi
    echo "$prefix"
}

# Function to create temporary read-only SSH user
create_temp_ssh_user() {
    print_banner "Create Temporary SSH User"

    # Get secret prefix from server
    local prefix=$(get_user_prefix)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Generate random username with secret prefix
    local temp_username="${prefix}_$(openssl rand -hex 4)"

    echo -e "${YELLOW}Creating temporary read-only SSH user on server (using SSH key auth)...${NC}"

    # Create user with 1 hour expiration and SSH key access
    local create_user_script=$(cat <<'EOF'
#!/bin/bash
USERNAME="$1"
SERVER_PATH="$2"
DEPLOY_USER="$3"
SUDO_CMD="$4"
EXPIRY_TIME=$(date -d '+1 hour' '+%Y-%m-%d %H:%M:%S')

# Create user
$SUDO_CMD useradd -m -s /bin/bash "$USERNAME"

# Copy SSH authorized_keys from deploy user (enables same key access)
$SUDO_CMD mkdir -p /home/$USERNAME/.ssh
$SUDO_CMD cp /home/$DEPLOY_USER/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys 2>/dev/null || {
    echo "ERROR: Could not copy SSH keys from $DEPLOY_USER"
    exit 1
}
$SUDO_CMD chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
$SUDO_CMD chmod 700 /home/$USERNAME/.ssh
$SUDO_CMD chmod 600 /home/$USERNAME/.ssh/authorized_keys

# Set account expiration (1 hour from now)
echo "$SUDO_CMD userdel -r $USERNAME; $SUDO_CMD rm -f /etc/sudoers.d/temp_${USERNAME}" | $SUDO_CMD at now + 1 hour 2>/dev/null || {
    echo "# User $USERNAME should be manually removed after: $EXPIRY_TIME" | $SUDO_CMD tee -a /tmp/temp_users.log
}

# Add to docker group for docker access
$SUDO_CMD usermod -aG docker "$USERNAME" 2>/dev/null || true

# Add debugging and Docker maintenance access
$SUDO_CMD mkdir -p /etc/sudoers.d
$SUDO_CMD tee "/etc/sudoers.d/temp_${USERNAME}" > /dev/null <<SUDOERS
# Temporary user - debugging + Docker access
# NO destructive commands (rm, mv, chmod) outside project dir
$USERNAME ALL=(ALL) NOPASSWD: /bin/ls *
$USERNAME ALL=(ALL) NOPASSWD: /bin/cat *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/find *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/du *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/journalctl *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/tail *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/head *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/less *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/systemctl status *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active *
$USERNAME ALL=(ALL) NOPASSWD: /usr/sbin/nginx -t
# Docker commands (full access for debugging)
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/docker *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/docker compose *
$USERNAME ALL=(ALL) NOPASSWD: /usr/local/bin/docker-compose *
# Git operations (read-only)
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/git -C $SERVER_PATH status
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/git -C $SERVER_PATH log *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/git -C $SERVER_PATH diff *
# Restricted to project directory only
$USERNAME ALL=(ALL) NOPASSWD: /bin/mkdir $SERVER_PATH/*
SUDOERS

# Grant read access to website directory
$SUDO_CMD chmod -R o+rx $SERVER_PATH 2>/dev/null || true

$SUDO_CMD chmod 440 "/etc/sudoers.d/temp_${USERNAME}"

echo "✓ User created: $USERNAME"
echo "✓ Expires: $EXPIRY_TIME"
echo "✓ Auth method: SSH key (copied from $DEPLOY_USER)"
EOF
)

    # Execute on server - pass deploy user and sudo command
    if ssh_exec "bash -s $temp_username ${SERVER_PATH} ${SERVER_USER} \"${REMOTE_SUDO}\"" <<< "$create_user_script"; then
        echo -e "${GREEN}✓ Temporary SSH user created (expires in 1 hour)${NC}"
        echo ""
        echo "SSH: ssh ${temp_username}@${SERVER}"
        echo ""

        # Save credentials to a temporary file for easy reference
        local creds_file="scripts/temp-user.txt"
        mkdir -p scripts
        cat > "$creds_file" <<CREDS
VPS Temporary Access (expires in 1 hour)

SSH: ssh ${temp_username}@${SERVER}

Paths:
  WEBSITE=${SERVER_PATH}
  NGINX_CONFIG=/etc/nginx/sites-available/salongroei
  NGINX_LOGS=/var/log/nginx/

Auth: Uses same SSH key as ${SERVER_USER} (no password needed)

Useful Commands:
  # Nginx
  sudo systemctl status nginx
  sudo nginx -t
  sudo tail -f /var/log/nginx/access.log
  sudo cat /var/log/nginx/error.log

  # Docker (if containers exist)
  sudo docker ps
  sudo docker stats
  sudo docker logs <container_name>
  sudo docker exec -it <container_name> bash

  # Files
  sudo ls -la ${SERVER_PATH}
  sudo cat ${SERVER_PATH}/index.html
CREDS
        echo -e "${GREEN}✓ Credentials saved to: ${creds_file}${NC}"
    else
        echo -e "${RED}Failed to create temporary user${NC}"
        exit 1
    fi
}

# Function to list temporary users
list_temp_users() {
    print_banner "List Temporary Users"

    # Get prefix for display
    local prefix=$(get_user_prefix 2>/dev/null || echo "unknown")

    ssh_exec "
        PREFIX=\$(cat /opt/salongroei/.temp_user_prefix 2>/dev/null || echo 'unknown')
        echo \"Temporary users (prefix: \$PREFIX)\"
        echo '─────────────────────────────────────────────────────────────────'
        ${REMOTE_SUDO} getent passwd | grep -E \"^\${PREFIX}_\" | while read line; do
            username=\$(echo \$line | cut -d: -f1)
            echo \"  \$username\"
        done
        echo '─────────────────────────────────────────────────────────────────'

        if [ -f /tmp/temp_users.log ]; then
            echo ''
            echo 'Pending deletions:'
            cat /tmp/temp_users.log
        fi
    "
}

# Function to manually delete a temporary user
delete_temp_user() {
    print_banner "Delete Temporary User"

    # List current temp users
    list_temp_users

    echo ""
    read -p "Enter username to delete (or 'q' to cancel): " username

    if [ "$username" = "q" ]; then
        echo -e "${YELLOW}Deletion cancelled${NC}"
        return 0
    fi

    echo ""
    read -p "Delete user '$username'? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deletion cancelled${NC}"
        return 0
    fi

    ssh_exec "
        ${REMOTE_SUDO} userdel -r $username 2>/dev/null || echo 'User not found'
        ${REMOTE_SUDO} rm -f /etc/sudoers.d/temp_${username}
        echo '✓ User deleted: $username'
    "
    echo -e "${GREEN}✓ User deleted${NC}"
}

# Function to create firefighter access (full sudo for emergencies)
create_firefighter_user() {
    print_banner "Create Firefighter SSH User (Full Access)"

    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  WARNING: FIREFIGHTER ACCESS - FULL SUDO PRIVILEGES             ║${NC}"
    echo -e "${RED}║  Use only for emergencies! Expires in 1 hour.                   ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    read -p "Create firefighter user with FULL sudo access? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        return 0
    fi

    # Get secret prefix from server
    local prefix=$(get_user_prefix)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Generate random username with secret prefix (ff = firefighter)
    local temp_username="${prefix}_ff_$(openssl rand -hex 4)"

    echo -e "${YELLOW}Creating firefighter user on server (using SSH key auth)...${NC}"

    # Create user with full sudo access and copy SSH keys
    local create_user_script=$(cat <<'EOF'
#!/bin/bash
USERNAME="$1"
SERVER_PATH="$2"
DEPLOY_USER="$3"
SUDO_CMD="$4"
EXPIRY_TIME=$(date -d '+1 hour' '+%Y-%m-%d %H:%M:%S')

# Create user
$SUDO_CMD useradd -m -s /bin/bash "$USERNAME"

# Copy SSH authorized_keys from deploy user (enables same key access)
$SUDO_CMD mkdir -p /home/$USERNAME/.ssh
$SUDO_CMD cp /home/$DEPLOY_USER/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys 2>/dev/null || {
    echo "ERROR: Could not copy SSH keys from $DEPLOY_USER"
    exit 1
}
$SUDO_CMD chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
$SUDO_CMD chmod 700 /home/$USERNAME/.ssh
$SUDO_CMD chmod 600 /home/$USERNAME/.ssh/authorized_keys

# Schedule deletion
echo "$SUDO_CMD userdel -r $USERNAME; $SUDO_CMD rm -f /etc/sudoers.d/temp_${USERNAME}" | $SUDO_CMD at now + 1 hour 2>/dev/null || {
    echo "# FIREFIGHTER User $USERNAME - DELETE AFTER: $EXPIRY_TIME" | $SUDO_CMD tee -a /tmp/temp_users.log
}

# FIREFIGHTER: Full sudo access (ALL commands)
$SUDO_CMD mkdir -p /etc/sudoers.d
$SUDO_CMD tee "/etc/sudoers.d/temp_${USERNAME}" > /dev/null <<SUDOERS
# FIREFIGHTER ACCESS - Full sudo privileges
# User: $USERNAME
# Expires: $EXPIRY_TIME
# WARNING: This user has FULL root access!
$USERNAME ALL=(ALL) NOPASSWD: ALL
SUDOERS

$SUDO_CMD chmod 440 "/etc/sudoers.d/temp_${USERNAME}"

echo "✓ Firefighter user created: $USERNAME"
echo "✓ Expires: $EXPIRY_TIME"
echo "✓ Access level: FULL SUDO (ALL commands)"
echo "✓ Auth method: SSH key (copied from $DEPLOY_USER)"
EOF
)

    # Execute on server - pass deploy user and sudo command
    if ssh_exec "bash -s $temp_username ${SERVER_PATH} ${SERVER_USER} \"${REMOTE_SUDO}\"" <<< "$create_user_script"; then
        echo -e "${GREEN}✓ Firefighter user created (expires in 1 hour)${NC}"
        echo ""
        echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  FIREFIGHTER ACCESS CREDENTIALS                                  ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "SSH: ssh ${temp_username}@${SERVER}"
        echo ""
        echo -e "${YELLOW}Uses same SSH key as ${SERVER_USER}. FULL sudo access!${NC}"
        echo ""

        # Save credentials
        local creds_file="scripts/temp-user.txt"
        mkdir -p scripts
        cat > "$creds_file" <<CREDS
VPS FIREFIGHTER Access (expires in 1 hour)
WARNING: FULL SUDO ACCESS - USE RESPONSIBLY!

SSH: ssh ${temp_username}@${SERVER}

Paths:
  WEBSITE=${SERVER_PATH}
  NGINX_CONFIG=/etc/nginx/sites-available/salongroei
  NGINX_LOGS=/var/log/nginx/

Auth: Uses same SSH key as ${SERVER_USER} (no password needed)
This user can run ANY command with sudo (NOPASSWD)!

Useful Commands:
  sudo systemctl restart nginx
  sudo docker ps -a
  sudo docker exec -it <container_name> bash
  sudo journalctl -u nginx -f
  sudo certbot renew
CREDS
        echo -e "${GREEN}✓ Credentials saved to: ${creds_file}${NC}"
    else
        echo -e "${RED}Failed to create firefighter user${NC}"
        exit 1
    fi
}
