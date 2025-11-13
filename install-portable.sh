#!/bin/bash
# CAN Bus Train Monitor - Portable Installer for Linux/Mac
# This script sets up the complete train monitoring system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default installation path
INSTALL_PATH="${HOME}/CANTrainMonitor"
SKIP_PYTHON=false
SKIP_DEPENDENCIES=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-path)
            INSTALL_PATH="$2"
            shift 2
            ;;
        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;
        --skip-dependencies)
            SKIP_DEPENDENCIES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --install-path PATH     Custom installation path (default: ~/CANTrainMonitor)"
            echo "  --skip-python           Skip Python version check"
            echo "  --skip-dependencies     Skip Python package installation"
            echo "  --help                  Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}"
echo "============================================="
echo "CAN Bus Train Monitor - Portable Installer"
echo "============================================="
echo -e "${NC}"

# Check if Python is installed
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        PYTHON_VERSION=$(python3 --version 2>&1)
        echo -e "${GREEN}✓ Python found: $PYTHON_VERSION${NC}"
        return 0
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
        PYTHON_VERSION=$(python --version 2>&1)
        echo -e "${GREEN}✓ Python found: $PYTHON_VERSION${NC}"
        return 0
    else
        echo -e "${RED}✗ Python not found${NC}"
        return 1
    fi
}

# Install Python packages
install_packages() {
    echo -e "\n${YELLOW}Installing Python dependencies...${NC}"
    
    packages=("python-can" "websockets")
    
    for package in "${packages[@]}"; do
        echo -e "${CYAN}  Installing $package...${NC}"
        if $PYTHON_CMD -m pip install "$package" --quiet; then
            echo -e "${GREEN}  ✓ $package installed${NC}"
        else
            echo -e "${RED}  ✗ Failed to install $package${NC}"
            exit 1
        fi
    done
}

# Create directory structure
init_directory() {
    echo -e "\n${YELLOW}Creating installation directory...${NC}"
    
    if [ -d "$INSTALL_PATH" ]; then
        echo -e "${YELLOW}Directory $INSTALL_PATH already exists.${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            exit 0
        fi
        rm -rf "$INSTALL_PATH"
    fi
    
    mkdir -p "$INSTALL_PATH"
    echo -e "${GREEN}✓ Created: $INSTALL_PATH${NC}"
}

# Copy server.py
copy_server() {
    echo -e "\n${YELLOW}Copying server files...${NC}"
    
    cat > "$INSTALL_PATH/server.py" << 'EOF'
#!/usr/bin/env python3
"""
CAN Bus Train Monitor - Python Server
Serves the React app and runs the WebSocket CAN bridge
"""

import asyncio
import websockets
import json
import can
import http.server
import socketserver
import threading
import webbrowser
import os
from pathlib import Path

# Configuration
HTTP_PORT = 3000
WEBSOCKET_PORT = 8080
CAN_INTERFACE = 'vcan0'
AUTO_OPEN_BROWSER = True

clients = set()

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        pass

async def can_reader(bus):
    loop = asyncio.get_event_loop()
    
    while True:
        try:
            msg = await loop.run_in_executor(None, bus.recv, 0.1)
            
            if msg is not None:
                can_data = {
                    'id': msg.arbitration_id,
                    'data': list(msg.data),
                    'timestamp': msg.timestamp,
                    'is_extended': msg.is_extended_id
                }
                
                if clients:
                    message = json.dumps(can_data)
                    await asyncio.gather(
                        *[client.send(message) for client in clients],
                        return_exceptions=True
                    )
        except Exception as e:
            await asyncio.sleep(0.1)

async def websocket_handler(websocket):
    clients.add(websocket)
    print(f"✓ WebSocket client connected (Total: {len(clients)})")
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                can_msg = can.Message(
                    arbitration_id=data['id'],
                    data=data['data'],
                    is_extended_id=data.get('is_extended', False)
                )
                bus.send(can_msg)
            except Exception as e:
                print(f"✗ Error: {e}")
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        clients.remove(websocket)

def start_http_server():
    handler = CORSHTTPRequestHandler
    with socketserver.TCPServer(("", HTTP_PORT), handler) as httpd:
        print(f"✓ HTTP Server running on http://localhost:{HTTP_PORT}")
        httpd.serve_forever()

async def start_websocket_server(bus):
    asyncio.create_task(can_reader(bus))
    async with websockets.serve(websocket_handler, "localhost", WEBSOCKET_PORT):
        print(f"✓ WebSocket server running on ws://localhost:{WEBSOCKET_PORT}")
        await asyncio.Future()

def main():
    print("\n" + "="*60)
    print("CAN Bus Train Monitor - Server")
    print("="*60 + "\n")
    
    try:
        global bus
        bus = can.interface.Bus(channel=CAN_INTERFACE, interface='socketcan')
        print(f"✓ Connected to CAN interface: {CAN_INTERFACE}")
    except Exception as e:
        print(f"✗ Could not connect to CAN: {e}")
        print("  Running in simulation mode")
        bus = None
    
    http_thread = threading.Thread(target=start_http_server, daemon=True)
    http_thread.start()
    
    if AUTO_OPEN_BROWSER:
        import time
        time.sleep(1)
        webbrowser.open(f'http://localhost:{HTTP_PORT}/train-monitor-standalone.html')
    
    print("\n" + "-"*60)
    print("Server is running!")
    print(f"  → Web Interface: http://localhost:{HTTP_PORT}/train-monitor-standalone.html")
    print(f"  → WebSocket: ws://localhost:{WEBSOCKET_PORT}")
    print("  → Press Ctrl+C to stop")
    print("-"*60 + "\n")
    
    if bus:
        asyncio.run(start_websocket_server(bus))
    else:
        async def dummy_server():
            async with websockets.serve(websocket_handler, "localhost", WEBSOCKET_PORT):
                await asyncio.Future()
        asyncio.run(dummy_server())

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n✓ Server stopped")
    except Exception as e:
        print(f"\n✗ Error: {e}")
EOF
    
    chmod +x "$INSTALL_PATH/server.py"
    echo -e "${GREEN}✓ Created: server.py${NC}"
}

# Copy standalone HTML
copy_html() {
    if [ -f "train-monitor-standalone.html" ]; then
        cp "train-monitor-standalone.html" "$INSTALL_PATH/"
        echo -e "${GREEN}✓ Copied: train-monitor-standalone.html${NC}"
    else
        echo -e "${YELLOW}! Warning: train-monitor-standalone.html not found${NC}"
        echo -e "${YELLOW}  Please copy it to the installation directory manually${NC}"
    fi
}

# Create launcher script
create_launcher() {
    echo -e "\n${YELLOW}Creating launcher script...${NC}"
    
    cat > "$INSTALL_PATH/start-monitor.sh" << 'EOF'
#!/bin/bash
# CAN Bus Train Monitor Launcher

echo "============================================"
echo "CAN Bus Train Monitor"
echo "============================================"
echo ""
echo "Starting server..."
echo ""

# Determine Python command
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "Error: Python not found!"
    exit 1
fi

# Run server
$PYTHON_CMD server.py
EOF
    
    chmod +x "$INSTALL_PATH/start-monitor.sh"
    echo -e "${GREEN}✓ Created: start-monitor.sh${NC}"
}

# Create vcan setup script (Linux only)
create_vcan_setup() {
    echo -e "\n${YELLOW}Creating virtual CAN setup script...${NC}"
    
    cat > "$INSTALL_PATH/setup-vcan.sh" << 'EOF'
#!/bin/bash
# Virtual CAN Interface Setup (Linux only)

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This script is for Linux only."
    echo "Mac users: Use a CAN adapter or run in simulation mode."
    exit 1
fi

echo "Setting up virtual CAN interface (vcan0)..."
echo "This requires sudo privileges."
echo ""

# Load vcan kernel module
sudo modprobe vcan

# Create vcan0 interface
sudo ip link add dev vcan0 type vcan

# Bring up the interface
sudo ip link set up vcan0

# Verify
if ip link show vcan0 &> /dev/null; then
    echo "✓ vcan0 interface created successfully"
    echo ""
    echo "To make this permanent, add to /etc/network/interfaces:"
    echo "  auto vcan0"
    echo "  iface vcan0 inet manual"
    echo "    pre-up ip link add dev vcan0 type vcan"
    echo "    up ip link set up vcan0"
else
    echo "✗ Failed to create vcan0 interface"
    exit 1
fi
EOF
    
    chmod +x "$INSTALL_PATH/setup-vcan.sh"
    echo -e "${GREEN}✓ Created: setup-vcan.sh${NC}"
}

# Create README
create_readme() {
    echo -e "\n${YELLOW}Creating README...${NC}"
    
    cat > "$INSTALL_PATH/README.txt" << EOF
# CAN Bus Train Monitor - Portable Installation

## Installation Directory
$INSTALL_PATH

## Quick Start

### Linux/Mac
1. Open terminal in this directory
2. Run: ./start-monitor.sh
3. Browser opens automatically at http://localhost:3000/train-monitor-standalone.html
4. Press Ctrl+C to stop

### Manual Start
\`\`\`
python3 server.py
\`\`\`
Then open: http://localhost:3000/train-monitor-standalone.html

## Files Included

- server.py - Python backend server (HTTP + WebSocket)
- train-monitor-standalone.html - Self-contained web interface
- start-monitor.sh - Launcher script
- setup-vcan.sh - Virtual CAN setup (Linux only)
- README.txt - This file

## Requirements

- Python 3.7 or higher
- Python packages: python-can, websockets
- Modern web browser

## Virtual CAN Setup (Linux)

For testing with virtual CAN:
\`\`\`
./setup-vcan.sh
\`\`\`

Or manually:
\`\`\`
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
\`\`\`

## Configuration

Edit server.py to change:
- HTTP_PORT = 3000 - Web server port
- WEBSOCKET_PORT = 8080 - WebSocket port
- CAN_INTERFACE = 'vcan0' - CAN interface name
- AUTO_OPEN_BROWSER = True - Auto-open browser

## Mac Notes

- Virtual CAN not natively supported
- Use real CAN adapter or run in simulation mode
- Simulation mode works without CAN hardware

## Troubleshooting

### Python not found
Install Python:
- Linux: sudo apt install python3 python3-pip
- Mac: brew install python3

### Missing packages
\`\`\`
pip3 install python-can websockets
\`\`\`

### Permission denied on scripts
\`\`\`
chmod +x start-monitor.sh setup-vcan.sh
\`\`\`

### Port already in use
- Change HTTP_PORT or WEBSOCKET_PORT in server.py
- Or: lsof -ti:3000 | xargs kill (to free port 3000)

### Browser doesn't open
Manually navigate to: http://localhost:3000/train-monitor-standalone.html

## Features

- Real-time CAN bus monitoring
- Animated train visualization
- Battery management with dead protection
- Odometer tracking
- Speed control (0-120 km/h)
- Temperature and fan monitoring
- Power consumption tracking

## Support

- Check Python version: python3 --version
- Check packages: pip3 list | grep -E "can|websockets"
- View server logs in terminal
- Check firewall for ports 3000 and 8080

---
Installation date: $(date)
Platform: $(uname -s)
EOF
    
    echo -e "${GREEN}✓ Created: README.txt${NC}"
}

# Main installation process
main() {
    echo "Installation Path: $INSTALL_PATH"
    echo ""
    
    # Check Python
    if [ "$SKIP_PYTHON" = false ]; then
        if ! check_python; then
            echo -e "\n${RED}Python is required but not found.${NC}"
            echo -e "${YELLOW}Install Python:${NC}"
            echo "  - Linux: sudo apt install python3 python3-pip"
            echo "  - Mac: brew install python3"
            echo ""
            echo "Or use --skip-python to continue without checking"
            exit 1
        fi
    else
        # Default to python3
        PYTHON_CMD="python3"
    fi
    
    # Create directory
    init_directory
    
    # Install dependencies
    if [ "$SKIP_DEPENDENCIES" = false ] && [ "$SKIP_PYTHON" = false ]; then
        install_packages
    else
        echo -e "\n${YELLOW}Skipping Python package installation...${NC}"
    fi
    
    # Copy files
    copy_server
    copy_html
    
    # Copy demo.dbc if it exists
    if [ -f "demo.dbc" ]; then
        cp "demo.dbc" "$INSTALL_PATH/"
        echo -e "${GREEN}✓ Copied: demo.dbc${NC}"
    fi
    
    # Create scripts
    create_launcher
    create_vcan_setup
    create_readme
    
    echo -e "\n${GREEN}=============================================${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}=============================================${NC}\n"
    
    echo -e "${CYAN}Installation directory: $INSTALL_PATH${NC}"
    echo ""
    echo -e "${YELLOW}To start the monitor:${NC}"
    echo -e "${NC}  1. cd $INSTALL_PATH${NC}"
    echo -e "${NC}  2. ./start-monitor.sh${NC}"
    echo ""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${YELLOW}For virtual CAN testing:${NC}"
        echo -e "${NC}  ./setup-vcan.sh${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}Press Enter to open the installation directory...${NC}"
    read
    
    # Open directory based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$INSTALL_PATH"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v xdg-open &> /dev/null; then
            xdg-open "$INSTALL_PATH"
        elif command -v nautilus &> /dev/null; then
            nautilus "$INSTALL_PATH"
        else
            echo "Installation directory: $INSTALL_PATH"
        fi
    fi
}

# Run main installation
main
