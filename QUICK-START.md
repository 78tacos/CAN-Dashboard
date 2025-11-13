# Quick Start Guide - CAN Bus Train Monitor

## Fastest Way to Get Started (3 Steps)

### 1. Install (Choose One Method)

**🐳 Docker (Easiest - All Platforms):**
```bash
docker-compose up -d
# Or: docker run -d -p 3000:3000 -p 8080:8080 can-train-monitor
```

**Windows - Batch Installer (Easiest):**
```
Double-click: install-portable.bat
```

**Windows - PowerShell Installer (Recommended):**
```powershell
.\install-portable.ps1
```

**Linux/Mac - Bash Installer:**
```bash
chmod +x install-portable.sh
./install-portable.sh
```

**Quick Run (No Installation):**
```bash
# Windows
start-monitor.bat

# Linux/Mac
chmod +x start-monitor.sh
./start-monitor.sh
```

**Manual Installation:**
```bash
# Windows
mkdir %USERPROFILE%\CANTrainMonitor
cd %USERPROFILE%\CANTrainMonitor

# Linux/Mac
mkdir ~/CANTrainMonitor
cd ~/CANTrainMonitor

# All platforms - Copy files and install
pip install python-can websockets
```

### 2. Run

**Windows:**
```
Double-click: start-monitor.bat
```

**Linux/Mac:**
```bash
./start-monitor.sh
```

**Or manually:**
```bash
python3 server.py  # Linux/Mac
python server.py   # Windows
```

### 3. Use
- Browser opens automatically to the monitor
- Click "Start Simulation" to begin
- Adjust speed with the slider
- Watch the animated train respond!

---

## What You'll See

```
┌─────────────────────────────────────────────┐
│    Electric Train CAN Bus Monitor          │
├─────────────────────────────────────────────┤
│  ● CAN Connected    [Stop Simulation]      │
│  Target Speed: 80 km/h  [====|====]        │
├─────────────────────────────────────────────┤
│ Odometer        │  Train Status             │
│  15.42 km       │  😊 Happy & Energized     │
│                 │  🚂 [animated train]      │
│ Speed           │                           │
│  80.0 km/h      │  Component Status         │
│  ████████░░     │  🌡️ Temperature: 45°C    │
│                 │  💨 Fan Speed: 60%        │
│ Battery         │  ⚡ Power: 120.0 kW      │
│  75.2%          │  🔋 Current: 300.0 A     │
│  ████████░░     │                           │
│  380V  300A     │  CAN Messages            │
│                 │  0x100 SPEED: 80 km/h    │
│                 │  0x200 BATTERY: 75%      │
└─────────────────┴───────────────────────────┘
```

---

## Controls

**Start/Stop Button** - Begin or end the simulation
**Speed Slider** - Set target speed (0-120 km/h)
**Browser Refresh** - Reset to defaults

---

## Features at a Glance

✓ **Real-time Monitoring** - Live CAN bus data
✓ **Animated Train** - Changes color/expression based on battery
✓ **Battery Protection** - Auto-stops at 0%
✓ **Odometer** - Tracks distance traveled
✓ **Component Status** - Temperature, fan, power, current
✓ **CAN Messages** - View raw message data

---

## Common Commands

### Start Server
```bash
# Linux/Mac
python3 server.py

# Windows
python server.py
```

### Stop Server
```
Press Ctrl+C
```

### View in Browser
```
http://localhost:3000/train-monitor-standalone.html
```

### Check Python
```bash
# Linux/Mac
python3 --version

# Windows
python --version
```

### Install Dependencies
```bash
# Linux/Mac
pip3 install python-can websockets

# Windows
pip install python-can websockets
```

### Virtual CAN Setup (Linux only)
```bash
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Or use the setup script
./setup-vcan.sh
```

---

## Tips & Tricks

1. **No CAN Hardware?** No problem! Works in simulation mode
2. **Customize Ports** Edit server.py (lines 14-15)
3. **Battery Low?** Refresh browser to reset to 100%
4. **Speed Limits** Train can go 0-120 km/h
5. **Watch the Train** Expressions change with battery level!

---

## Train States

| Battery | Train Face | Color | Behavior |
|---------|-----------|-------|----------|
| >60% | 😊 Happy | Blue | Energized, bright eyes |
| 30-60% | 😐 Okay | Yellow | Neutral expression |
| <30% | 😫 Tired | Red | Tired, smoke effects |
| 0% | 💀 Dead | Dark | Cannot start |

---

## Troubleshooting (Quick Fixes)

**Problem:** Python not found
**Fix:** Install from python.org

**Problem:** Module not found
**Fix:** `pip install python-can websockets`

**Problem:** Port already in use
**Fix:** Change ports in server.py or close other apps

**Problem:** Browser won't open
**Fix:** Manually go to http://localhost:3000/train-monitor-standalone.html

---

## Next Steps

1. ✓ Install and run (you're here!)
2. Connect real CAN hardware (optional)
3. Customize CAN messages in demo.dbc
4. Modify server.py for your setup
5. Share with teammates!

---

## Need Help?

Check the full **INSTALLATION-GUIDE.md** for:
- Detailed installation instructions
- Configuration options
- CAN interface setup
- Advanced features
- Distribution methods

---

**That's it! Enjoy your CAN Bus Train Monitor! 🚂**
