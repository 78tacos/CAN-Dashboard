# CAN Bus Train Monitor - Installation Guide

## Overview
You now have three ways to run the CAN Bus Train Monitor:

1. **Self-Contained HTML File** - Single file, no installation needed (requires Python server)
2. **Portable Installer (PowerShell)** - Automated installation with full setup
3. **Portable Installer (Batch)** - Simple Windows batch installer

---

## Option 1: Self-Contained HTML File

### File: `train-monitor-standalone.html`

This is a single HTML file with all JavaScript embedded. Perfect for:
- Quick demos
- Sharing with others
- No file dependencies

### How to Use:
1. Start the Python server:
   ```
   python server.py
   ```

2. Open in browser:
   ```
   http://localhost:3000/train-monitor-standalone.html
   ```

Or simply double-click `train-monitor-standalone.html` and it will try to connect to the WebSocket server.

---

## Option 2: PowerShell Installer (Recommended for Windows)

### File: `install-portable.ps1`

Full-featured installer with error checking and configuration options.

### How to Use:

#### Basic Installation:
```powershell
.\install-portable.ps1
```

#### Custom Installation Path:
```powershell
.\install-portable.ps1 -InstallPath "C:\MyApps\TrainMonitor"
```

#### Skip Python Check:
```powershell
.\install-portable.ps1 -SkipPython
```

#### Skip Dependency Installation:
```powershell
.\install-portable.ps1 -SkipDependencies
```

### What It Does:
- ✓ Checks for Python installation
- ✓ Installs required Python packages (python-can, websockets)
- ✓ Creates installation directory (default: `%USERPROFILE%\CANTrainMonitor`)
- ✓ Copies all necessary files
- ✓ Creates launcher scripts (.bat and .ps1)
- ✓ Generates detailed README
- ✓ Opens installation directory when done

### After Installation:
Navigate to the installation directory and run:
- `start-monitor.bat` (double-click)
- OR `start-monitor.ps1` (right-click → Run with PowerShell)

---

## Option 3: Bash Installer (Linux/Mac)

### File: `install-portable.sh`

Cross-platform Unix installer for Linux and macOS.

### How to Use:

#### Make executable and run:
```bash
chmod +x install-portable.sh
./install-portable.sh
```

#### Custom Installation Path:
```bash
./install-portable.sh --install-path "/opt/CANTrainMonitor"
```

#### Skip Python Check:
```bash
./install-portable.sh --skip-python
```

#### Skip Dependency Installation:
```bash
./install-portable.sh --skip-dependencies
```

#### Show Help:
```bash
./install-portable.sh --help
```

### What It Does:
- ✓ Checks for Python 3 installation
- ✓ Installs required Python packages via pip3
- ✓ Creates installation directory (default: `~/CANTrainMonitor`)
- ✓ Copies all necessary files
- ✓ Creates launcher script (start-monitor.sh)
- ✓ Creates virtual CAN setup script (Linux only)
- ✓ Generates detailed README
- ✓ Opens installation directory (if GUI available)

### After Installation:
Navigate to the installation directory and run:
```bash
./start-monitor.sh
```

For virtual CAN testing (Linux):
```bash
./setup-vcan.sh
```

---

## Option 4: Batch Installer (Windows - Simplest)

### File: `install-portable.bat`

Simple Windows batch file installer.

### How to Use:
1. Double-click `install-portable.bat`
2. Follow the on-screen prompts
3. Installation directory will open automatically

### What It Does:
- ✓ Checks for Python
- ✓ Installs Python packages
- ✓ Copies files to `%USERPROFILE%\CANTrainMonitor`
- ✓ Creates launcher script
- ✓ Generates README

---

## Files Created After Installation

```
CANTrainMonitor/
├── server.py                      # Python backend server
├── train-monitor-standalone.html  # Self-contained web interface
├── start-monitor.bat              # Windows launcher
├── start-monitor.sh               # Linux/Mac launcher
├── start-monitor.ps1              # PowerShell launcher (if using PS installer)
├── setup-vcan.sh                  # Virtual CAN setup (Linux only)
├── demo.dbc                       # CAN database (if available)
└── README.txt                     # Usage instructions
```

---

## Running the Monitor

### Method 1: Using Launcher (Easiest)

**Windows:**
```
Double-click start-monitor.bat
```

**Linux/Mac:**
```bash
./start-monitor.sh
```

### Method 2: Manual Python

**Linux/Mac:**
```bash
cd ~/CANTrainMonitor
python3 server.py
```

**Windows:**
```bash
cd %USERPROFILE%\CANTrainMonitor
python server.py
```

### Method 3: PowerShell (Windows)
```powershell
cd $env:USERPROFILE\CANTrainMonitor
.\start-monitor.ps1
```

The browser will automatically open to:
```
http://localhost:3000/train-monitor-standalone.html
```

---

## Configuration

Edit `server.py` to customize:

```python
HTTP_PORT = 3000              # Web server port
WEBSOCKET_PORT = 8080         # WebSocket port
CAN_INTERFACE = 'vcan0'       # CAN interface name
AUTO_OPEN_BROWSER = True      # Auto-open browser on start
```

---

## Requirements

### Python
- Version: 3.7 or higher
- Download: 
  - Windows: https://www.python.org/downloads/
  - Linux: `sudo apt install python3 python3-pip` (Ubuntu/Debian) or `sudo yum install python3 python3-pip` (RHEL/CentOS)
  - Mac: `brew install python3` or https://www.python.org/downloads/

### Python Packages
```bash
# Linux/Mac
pip3 install python-can websockets

# Windows
pip install python-can websockets
```

The installers handle this automatically.

---

## CAN Interface Setup

### Virtual CAN (Linux) - For Testing
```bash
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

Or use the automated setup script:
```bash
./setup-vcan.sh
```

### Virtual CAN (Mac) - Not Natively Supported
macOS doesn't support virtual CAN natively. Options:
1. **Run in simulation mode** (works without CAN)
2. **Use a USB CAN adapter** (e.g., PEAK, Vector)
3. **Use a Linux VM or Docker** for vcan support

### Real CAN Interface (All Platforms)
Update `CAN_INTERFACE` in `server.py`:
```python
CAN_INTERFACE = 'can0'  # or your actual interface
```

Supported interfaces:
- **Linux**: socketcan (can0, can1, vcan0, etc.)
- **Windows**: PEAK, Vector, Kvaser (via python-can)
- **Mac**: USB CAN adapters with drivers

---

## Troubleshooting

### "Python not found"
- **Windows**: Install Python from python.org, check "Add Python to PATH"
- **Linux**: `sudo apt install python3 python3-pip`
- **Mac**: `brew install python3` or install from python.org

### "Module not found"
```bash
# Linux/Mac
pip3 install python-can websockets

# Windows
pip install python-can websockets
```

### "Permission denied" on scripts (Linux/Mac)
```bash
chmod +x start-monitor.sh
chmod +x install-portable.sh
chmod +x setup-vcan.sh
```

### "Port already in use"
**Linux/Mac:**
```bash
# Find and kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or change port in server.py
```

**Windows:**
```powershell
# Find process on port 3000
netstat -ano | findstr :3000

# Kill process (replace PID)
taskkill /PID <PID> /F

# Or change port in server.py
```

### Browser doesn't open
- Manually navigate to: http://localhost:3000/train-monitor-standalone.html

### WebSocket connection failed
- Make sure server.py is running
- Check firewall settings for ports 3000 and 8080
- **Linux**: `sudo ufw allow 3000` and `sudo ufw allow 8080`
- **Mac**: Check System Preferences → Security & Privacy → Firewall

### Virtual CAN not working (Linux)
```bash
# Check if module loaded
lsmod | grep vcan

# Check if interface exists
ip link show vcan0

# Reload if needed
sudo modprobe -r vcan
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

---

## Features

✓ Real-time CAN bus monitoring
✓ Animated train visualization with expressions
✓ Battery management with dead protection
✓ Odometer tracking
✓ Speed control (0-120 km/h)
✓ Temperature and fan monitoring
✓ Power consumption tracking
✓ Component status bars
✓ CAN message display

---

## Distribution

To share with others:

### Option A: Self-Contained HTML
Just send `train-monitor-standalone.html` and `server.py`

### Option B: Portable Package
1. Run the installer yourself
2. Zip the installation directory
3. Share the zip file
4. Recipients just unzip and run `start-monitor.bat`

### Option C: Installer Script
Share `install-portable.bat` or `install-portable.ps1` along with source files

---

## Uninstallation

Simply delete the installation directory:
```
%USERPROFILE%\CANTrainMonitor
```

Or if you used a custom path, delete that directory.

---

## Support & Development

### Project Files:
- `server.py` - Backend server
- `monitor.js` - React application (if separate)
- `index.html` - HTML template (if separate)
- `demo.dbc` - CAN database definition

### Key CAN Messages:
- 0x100: Speed control
- 0x200: Battery level & voltage
- 0x300: Temperature & fan speed
- 0x400: Power consumption & current
- 0x500: Odometer reading

---

## Tips

1. **Demo Mode**: The monitor works without a real CAN interface - it runs in simulation mode
2. **Battery Protection**: Train automatically stops when battery reaches 0%
3. **Performance**: Optimized for 60 FPS with smooth animations
4. **Responsive**: Works on desktop, tablet, and mobile browsers
5. **Dark Theme**: Easy on the eyes for extended monitoring

---

Generated: $(date)
