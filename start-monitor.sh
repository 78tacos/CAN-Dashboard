#!/bin/bash
# CAN Bus Train Monitor - Quick Launcher
# Runs the monitor from the current directory without installation

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "============================================"
echo "CAN Bus Train Monitor"
echo "============================================"
echo -e "${NC}"

# Find Python
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}Error: Python not found!${NC}"
    echo "Please install Python 3.7 or higher"
    exit 1
fi

echo -e "${GREEN}✓ Using: $($PYTHON_CMD --version)${NC}"
echo ""

# Check for required packages
echo "Checking dependencies..."
if $PYTHON_CMD -c "import can, websockets" 2>/dev/null; then
    echo -e "${GREEN}✓ Required packages installed${NC}"
else
    echo -e "${YELLOW}! Missing packages. Installing...${NC}"
    $PYTHON_CMD -m pip install python-can websockets
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Packages installed${NC}"
    else
        echo -e "${RED}✗ Failed to install packages${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}Starting server...${NC}"
echo ""

# Run server
$PYTHON_CMD server.py
