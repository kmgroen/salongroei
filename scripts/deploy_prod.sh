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
    ssh_exec "mkdir -p ${SERVER_PATH}"
    ssh_exec "chown -R www-data:www-data ${SERVER_PATH}"
    ssh_exec "chmod -R 755 ${SERVER_PATH}"

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

    ssh_exec "cat > ${nginx_config}" << 'NGINX_EOF'
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

    # Enable site
    ssh_exec "ln -sf ${nginx_config} /etc/nginx/sites-enabled/salongroei"

    # Test and reload nginx
    if ssh_exec "nginx -t"; then
        ssh_exec "systemctl reload nginx"
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
    ssh_exec "chown -R www-data:www-data ${SERVER_PATH}"
    ssh_exec "chmod -R 755 ${SERVER_PATH}"

    echo -e "${GREEN}✓ Files deployed successfully${NC}"
    echo -e "${CYAN}  Files on server: $(ssh_exec "find ${SERVER_PATH} -type f | wc -l")${NC}"
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
    echo "║                                                                            ║"
    echo "║  6) Exit                                                                   ║"
    echo "║                                                                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    read -p "Select option [1-6]: " choice
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
    if ssh_exec "[ -f /etc/letsencrypt/live/salongroei.com/fullchain.pem ]"; then
        echo -e "${GREEN}✓ SSL certificate installed${NC}"
    else
        echo -e "${YELLOW}○ SSL certificate not installed${NC}"
    fi

    # Check nginx status
    if ssh_exec "systemctl is-active nginx > /dev/null 2>&1"; then
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

    ssh_exec "certbot --nginx -d salongroei.com -d www.salongroei.com"

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
