# CAN Bus Train Monitor - Portable Installer for Windows
# This script sets up the complete train monitoring system

param(
    [string]$InstallPath = "$env:USERPROFILE\CANTrainMonitor",
    [switch]$SkipPython,
    [switch]$SkipDependencies
)

$ErrorActionPreference = "Stop"

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "CAN Bus Train Monitor - Portable Installer" -ForegroundColor Cyan
Write-Host "=============================================`n" -ForegroundColor Cyan

# Check if Python is installed
function Test-Python {
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Python not found" -ForegroundColor Red
        return $false
    }
}

# Install Python packages
function Install-PythonPackages {
    Write-Host "`nInstalling Python dependencies..." -ForegroundColor Yellow
    
    $packages = @("python-can", "websockets")
    
    foreach ($package in $packages) {
        Write-Host "  Installing $package..." -ForegroundColor Gray
        python -m pip install $package --quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $package installed" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Failed to install $package" -ForegroundColor Red
            throw "Package installation failed"
        }
    }
}

# Create directory structure
function Initialize-Directory {
    param([string]$Path)
    
    Write-Host "`nCreating installation directory..." -ForegroundColor Yellow
    
    if (Test-Path $Path) {
        $response = Read-Host "Directory $Path already exists. Overwrite? (Y/N)"
        if ($response -ne "Y" -and $response -ne "y") {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
            exit 0
        }
        Remove-Item -Path $Path -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Write-Host "✓ Created: $Path" -ForegroundColor Green
}

# Copy server.py
function Copy-ServerFile {
    param([string]$DestPath)
    
    Write-Host "`nCopying server files..." -ForegroundColor Yellow
    
    $serverContent = @'
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
'@
    
    $serverPath = Join-Path $DestPath "server.py"
    Set-Content -Path $serverPath -Value $serverContent -Encoding UTF8
    Write-Host "✓ Created: server.py" -ForegroundColor Green
}

# Copy standalone HTML
function Copy-StandaloneHTML {
    param([string]$DestPath)
    
    # Check if the standalone HTML exists in current directory
    $sourcePath = "train-monitor-standalone.html"
    $destFile = Join-Path $DestPath "train-monitor-standalone.html"
    
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destFile
        Write-Host "✓ Copied: train-monitor-standalone.html" -ForegroundColor Green
    } else {
        Write-Host "! Warning: train-monitor-standalone.html not found in current directory" -ForegroundColor Yellow
        Write-Host "  Please copy train-monitor-standalone.html to the installation directory manually" -ForegroundColor Yellow
    }
}

# Create launcher script
function Create-Launcher {
    param([string]$DestPath)
    
    Write-Host "`nCreating launcher script..." -ForegroundColor Yellow
    
    $launcherContent = @"
@echo off
echo ============================================
echo CAN Bus Train Monitor
echo ============================================
echo.
echo Starting server...
python server.py
pause
"@
    
    $launcherPath = Join-Path $DestPath "start-monitor.bat"
    Set-Content -Path $launcherPath -Value $launcherContent -Encoding ASCII
    Write-Host "✓ Created: start-monitor.bat" -ForegroundColor Green
}

# Create PowerShell launcher
function Create-PowerShellLauncher {
    param([string]$DestPath)
    
    $psLauncherContent = @'
# CAN Bus Train Monitor Launcher
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CAN Bus Train Monitor" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "Starting server..." -ForegroundColor Yellow

try {
    python server.py
} catch {
    Write-Host "`nError starting server: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
'@
    
    $psLauncherPath = Join-Path $DestPath "start-monitor.ps1"
    Set-Content -Path $psLauncherPath -Value $psLauncherContent -Encoding UTF8
    Write-Host "✓ Created: start-monitor.ps1" -ForegroundColor Green
}

# Create README
function Create-ReadMe {
    param([string]$DestPath)
    
    Write-Host "`nCreating README..." -ForegroundColor Yellow
    
    $readmeContent = @"
# CAN Bus Train Monitor - Portable Installation

## Installation Directory
$DestPath

## Quick Start

### Windows
1. Double-click `start-monitor.bat` to launch the server
2. Your browser will automatically open to the monitor interface
3. Press Ctrl+C in the terminal to stop the server

### PowerShell
1. Right-click `start-monitor.ps1` and select "Run with PowerShell"
2. Or open PowerShell and run: .\start-monitor.ps1

### Manual Start
```
python server.py
```
Then open: http://localhost:3000/train-monitor-standalone.html

## Files Included

- `server.py` - Python backend server (HTTP + WebSocket)
- `train-monitor-standalone.html` - Self-contained web interface
- `start-monitor.bat` - Windows batch launcher
- `start-monitor.ps1` - PowerShell launcher
- `README.txt` - This file

## Requirements

- Python 3.7 or higher
- Python packages: python-can, websockets

## Configuration

Edit `server.py` to change:
- `HTTP_PORT = 3000` - Web server port
- `WEBSOCKET_PORT = 8080` - WebSocket port
- `CAN_INTERFACE = 'vcan0'` - CAN interface name
- `AUTO_OPEN_BROWSER = True` - Auto-open browser

## CAN Interface Setup (Linux)

For virtual CAN testing:
```
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

## Troubleshooting

### Python not found
- Install Python from https://www.python.org/downloads/
- Make sure Python is added to PATH

### Missing packages
Run: python -m pip install python-can websockets

### Port already in use
- Change HTTP_PORT or WEBSOCKET_PORT in server.py
- Or close the application using the port

### Browser doesn't open
- Manually navigate to: http://localhost:3000/train-monitor-standalone.html

## Features

- Real-time CAN bus monitoring
- Animated train visualization
- Battery management with dead protection
- Odometer tracking
- Speed control
- Temperature and fan monitoring
- Power consumption tracking

## Support

For issues, check:
- Python and packages are installed correctly
- Firewall allows connections to ports 3000 and 8080
- CAN interface is properly configured (if using real CAN)

---
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    $readmePath = Join-Path $DestPath "README.txt"
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host "✓ Created: README.txt" -ForegroundColor Green
}

# Main installation process
try {
    Write-Host "Installation Path: $InstallPath" -ForegroundColor Cyan
    Write-Host ""
    
    # Check Python
    if (-not $SkipPython) {
        if (-not (Test-Python)) {
            Write-Host "`nPython is required but not found." -ForegroundColor Red
            Write-Host "Please install Python from https://www.python.org/downloads/" -ForegroundColor Yellow
            Write-Host "Or use -SkipPython to continue without checking" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Create directory
    Initialize-Directory -Path $InstallPath
    
    # Install dependencies
    if (-not $SkipDependencies -and -not $SkipPython) {
        Install-PythonPackages
    } else {
        Write-Host "`nSkipping Python package installation..." -ForegroundColor Yellow
    }
    
    # Copy files
    Copy-ServerFile -DestPath $InstallPath
    Copy-StandaloneHTML -DestPath $InstallPath
    
    # Create launchers
    Create-Launcher -DestPath $InstallPath
    Create-PowerShellLauncher -DestPath $InstallPath
    
    # Create README
    Create-ReadMe -DestPath $InstallPath
    
    Write-Host "`n=============================================" -ForegroundColor Green
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "=============================================`n" -ForegroundColor Green
    
    Write-Host "Installation directory: $InstallPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To start the monitor:" -ForegroundColor Yellow
    Write-Host "  1. Navigate to: $InstallPath" -ForegroundColor White
    Write-Host "  2. Run: start-monitor.bat (or start-monitor.ps1)" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Enter to open the installation directory..." -ForegroundColor Yellow
    Read-Host
    
    # Open installation directory
    Invoke-Item $InstallPath
    
} catch {
    Write-Host "`n✗ Installation failed: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
