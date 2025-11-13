# Platform-Specific Installation Guide

Quick reference for platform-specific installation and setup.

---

## 🪟 Windows

### Quick Install
```powershell
# Option 1: Batch (Easiest)
install-portable.bat

# Option 2: PowerShell (Recommended)
.\install-portable.ps1

# Option 3: Quick run
start-monitor.bat
```

### Requirements
- Python 3.7+: https://www.python.org/downloads/
- Make sure "Add Python to PATH" is checked

### Python Commands
```powershell
python --version
pip install python-can websockets
python server.py
```

### Common Issues
**Python not found:**
```powershell
# Check PATH
$env:PATH -split ';' | Select-String python

# Or use full path
C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe server.py
```

**Port in use:**
```powershell
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

### Firewall
Windows Defender may ask for permission - Allow it.

---

## 🐧 Linux

### Quick Install
```bash
# Option 1: Installer
chmod +x install-portable.sh
./install-portable.sh

# Option 2: Quick run
chmod +x start-monitor.sh
./start-monitor.sh
```

### Requirements Install

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3 python3-pip
pip3 install python-can websockets
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install python3 python3-pip
pip3 install python-can websockets
```

**Arch Linux:**
```bash
sudo pacman -S python python-pip
pip install python-can websockets
```

### Virtual CAN Setup
```bash
# Automated
./setup-vcan.sh

# Manual
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Verify
ip link show vcan0
```

### Make Permanent
Add to `/etc/network/interfaces`:
```
auto vcan0
iface vcan0 inet manual
    pre-up ip link add dev vcan0 type vcan
    up ip link set up vcan0
```

Or create systemd service `/etc/systemd/system/vcan.service`:
```ini
[Unit]
Description=Virtual CAN interface
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/modprobe vcan
ExecStart=/sbin/ip link add dev vcan0 type vcan
ExecStart=/sbin/ip link set up vcan0
ExecStop=/sbin/ip link del vcan0

[Install]
WantedBy=multi-user.target
```

Enable it:
```bash
sudo systemctl enable vcan.service
sudo systemctl start vcan.service
```

### Common Issues
**Permission denied:**
```bash
chmod +x *.sh
```

**Port in use:**
```bash
lsof -ti:3000 | xargs kill -9
```

**Firewall:**
```bash
sudo ufw allow 3000
sudo ufw allow 8080
```

---

## 🍎 macOS

### Quick Install
```bash
# Option 1: Installer
chmod +x install-portable.sh
./install-portable.sh

# Option 2: Quick run  
chmod +x start-monitor.sh
./start-monitor.sh
```

### Requirements Install

**Using Homebrew (Recommended):**
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python
brew install python3

# Install packages
pip3 install python-can websockets
```

**Using Official Python:**
1. Download from https://www.python.org/downloads/macos/
2. Install DMG
3. Open Terminal:
```bash
pip3 install python-can websockets
```

### Virtual CAN - NOT SUPPORTED
macOS doesn't have native virtual CAN support. Options:

**Option 1: Simulation Mode (Easiest)**
- Just run the monitor
- It works without CAN hardware
- Perfect for demos

**Option 2: USB CAN Adapter**
- PEAK PCAN-USB
- Intrepid neoVI
- Install manufacturer's drivers
- Update `CAN_INTERFACE` in server.py

**Option 3: Docker/VM**
```bash
# Use Docker with Linux
docker run -it --privileged ubuntu:latest
# Then follow Linux instructions inside container
```

**Option 4: Parallels/VMware**
- Run Linux VM
- Use virtual CAN inside VM

### Common Issues

**"python3: command not found":**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="/usr/local/bin:/usr/local/opt/python/libexec/bin:$PATH"
```

**Port in use:**
```bash
lsof -ti:3000 | xargs kill -9
```

**Firewall:**
```bash
# System Preferences → Security & Privacy → Firewall
# Allow Python
```

**Permission issues:**
```bash
chmod +x start-monitor.sh
chmod +x install-portable.sh
```

---

## 📱 Platform Feature Matrix

| Feature | Windows | Linux | Mac |
|---------|---------|-------|-----|
| Python Support | ✅ | ✅ | ✅ |
| HTTP Server | ✅ | ✅ | ✅ |
| WebSocket | ✅ | ✅ | ✅ |
| Simulation Mode | ✅ | ✅ | ✅ |
| Virtual CAN | ⚠️ WSL | ✅ Native | ❌ No |
| Real CAN Hardware | ✅ Drivers | ✅ Native | ✅ USB |
| Auto Browser Open | ✅ | ✅ | ✅ |
| Installer Script | ✅ .bat/.ps1 | ✅ .sh | ✅ .sh |

---

## 🔧 Platform-Specific Configuration

### Windows - Use Backslashes
```python
CAN_INTERFACE = 'PCAN_USBBUS1'  # PEAK
CAN_INTERFACE = 'vector0'        # Vector
```

### Linux - Use SocketCAN
```python
CAN_INTERFACE = 'can0'   # Real hardware
CAN_INTERFACE = 'vcan0'  # Virtual
CAN_INTERFACE = 'slcan0' # Serial CAN
```

### Mac - Depends on Adapter
```python
CAN_INTERFACE = 'PCAN_USBBUS1'  # PEAK with driver
# Or run in simulation mode
```

---

## 🚀 Quick Start by Platform

### Windows User
1. Download all files
2. Double-click `install-portable.bat`
3. Wait for installation
4. Double-click `start-monitor.bat` in installed directory
5. Done! Browser opens automatically

### Linux User
1. Download all files
2. `chmod +x install-portable.sh && ./install-portable.sh`
3. `cd ~/CANTrainMonitor && ./start-monitor.sh`
4. Optional: `./setup-vcan.sh` for virtual CAN
5. Done! Browser opens automatically

### Mac User
1. Download all files
2. `chmod +x install-portable.sh && ./install-portable.sh`
3. `cd ~/CANTrainMonitor && ./start-monitor.sh`
4. Note: No virtual CAN, use simulation mode
5. Done! Browser opens automatically

---

## 📞 Getting Help

### Windows
- Python issues: https://www.python.org/downloads/windows/
- PATH issues: https://docs.python.org/3/using/windows.html

### Linux  
- Distribution forums
- `man python3`
- SocketCAN docs: https://www.kernel.org/doc/html/latest/networking/can.html

### Mac
- Homebrew: https://brew.sh/
- Python on Mac: https://docs.python.org/3/using/mac.html

---

## 🎯 Recommended Setup by Use Case

### Learning/Demo (Any Platform)
- Use simulation mode
- No CAN hardware needed
- Quick install with batch/shell script

### Development with Virtual CAN
- **Best**: Linux (native vcan support)
- **Alternative**: Windows with WSL2
- **Mac**: Use Docker or VM

### Production with Real Hardware
- **Windows**: PEAK/Vector/Kvaser with drivers
- **Linux**: SocketCAN with any adapter
- **Mac**: USB adapters with drivers

---

*Last updated: November 10, 2025*
