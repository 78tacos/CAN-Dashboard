#!/bin/bash
# Docker Build and Run Script for CAN Bus Train Monitor

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

IMAGE_NAME="can-train-monitor"
CONTAINER_NAME="can-train-monitor"

echo -e "${CYAN}"
echo "============================================"
echo "CAN Bus Train Monitor - Docker Setup"
echo "============================================"
echo -e "${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is not installed!${NC}"
    echo "Please install Docker:"
    echo "  - Linux: sudo apt install docker.io"
    echo "  - Mac: Download Docker Desktop"
    echo "  - Windows: Download Docker Desktop"
    exit 1
fi

echo -e "${GREEN}✓ Docker found: $(docker --version)${NC}"
echo ""

echo "Choose an option:"
echo "  1) Build image"
echo "  2) Run container"
echo "  3) Build and run"
echo "  4) Stop container"
echo "  5) View logs"
echo "  6) Remove container"
echo "  7) Docker Compose (up)"
echo "  8) Docker Compose (down)"
echo "  9) Clean up everything"
echo ""
read -p "Enter choice [1-9]: " choice

case $choice in
    1)
        echo -e "${YELLOW}Building Docker image...${NC}"
        docker build -t $IMAGE_NAME .
        echo -e "${GREEN}✓ Image built successfully${NC}"
        ;;
    2)
        echo -e "${YELLOW}Running container...${NC}"
        docker run -d \
            --name $CONTAINER_NAME \
            -p 3000:3000 \
            -p 8080:8080 \
            $IMAGE_NAME
        echo -e "${GREEN}✓ Container started${NC}"
        echo ""
        echo "Access at: http://localhost:3000/train-monitor-standalone.html"
        ;;
    3)
        echo -e "${YELLOW}Building Docker image...${NC}"
        docker build -t $IMAGE_NAME .
        echo -e "${GREEN}✓ Image built${NC}"
        echo ""
        echo -e "${YELLOW}Running container...${NC}"
        docker run -d \
            --name $CONTAINER_NAME \
            -p 3000:3000 \
            -p 8080:8080 \
            $IMAGE_NAME
        echo -e "${GREEN}✓ Container started${NC}"
        echo ""
        echo "Access at: http://localhost:3000/train-monitor-standalone.html"
        ;;
    4)
        echo -e "${YELLOW}Stopping container...${NC}"
        docker stop $CONTAINER_NAME
        echo -e "${GREEN}✓ Container stopped${NC}"
        ;;
    5)
        echo -e "${CYAN}Container logs (Ctrl+C to exit):${NC}"
        docker logs -f $CONTAINER_NAME
        ;;
    6)
        echo -e "${YELLOW}Removing container...${NC}"
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME
        echo -e "${GREEN}✓ Container removed${NC}"
        ;;
    7)
        if command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Starting with Docker Compose...${NC}"
            docker-compose up -d
            echo -e "${GREEN}✓ Services started${NC}"
            echo ""
            echo "Access at: http://localhost:3000/train-monitor-standalone.html"
        else
            echo -e "${YELLOW}docker-compose not found, using docker compose...${NC}"
            docker compose up -d
            echo -e "${GREEN}✓ Services started${NC}"
            echo ""
            echo "Access at: http://localhost:3000/train-monitor-standalone.html"
        fi
        ;;
    8)
        if command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Stopping Docker Compose services...${NC}"
            docker-compose down
            echo -e "${GREEN}✓ Services stopped${NC}"
        else
            echo -e "${YELLOW}Stopping Docker Compose services...${NC}"
            docker compose down
            echo -e "${GREEN}✓ Services stopped${NC}"
        fi
        ;;
    9)
        echo -e "${YELLOW}Cleaning up everything...${NC}"
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        docker rmi $IMAGE_NAME 2>/dev/null || true
        echo -e "${GREEN}✓ Cleanup complete${NC}"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
