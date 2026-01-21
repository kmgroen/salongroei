#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                              SSH AUTHENTICATION FUNCTIONS                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝

SSH_AGENT_TIMEOUT=86400  # 24 hours
SSH_AGENT_ENV="/tmp/.ssh-agent-env-${USER}"

ssh_base_args() {
    local args=( $SSH_OPTIONS -p "${SSH_PORT}" )

    if [ -n "${SSH_IDENTITY_FILE}" ]; then
        args+=( -i "${SSH_IDENTITY_FILE}" )
    fi

    printf '%s ' "${args[@]}"
}

scp_base_args() {
    # SCP uses -P (uppercase) for port, not -p
    local args=( $SSH_OPTIONS -P "${SSH_PORT}" )

    if [ -n "${SSH_IDENTITY_FILE}" ]; then
        args+=( -i "${SSH_IDENTITY_FILE}" )
    fi

    printf '%s ' "${args[@]}"
}

ensure_ssh_agent() {
    if [ -f "$SSH_AGENT_ENV" ]; then
        . "$SSH_AGENT_ENV" > /dev/null
        if ! kill -0 $SSH_AGENT_PID 2>/dev/null; then
            rm -f "$SSH_AGENT_ENV"
            start_new_ssh_agent
        else
            echo -e "${GREEN}✓ Reusing existing SSH agent (PID: $SSH_AGENT_PID)${NC}"
        fi
    else
        start_new_ssh_agent
    fi
}

start_new_ssh_agent() {
    echo -e "${YELLOW}Starting new SSH agent with 24-hour key retention...${NC}"
    ssh-agent -t $SSH_AGENT_TIMEOUT > "$SSH_AGENT_ENV"
    chmod 600 "$SSH_AGENT_ENV"
    . "$SSH_AGENT_ENV" > /dev/null
    echo -e "${GREEN}✓ SSH agent started (PID: $SSH_AGENT_PID)${NC}"
}

setup_ssh_auth() {
    print_banner "Setting up SSH Authentication"

    # Check existing agent with keys
    if [ -f "$SSH_AGENT_ENV" ]; then
        . "$SSH_AGENT_ENV" > /dev/null 2>&1
        if kill -0 $SSH_AGENT_PID 2>/dev/null && ssh-add -l 2>/dev/null | grep -q -E "(id_|ssh)"; then
            if ssh $(ssh_base_args) -o BatchMode=yes -o ConnectTimeout=5 ${SERVER_USER}@${SERVER} exit 2>/dev/null; then
                echo -e "${GREEN}✓ SSH key authentication successful (using cached key)${NC}"
                export SSH_AUTH_METHOD="key"
                return 0
            fi
        fi
    fi

    # Test key auth without agent
    if ssh $(ssh_base_args) -o BatchMode=yes -o ConnectTimeout=5 ${SERVER_USER}@${SERVER} exit 2>/dev/null; then
        echo -e "${GREEN}✓ SSH key authentication successful${NC}"
        export SSH_AUTH_METHOD="key"
        return 0
    fi

    # Start/reuse agent
    ensure_ssh_agent

    # Check if key already loaded
    if ssh-add -l 2>/dev/null | grep -q -E "(id_|ssh)"; then
        if ssh $(ssh_base_args) -o BatchMode=yes -o ConnectTimeout=5 ${SERVER_USER}@${SERVER} exit 2>/dev/null; then
            export SSH_AUTH_METHOD="key"
            return 0
        fi
    fi

    # Add key with passphrase prompt
    echo -e "${YELLOW}SSH key requires passphrase (will be cached for 24 hours)${NC}"

    if [ -n "${SSH_IDENTITY_FILE}" ] && [ -f "${SSH_IDENTITY_FILE}" ]; then
        echo -e "${YELLOW}Using configured key: ${SSH_IDENTITY_FILE}${NC}"
        ssh-add -t $SSH_AGENT_TIMEOUT "${SSH_IDENTITY_FILE}" || true
    else
        ssh-add -t $SSH_AGENT_TIMEOUT 2>/dev/null || true
    fi

    if ssh-add -l 2>/dev/null | grep -q -E "(id_|ssh)"; then
        echo -e "${GREEN}✓ SSH key added to agent${NC}"
    fi

    # Test again
    if ssh $(ssh_base_args) -o BatchMode=yes -o ConnectTimeout=5 ${SERVER_USER}@${SERVER} exit 2>/dev/null; then
        echo -e "${GREEN}✓ SSH key authentication successful${NC}"
        export SSH_AUTH_METHOD="key"
        return 0
    fi

    # Fallback to password
    if ! command -v sshpass &> /dev/null; then
        echo -e "${RED}Error: SSH key authentication failed and sshpass is not installed.${NC}"
        echo -e "${YELLOW}Fix: set up SSH key auth (recommended) or install sshpass manually.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Enter VPS password:${NC}"
    read -sp "Password for ${SERVER_USER}@${SERVER}: " VPS_PASSWORD
    echo

    if sshpass -p "$VPS_PASSWORD" ssh $(ssh_base_args) ${SERVER_USER}@${SERVER} exit 2>/dev/null; then
        echo -e "${GREEN}✓ Password authentication successful${NC}"
        export SSH_AUTH_METHOD="password"
        export VPS_PASSWORD
        return 0
    else
        echo -e "${RED}Error: Authentication failed${NC}"
        exit 1
    fi
}

ssh_exec() {
    if [ "$SSH_AUTH_METHOD" = "key" ]; then
        ssh $(ssh_base_args) ${SERVER_USER}@${SERVER} "$@"
    else
        sshpass -p "$VPS_PASSWORD" ssh $(ssh_base_args) ${SERVER_USER}@${SERVER} "$@"
    fi
}

rsync_exec() {
    local source="$1"
    local destination="$2"

    if [ "$SSH_AUTH_METHOD" = "key" ]; then
        rsync -avz --delete -e "ssh $(ssh_base_args)" "$source" ${SERVER_USER}@${SERVER}:"$destination"
    else
        sshpass -p "$VPS_PASSWORD" rsync -avz --delete -e "ssh $(ssh_base_args)" "$source" ${SERVER_USER}@${SERVER}:"$destination"
    fi
}
