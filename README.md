# CAN Dashboard

A real-time web-based monitoring dashboard for CAN bus data from an electric train system.

## Project Structure

```
sample-website/
├── server.py           # Python backend server (HTTP + WebSocket + CAN interface)
├── index.html          # HTML page structure
├── monitor.js          # React frontend application
├── can_websocket_bridge.py  # Original CAN bridge (deprecated, use server.py)
└── can_monitor_server.sh    # Original all-in-one file (deprecated, use separate files)
```

## Features

- **Real-time CAN Bus Communication**: Connects to SocketCAN interface (vcan0)
- **WebSocket Bridge**: Streams CAN messages to the web frontend
- **Battery Management**: 
  - Automatically stops train when battery is dead (0%)
  - Prevents speed changes when battery is depleted
- **Odometer**: Tracks total distance traveled in kilometers
- **Live Monitoring**:
  - Speed (km/h)
  - Battery level, voltage, current
  - Temperature and cooling fan status
  - Power consumption
- **Animated Train**: Visual train animation that moves across screen based on speed
- **Component Status Bars**: Visual progress bars for all monitored components

## Setup

### Prerequisites

```bash
# Install Python dependencies
pip install python-can websockets

# Setup virtual CAN interface (Linux only)
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

### Running the Application

```bash
# Start the server (serves HTML and handles WebSocket/CAN)
python3 server.py
```

The application will:
1. Start HTTP server on port 3000
2. Start WebSocket server on port 8080
3. Connect to CAN interface (vcan0)
4. Automatically open browser to http://localhost:3000

## CAN Message IDs

| ID    | Name      | Data                                    |
|-------|-----------|----------------------------------------|
| 0x100 | SPEED     | Speed (km/h)                           |
| 0x200 | BATTERY   | Battery level (%), Voltage (V)         |
| 0x300 | THERMAL   | Temperature (°C), Fan speed (%)        |
| 0x400 | POWER     | Power consumption (kW), Current (A)    |
| 0x500 | ODOMETER  | Total distance traveled (km)           |

## Development

### File Descriptions

- **server.py**: Python backend that:
  - Serves static HTML files via HTTP
  - Bridges CAN bus to WebSocket
  - Handles bidirectional CAN message translation

- **index.html**: Simple HTML structure that:
  - Loads React and Tailwind CSS from CDN
  - Creates root div for React app
  - Includes the monitor.js script

- **monitor.js**: React application that:
  - Connects to WebSocket server
  - Parses CAN messages
  - Renders real-time dashboard with animations
  - Simulates train behavior when running locally

## Battery Dead Protection

When battery level reaches 0%:
- Speed is immediately set to 0
- Target speed is reset to 0
- Simulation automatically stops
- Speed slider is disabled
- Start button is disabled with "Battery Dead" message
- Train emoji changes to 💀
- Warning message "Dead - Need Charge!" is displayed

## Odometer Calculation

The odometer calculates distance traveled using:
```
distance += speed (km/h) × time_interval (hours)
```
Updates every 100ms based on current speed.

## Notes

- The old `can_monitor_server.sh` file was an all-in-one file that's now split into separate files for better maintainability
- If CAN interface is not available, the server runs in simulation mode (WebSocket only)
- The frontend will work in simulation mode without real CAN data
