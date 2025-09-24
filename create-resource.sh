#!/bin/bash

# Create Resource Script - Install Docker.io, Nginx, Certbot with Domain Configuration
# Usage: curl -s https://raw.githubusercontent.com/aslamnk/script/main/create-resource.sh | bash -s example.com 8000

set -e

# Parameters
DOMAIN="${1:-localhost}"
APP_PORT="${2:-8000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to update system packages
update_system() {
    print_status "Updating system packages..."
    apt-get update -y >/dev/null 2>&1
    print_success "System updated"
}

# Function to install docker.io
install_docker() {
    print_status "Installing Docker.io..."
    
    if command -v docker &> /dev/null; then
        print_warning "Docker is already installed"
        return
    fi
    
    apt-get install -y docker.io >/dev/null 2>&1
    systemctl start docker
    systemctl enable docker
    
    # Add user to docker group if not root
    if [[ $SUDO_USER ]]; then
        usermod -aG docker $SUDO_USER
    fi
    
    print_success "Docker.io installed and started"
}

# Function to install nginx
install_nginx() {
    print_status "Installing Nginx..."
    
    if command -v nginx &> /dev/null; then
        print_warning "Nginx is already installed"
        return
    fi
    
    apt-get install -y nginx >/dev/null 2>&1
    systemctl start nginx
    systemctl enable nginx
    
    print_success "Nginx installed and started"
}

# Function to install certbot
install_certbot() {
    print_status "Installing Certbot..."
    
    if command -v certbot &> /dev/null; then
        print_warning "Certbot is already installed"
        return
    fi
    
    apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1
    print_success "Certbot installed"
}

# Function to install postgresql
install_postgresql() {
    print_status "Installing PostgreSQL..."
    
    if command -v psql &> /dev/null; then
        print_warning "PostgreSQL is already installed"
        return
    fi
    
    apt-get install -y postgresql postgresql-contrib >/dev/null 2>&1
    systemctl start postgresql
    systemctl enable postgresql
    
    # Create a database and user for the application
    sudo -u postgres psql -c "CREATE DATABASE app_db;" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE USER app_user WITH PASSWORD 'app_password';" 2>/dev/null || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE app_db TO app_user;" 2>/dev/null || true
    
    print_success "PostgreSQL installed and configured"
    print_status "Database: app_db, User: app_user, Password: app_password"
}

# Function to install redis
install_redis() {
    print_status "Installing Redis..."
    
    if command -v redis-server &> /dev/null; then
        print_warning "Redis is already installed"
        return
    fi
    
    apt-get install -y redis-server >/dev/null 2>&1
    systemctl start redis-server
    systemctl enable redis-server
    
    # Configure Redis for production use
    sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
    sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    systemctl restart redis-server
    
    print_success "Redis installed and configured"
    print_status "Redis running on localhost:6379"
}

# Function to configure nginx
configure_nginx() {
    print_status "Configuring Nginx for domain: $DOMAIN -> Port: $APP_PORT"
    
    # Remove default nginx config
    rm -f /etc/nginx/sites-enabled/default
    
    # Create nginx configuration
    cat > "/etc/nginx/sites-available/$DOMAIN" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Enable the site
    ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/$DOMAIN"
    
    # Test and reload nginx
    nginx -t
    systemctl reload nginx
    
    print_success "Nginx configured: $DOMAIN (port 80) -> localhost:$APP_PORT"
}



# Function to display final status
show_final_status() {
    echo ""
    echo "============================================"
    print_success "Resource Creation Complete!"
    echo "============================================"
    echo ""
    print_status "Configuration Summary:"
    echo "  Domain: $DOMAIN"
    echo "  Nginx: Listening on port 80"
    echo "  Application: Running on port $APP_PORT"
    echo "  Port Forwarding: $DOMAIN:80 → localhost:$APP_PORT"
    echo ""
    print_status "Services Status:"
    systemctl is-active --quiet docker && print_success "  Docker: Running" || print_error "  Docker: Not running"
    systemctl is-active --quiet nginx && print_success "  Nginx: Running" || print_error "  Nginx: Not running"
    systemctl is-active --quiet postgresql && print_success "  PostgreSQL: Running" || print_error "  PostgreSQL: Not running"
    systemctl is-active --quiet redis-server && print_success "  Redis: Running" || print_error "  Redis: Not running"
    echo ""
    print_status "Test your setup:"
    echo "  curl http://$DOMAIN"
    echo ""
    print_status "Database Info:"
    echo "  PostgreSQL Database: app_db"
    echo "  PostgreSQL Username: app_user"
    echo "  PostgreSQL Password: app_password"
    echo "  PostgreSQL Connection: postgresql://app_user:app_password@localhost:5432/app_db"
    echo "  Redis Connection: redis://localhost:6379"
    echo ""
    print_status "Next steps:"
    echo "  1. Point your domain DNS to this server's IP"
    echo "  2. Deploy your application on port $APP_PORT"
    echo "  3. Connect to database using the credentials above"
    echo "  4. Get SSL certificate: sudo certbot --nginx -d $DOMAIN (optional)"
    echo ""
}

# Main execution
main() {
    print_status "Creating resource for domain: $DOMAIN on port: $APP_PORT"
    
    # Check root privileges
    check_root
    
    # Install and configure everything
    update_system
    install_docker
    install_nginx
    install_certbot
    install_postgresql
    install_redis
    configure_nginx
    
    # Show final status
    show_final_status
}

# Run main function with provided arguments
main "$@"
