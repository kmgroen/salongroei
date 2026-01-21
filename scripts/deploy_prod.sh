#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                         SALONGROEI.COM - PRODUCTION DEPLOYMENT                            ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝

# Navigate to project root
cd "$(dirname "$0")/.." || { echo "Failed to change to project root directory"; exit 1; }
PROJECT_ROOT=$(pwd)

# ═══════════════════════════════════════════════════════════════════════════════════════════
#                              SOURCE MODULAR COMPONENTS
# ═══════════════════════════════════════════════════════════════════════════════════════════

DEPLOYMENT_DIR="${PROJECT_ROOT}/scripts/deployment"

source "${DEPLOYMENT_DIR}/config/constants.sh"
source "${DEPLOYMENT_DIR}/functions/utils.sh"
source "${DEPLOYMENT_DIR}/functions/ssh_auth.sh"
source "${DEPLOYMENT_DIR}/functions/temp_ssh_user.sh"

# ═══════════════════════════════════════════════════════════════════════════════════════════
#                                    DEPLOYMENT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════════════

build_site() {
    print_banner "Building Astro Site"

    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm ci

    echo -e "${YELLOW}Building for production...${NC}"
    npm run build

    if [ ! -d "dist" ]; then
        echo -e "${RED}Error: Build failed - dist folder not found${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Build completed successfully${NC}"
    echo -e "${CYAN}  Files: $(find dist -type f | wc -l | xargs)${NC}"
}

setup_vps() {
    print_banner "Setting up VPS"

    echo -e "${YELLOW}Creating directory structure...${NC}"
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }mkdir -p ${SERVER_PATH}"
    # Set ownership to deployment user so rsync can write, deploy_files will change to www-data after
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }chown -R ${SERVER_USER}:www-data ${SERVER_PATH}"
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }chmod -R 775 ${SERVER_PATH}"

    echo -e "${GREEN}✓ VPS directory ready${NC}"
}

setup_nginx() {
    print_banner "Setting up Nginx"

    local nginx_config="/etc/nginx/sites-available/salongroei"

    # Check if nginx config exists
    if ssh_exec "[ -f ${nginx_config} ]"; then
        echo -e "${GREEN}✓ Nginx config already exists${NC}"
        return 0
    fi

    echo -e "${YELLOW}Creating Nginx configuration...${NC}"

    # Create config locally first
    local temp_config="/tmp/salongroei-nginx-$$.conf"
    cat > "${temp_config}" << 'NGINX_EOF'
server {
    listen 80;
    server_name salongroei.com www.salongroei.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name salongroei.com www.salongroei.com;

    # SSL will be configured by certbot
    # ssl_certificate /etc/letsencrypt/live/salongroei.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/salongroei.com/privkey.pem;

    root /var/www/salongroei;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        try_files $uri $uri/ /index.html =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
NGINX_EOF

    # Upload and move to nginx config location
    if [ "$SSH_AUTH_METHOD" = "key" ]; then
        scp $(scp_base_args) "${temp_config}" ${SERVER_USER}@${SERVER}:/tmp/salongroei.conf
    else
        sshpass -p "$VPS_PASSWORD" scp $(scp_base_args) "${temp_config}" ${SERVER_USER}@${SERVER}:/tmp/salongroei.conf
    fi

    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }mv /tmp/salongroei.conf ${nginx_config}"
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }chmod 644 ${nginx_config}"

    # Clean up local temp file
    rm -f "${temp_config}"

    # Enable site
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }ln -sf ${nginx_config} /etc/nginx/sites-enabled/salongroei"

    # Test and reload nginx
    if ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }nginx -t"; then
        ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }systemctl reload nginx"
        echo -e "${GREEN}✓ Nginx configured and reloaded${NC}"
    else
        echo -e "${RED}Error: Nginx configuration test failed${NC}"
        exit 1
    fi
}

deploy_files() {
    print_banner "Deploying Files"

    echo -e "${YELLOW}Syncing files to VPS...${NC}"
    rsync_exec "dist/" "${SERVER_PATH}/"

    # Fix permissions
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }chown -R www-data:www-data ${SERVER_PATH}"
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }chmod -R 755 ${SERVER_PATH}"

    echo -e "${GREEN}✓ Files deployed successfully${NC}"
    echo -e "${CYAN}  Files on server: $(ssh_exec "find ${SERVER_PATH} -type f | wc -l")${NC}"
}

configure_nginx_live() {
    print_banner "Configure Nginx (Live)"

    echo -e "${YELLOW}Creating nginx configuration...${NC}"

    # Create config locally
    local temp_config="/tmp/salongroei-nginx-$$.conf"
    cat > "${temp_config}" << 'NGINX_LIVE_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name salongroei.com www.salongroei.com;

    root /var/www/salongroei;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location / {
        try_files $uri $uri/ $uri.html /index.html =404;
    }

    # Logging
    access_log /var/log/nginx/salongroei-access.log;
    error_log /var/log/nginx/salongroei-error.log;
}
NGINX_LIVE_EOF

    # Upload config
    if [ "$SSH_AUTH_METHOD" = "key" ]; then
        scp $(scp_base_args) "${temp_config}" ${SERVER_USER}@${SERVER}:/tmp/salongroei.conf
    else
        sshpass -p "$VPS_PASSWORD" scp $(scp_base_args) "${temp_config}" ${SERVER_USER}@${SERVER}:/tmp/salongroei.conf
    fi

    # Move to nginx sites-available
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }mv /tmp/salongroei.conf /etc/nginx/sites-available/salongroei"
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }chmod 644 /etc/nginx/sites-available/salongroei"

    # Enable site
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }ln -sf /etc/nginx/sites-available/salongroei /etc/nginx/sites-enabled/salongroei"

    # Remove default site if exists
    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }rm -f /etc/nginx/sites-enabled/default"

    # Clean up local temp file
    rm -f "${temp_config}"

    # Test and reload nginx
    echo -e "${YELLOW}Testing nginx configuration...${NC}"
    if ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }nginx -t"; then
        ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }systemctl reload nginx"
        echo -e "${GREEN}✓ Nginx configured and reloaded${NC}"
        echo -e "${CYAN}Site should be live at http://${SERVER}${NC}"
    else
        echo -e "${RED}Error: Nginx configuration test failed${NC}"
        exit 1
    fi
}

show_menu() {
    echo -e "${WHITE}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    SALONGROEI.COM DEPLOYMENT MENU                          ║"
    echo "╠════════════════════════════════════════════════════════════════════════════╣"
    echo "║                                                                            ║"
    echo "║  1) Build & Deploy          - Build site and deploy to VPS                ║"
    echo "║  2) Deploy Only             - Deploy existing build (skip npm build)      ║"
    echo "║  3) Setup VPS               - Create directories & nginx config           ║"
    echo "║  4) Setup SSL               - Run certbot for SSL certificate             ║"
    echo "║  5) Check Status            - Show deployment status                       ║"
    echo "║  6) Configure Nginx (Live)  - Upload and enable nginx config              ║"
    echo "║                                                                            ║"
    echo -e "║  ${CYAN}SSH Access:${WHITE}                                                             ║"
    echo -e "║  7) Create Temp User        - Create temporary SSH user (1-hour)          ║"
    echo -e "║  8) Create Firefighter      - Create emergency user ${RED}(FULL sudo)${WHITE}         ║"
    echo "║                                                                            ║"
    echo "║  9) Exit                                                                   ║"
    echo "║                                                                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    read -p "Select option [1-9]: " choice
}

check_status() {
    print_banner "Deployment Status"

    echo -e "${YELLOW}Checking VPS status...${NC}"

    # Check if directory exists
    if ssh_exec "[ -d ${SERVER_PATH} ]"; then
        echo -e "${GREEN}✓ Deploy directory exists${NC}"
        local file_count=$(ssh_exec "find ${SERVER_PATH} -type f | wc -l")
        echo -e "${CYAN}  Files on server: ${file_count}${NC}"
    else
        echo -e "${RED}✗ Deploy directory not found${NC}"
    fi

    # Check nginx
    if ssh_exec "[ -f /etc/nginx/sites-enabled/salongroei ]"; then
        echo -e "${GREEN}✓ Nginx config enabled${NC}"
    else
        echo -e "${YELLOW}○ Nginx config not found${NC}"
    fi

    # Check SSL
    if ssh_exec "[ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]"; then
        echo -e "${GREEN}✓ SSL certificate installed${NC}"
    else
        echo -e "${YELLOW}○ SSL certificate not installed${NC}"
    fi

    # Check nginx status
    if ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }systemctl is-active nginx > /dev/null 2>&1"; then
        echo -e "${GREEN}✓ Nginx is running${NC}"
    else
        echo -e "${RED}✗ Nginx is not running${NC}"
    fi
}

setup_ssl() {
    print_banner "Setting up SSL Certificate"

    echo -e "${YELLOW}Running certbot...${NC}"
    echo -e "${CYAN}Make sure DNS is pointing to ${SERVER} before continuing!${NC}"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."

    ssh_exec "${REMOTE_SUDO:+$REMOTE_SUDO }certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"

    echo -e "${GREEN}✓ SSL setup complete${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════════════════
#                                      MAIN FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════════════════

main() {
    print_banner "salongroei.com Deployment"

    echo -e "${BLUE}Server: ${SERVER}${NC}"
    echo -e "${BLUE}Path: ${SERVER_PATH}${NC}"
    echo ""

    # Setup SSH authentication
    setup_ssh_auth

    # Show menu
    show_menu

    case $choice in
        1)
            build_site
            setup_vps
            deploy_files
            ;;
        2)
            if [ ! -d "dist" ]; then
                echo -e "${RED}Error: No dist folder found. Run option 1 first.${NC}"
                exit 1
            fi
            setup_vps
            deploy_files
            ;;
        3)
            setup_vps
            setup_nginx
            ;;
        4)
            setup_ssl
            ;;
        5)
            check_status
            exit 0
            ;;
        6)
            configure_nginx_live
            ;;
        7)
            create_temp_ssh_user
            exit 0
            ;;
        8)
            create_firefighter_user
            exit 0
            ;;
        9)
            echo -e "${YELLOW}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac

    print_banner "Deployment Complete"
    echo -e "${GREEN}✓ salongroei.com has been deployed!${NC}"
    echo ""
    echo "Site should be available at:"
    echo "  - https://salongroei.com (once DNS is configured)"
    echo "  - http://${SERVER} (direct IP access)"
    echo ""

    send_notification "Deployment Complete ✓" "salongroei.com deployed successfully!" "Glass"
}

# Run main function
main
