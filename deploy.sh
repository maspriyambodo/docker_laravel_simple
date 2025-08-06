#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment for Ternasys Backend...${NC}"

# Get current user ID and group ID
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

echo -e "${GREEN}Building with USER_ID=$USER_ID and GROUP_ID=$GROUP_ID${NC}"

# Check if src directory exists
if [ ! -d "src" ]; then
    echo -e "${RED}Error: src directory not found!${NC}"
    exit 1
fi

# Stop existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
docker compose down

# Build images
echo -e "${YELLOW}Building Docker images...${NC}"
docker compose build --no-cache

# Set proper permissions before starting
echo -e "${YELLOW}Setting initial permissions...${NC}"
sudo chown -R $USER_ID:$GROUP_ID src/storage src/bootstrap/cache
chmod -R 775 src/storage src/bootstrap/cache

# Install/update dependencies
echo -e "${YELLOW}Installing Composer dependencies...${NC}"
docker compose run --rm app composer install --optimize-autoloader --no-dev

# Generate key if .env doesn't exist in src
if [ ! -f "src/.env" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    docker compose run --rm app cp .env.example .env
    docker compose run --rm app php artisan key:generate
fi

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
docker compose run --rm app php artisan migrate --force

# Clear and optimize caches
echo -e "${YELLOW}Optimizing application...${NC}"
docker compose run --rm app php artisan config:cache
docker compose run --rm app php artisan route:cache
docker compose run --rm app php artisan event:cache

# Clear old cache
docker compose run --rm app php artisan cache:clear

# Set final permissions
echo -e "${YELLOW}Setting final permissions...${NC}"
docker compose run --rm app chown -R www:www /var/www/storage /var/www/bootstrap/cache

# Start services
echo -e "${YELLOW}Starting services...${NC}"
docker compose up -d

# Show running containers
echo -e "${GREEN}Deployment completed! Running containers:${NC}"
docker compose ps

# Show logs
echo -e "${YELLOW}Recent logs:${NC}"
docker compose logs --tail=20
