# Docker Container with Host CAN Access

This guide explains how to run the CAN Bus Train Monitor Docker container with access to the host's CAN interfaces and tools like `candump`.

---

## 🔑 Key Configuration

The Docker container is configured with:

- **Privileged Mode**: `privileged: true` - Required for CAN interface access
- **Network Mode Host**: `network_mode: host` - Allows direct access to host's network interfaces including CAN
- **CAN Utils**: Pre-installed `can-utils` package (includes `candump`, `cansend`, etc.)

---

## 🚀 Quick Start

### For Linux (Recommended for Real CAN Hardware)

```bash
# Build and start with host network access
docker-compose up -d

# The container now has access to all host CAN interfaces
# You can use candump, cansend, etc. from within the container
```

### Verify CAN Access

```bash
# Enter the container
docker exec -it can-train-monitor bash

# List available CAN interfaces (should show host's interfaces)
ip link show | grep can

# Use candump to monitor CAN traffic
candump vcan0

# Or any other CAN interface from the host
candump can0
```

---

## 🔧 Network Mode Explained

### `network_mode: host`

When enabled:
- ✅ Container shares the host's network stack
- ✅ Direct access to host's CAN interfaces (vcan0, can0, can1, etc.)
- ✅ Can use host's IP address
- ✅ `candump` and other CAN tools work directly with host interfaces
- ⚠️ Port mapping (`ports:`) is ignored (container uses host ports directly)
- ⚠️ Health checks may not work as expected

**Access application at:** `http://localhost:3000` (directly on host)

### Without `network_mode: host` (Bridge Mode)

When disabled:
- ✅ Standard port mapping works (`3000:3000`, `8080:8080`)
- ✅ Health checks work
- ✅ Better isolation
- ❌ No direct access to host CAN interfaces
- ⚠️ Requires `--device` flag to pass through CAN devices

---

## 🐧 Linux Setup Examples

### Option 1: Host Network (Easiest)

**docker-compose.yml:**
```yaml
services:
  can-train-monitor:
    network_mode: host
    privileged: true
```

**Start:**
```bash
docker-compose up -d
```

**Access:** `http://localhost:3000`

---

### Option 2: Bridge Network with Device Passthrough

**docker-compose.yml:**
```yaml
services:
  can-train-monitor:
    privileged: true
    devices:
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "3000:3000"
      - "8080:8080"
```

**Start with specific CAN device:**
```bash
docker run -d \
  --name can-train-monitor \
  --privileged \
  --device=/dev/net/tun \
  -p 3000:3000 \
  -p 8080:8080 \
  can-train-monitor
```

---

## 🪟 Windows / macOS Limitations

**Important:** `network_mode: host` only works on Linux.

### Windows with WSL2

```bash
# In WSL2, set up vcan
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Run Docker with privileged mode
docker-compose up -d
```

### Windows without WSL2 / macOS

Use bridge mode without `network_mode: host`:

**docker-compose.yml:**
```yaml
services:
  can-train-monitor:
    privileged: true
    ports:
      - "3000:3000"
      - "8080:8080"
    # Comment out network_mode: host
```

---

## 🛠️ CAN Tools Available in Container

The container includes `can-utils` package with these tools:

| Tool | Description |
|------|-------------|
| `candump` | Display CAN messages |
| `cansend` | Send CAN messages |
| `canplayer` | Replay CAN log files |
| `cangen` | Generate random CAN traffic |
| `cansequence` | Send sequence of CAN messages |
| `cansniffer` | Interactive CAN traffic analyzer |

### Examples

```bash
# Monitor all CAN traffic on vcan0
docker exec -it can-train-monitor candump vcan0

# Send a test message
docker exec -it can-train-monitor cansend vcan0 123#DEADBEEF

# Generate random traffic
docker exec -it can-train-monitor cangen vcan0 -g 100

# Interactive sniffer
docker exec -it can-train-monitor cansniffer vcan0
```

---

## 🔍 Troubleshooting

### Can't See Host CAN Interfaces

**Problem:** `ip link show` doesn't show host's CAN interfaces

**Solution:**
1. Ensure `network_mode: host` is enabled
2. Verify container is running with `privileged: true`
3. Check host has CAN interfaces: `ip link show | grep can`

### candump: No such device

**Problem:** `candump: No such device "vcan0"`

**Solution:**
```bash
# On host, create vcan0
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Verify it exists
ip link show vcan0

# Now accessible in container (with network_mode: host)
docker exec -it can-train-monitor candump vcan0
```

### Port Already in Use

**Problem:** Port 3000 or 8080 already in use

**Solution with `network_mode: host`:**
- Container uses host's ports directly
- Stop other services using ports 3000/8080
- Or change `HTTP_PORT` and `WEBSOCKET_PORT` environment variables

**Solution with bridge mode:**
- Map to different ports: `"3001:3000"`, `"8081:8080"`

### Windows/macOS network_mode: host Error

**Problem:** `network_mode: host` is not supported

**Solution:**
1. Comment out `network_mode: host` in docker-compose.yml
2. Use bridge mode with port mapping
3. CAN hardware access will be limited

---

## 📋 Environment Variables

Configure the container with these variables:

```yaml
environment:
  - HTTP_PORT=3000           # HTTP server port
  - WEBSOCKET_PORT=8080      # WebSocket server port
  - CAN_INTERFACE=vcan0      # CAN interface to use
  - AUTO_OPEN_BROWSER=false  # Auto-open browser (disable in Docker)
```

---

## 🚦 Real CAN Hardware Example

### Physical CAN Interface (e.g., can0)

```bash
# On host: Set up physical CAN interface at 500 kbit/s
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0

# Start container with host network
docker-compose up -d

# Monitor real CAN traffic
docker exec -it can-train-monitor candump can0

# Server will automatically connect to can0 if you set:
# environment:
#   - CAN_INTERFACE=can0
```

---

## 🎯 Complete Example Workflow

### 1. Set Up Host CAN Interface

```bash
# Create virtual CAN (for testing)
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

### 2. Start Docker Container

```bash
cd /path/to/sample-website
docker-compose up -d
```

### 3. Verify Container Has CAN Access

```bash
# Check CAN interfaces visible to container
docker exec -it can-train-monitor ip link show | grep can

# Start monitoring
docker exec -it can-train-monitor candump vcan0 &
```

### 4. Send Test CAN Messages

```bash
# From host
cansend vcan0 100#1122334455667788

# OR from within container
docker exec -it can-train-monitor cansend vcan0 100#1122334455667788
```

### 5. Access Web Interface

Open browser to `http://localhost:3000`

---

## 📝 Summary

**For Production with Real CAN Hardware (Linux):**
- Use `network_mode: host`
- Enable `privileged: true`
- Container has full access to host's CAN interfaces and tools

**For Development/Testing:**
- Use bridge mode with port mapping
- Set up virtual CAN (vcan0)
- More isolation, easier port management

**The container includes all necessary CAN tools (candump, cansend, etc.) and can access the host's CAN interfaces when configured properly.**

---

*Last Updated: November 10, 2025*
