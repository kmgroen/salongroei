#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                 UTILITY FUNCTIONS                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝

# Function to print stage banner
print_banner() {
    local text="$1"
    local width=78
    local padding=$(( (width - 2 - ${#text}) / 2 ))
    local extra=$(( (width - 2 - ${#text}) % 2 ))
    local timestamp=$(date '+%H:%M:%S')

    echo -e "${BLUE}"
    echo "┌$(printf '─%.0s' $(seq 1 $width))┐"
    echo "│$(printf ' %.0s' $(seq 1 $padding))$text$(printf ' %.0s' $(seq 1 $((padding + extra))))│"
    echo "└$(printf '─%.0s' $(seq 1 $width))┘"
    echo -e "${NC}"
    echo -e "${CYAN}[${timestamp}]${NC}"
}

# Function to send macOS notification
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-Blow}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
    fi
}
