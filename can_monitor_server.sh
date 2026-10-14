#!/usr/bin/env python3
"""
Complete Python launcher for CAN Bus Train Monitor
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

HTTP_PORT = 3000
WEBSOCKET_PORT = 8080
CAN_INTERFACE = 'vcan0'  # Change to your CAN interface
AUTO_OPEN_BROWSER = True

clients = set()

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler with CORS support for React development"""
    
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
        # Suppress excessive logging
        pass


def create_html_file():
    """Create standalone HTML file with embedded React component"""
    
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CAN Bus Train Monitor</title>
    <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body>
    <div id="root"></div>
    
    <script type="text/babel">
        const { useState, useEffect } = React;
        
        // Lucide icons as inline SVG components
        const Battery = ({ className, size = 24 }) => (
            <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" 
                 strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
                <rect x="2" y="7" width="16" height="10" rx="2" ry="2"/>
                <line x1="22" y1="11" x2="22" y2="13"/>
            </svg>
        );
        
        const Thermometer = ({ className, size = 24 }) => (
            <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
                <path d="M14 4v10.54a4 4 0 1 1-4 0V4a2 2 0 0 1 4 0Z"/>
            </svg>
        );
        
        const Wind = ({ className, size = 24 }) => (
            <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
                <path d="M9.59 4.59A2 2 0 1 1 11 8H2m10.59 11.41A2 2 0 1 0 14 16H2m15.73-8.27A2.5 2.5 0 1 1 19.5 12H2"/>
            </svg>
        );
        
        const Zap = ({ className, size = 24 }) => (
            <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
                <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
            </svg>
        );
        
        const Gauge = ({ className, size = 24 }) => (
            <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
                <path d="m12 14 4-4"/>
                <path d="M3.34 19a10 10 0 1 1 17.32 0"/>
            </svg>
        );
        
        const Train = ({ className, size = 24 }) => (
            <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
                <rect x="4" y="4" width="16" height="16" rx="2"/>
                <path d="M4 11h16"/>
                <path d="M12 4v7"/>
                <circle cx="8" cy="18" r="2"/>
                <circle cx="16" cy="18" r="2"/>
            </svg>
        );

        // Paste your complete CAN Bus Train Monitor component here
        // (The React component code from the artifact)
        const CANBusTrainMonitor = () => {
          // State for train parameters
          const [speed, setSpeed] = useState(0);
          const [batteryLevel, setBatteryLevel] = useState(100);
          const [batteryTemp, setBatteryTemp] = useState(25);
          const [fanSpeed, setFanSpeed] = useState(0);
          const [powerConsumption, setPowerConsumption] = useState(0);
          const [voltage, setVoltage] = useState(400);
          const [current, setCurrent] = useState(0);
          
          const [isRunning, setIsRunning] = useState(false);
          const [targetSpeed, setTargetSpeed] = useState(0);
          const [canConnected, setCanConnected] = useState(false);
          const [wsConnection, setWsConnection] = useState(null);

          // WebSocket connection for CAN interface
          useEffect(() => {
            const connectToCAN = () => {
              try {
                const ws = new WebSocket('ws://localhost:8080');
                
                ws.onopen = () => {
                  console.log('Connected to CAN interface');
                  setCanConnected(true);
                  setWsConnection(ws);
                };
                
                ws.onmessage = (event) => {
                  try {
                    const canMessage = JSON.parse(event.data);
                    parseCANMessage(canMessage);
                  } catch (e) {
                    console.error('Error parsing CAN message:', e);
                  }
                };
                
                ws.onerror = (error) => {
                  console.error('WebSocket error:', error);
                  setCanConnected(false);
                };
                
                ws.onclose = () => {
                  console.log('Disconnected from CAN interface');
                  setCanConnected(false);
                  setWsConnection(null);
                };
                
              } catch (error) {
                console.error('Failed to connect to CAN:', error);
              }
            };

            connectToCAN();

            return () => {
              if (wsConnection) {
                wsConnection.close();
              }
            };
          }, []);

          const parseCANMessage = (canMsg) => {
            const { id, data } = canMsg;
            
            switch(id) {
              case 0x100:
                const speedVal = parseSignal(data, 0, 16, 0.1, 0);
                setSpeed(speedVal);
                setTargetSpeed(speedVal); // Sync slider with incoming speed
                break;
              case 0x200:
                const level = parseSignal(data, 0, 8, 1, 0);
                const volt = parseSignal(data, 8, 16, 0.1, 0);
                setBatteryLevel(level);
                setVoltage(volt);
                break;
              case 0x300:
                const temp = parseSignal(data, 0, 16, 0.1, -40);
                const fan = parseSignal(data, 16, 8, 1, 0);
                setBatteryTemp(temp);
                setFanSpeed(fan);
                break;
              case 0x400:
                const power = parseSignal(data, 0, 16, 0.1, 0);
                const curr = parseSignal(data, 16, 16, 0.1, 0);
                setPowerConsumption(power);
                setCurrent(curr);
                break;
            }
          };

          const parseSignal = (data, startBit, length, factor, offset) => {
            const byteIndex = Math.floor(startBit / 8);
            const bitOffset = startBit % 8;
            let value = 0;
            
            const bytesNeeded = Math.ceil((bitOffset + length) / 8);
            for (let i = 0; i < bytesNeeded && (byteIndex + i) < data.length; i++) {
              value |= (data[byteIndex + i] << (i * 8));
            }
            
            const mask = (1 << length) - 1;
            value = (value >> bitOffset) & mask;
            
            return (value * factor) + offset;
          };

          useEffect(() => {
            if (!isRunning) return;

            const interval = setInterval(() => {
              setSpeed(prev => {
                const diff = targetSpeed - prev;
                return prev + Math.sign(diff) * Math.min(Math.abs(diff), 2);
              });

              const consumption = (speed / 100) * 150;
              setPowerConsumption(consumption);

              const calc_current = consumption / (voltage / 1000);
              setCurrent(calc_current);

              setBatteryLevel(prev => Math.max(0, prev - consumption * 0.001));

              setBatteryTemp(prev => {
                const targetTemp = 25 + (consumption / 150) * 45;
                return prev + (targetTemp - prev) * 0.05;
              });

              setFanSpeed(prev => {
                const targetFan = Math.max(0, Math.min(100, (batteryTemp - 30) * 2.5));
                return prev + (targetFan - prev) * 0.1;
              });

              setVoltage(400 - (consumption / 150) * 20);

            }, 100);

            return () => clearInterval(interval);
          }, [isRunning, speed, targetSpeed, batteryTemp, voltage]);

          const handleSpeedChange = (newSpeed) => {
            setTargetSpeed(newSpeed);
          };

          const getBatteryColor = () => {
            if (batteryLevel > 60) return 'text-green-500';
            if (batteryLevel > 30) return 'text-yellow-500';
            return 'text-red-500';
          };

          const getTempColor = () => {
            if (batteryTemp < 40) return 'text-blue-500';
            if (batteryTemp < 55) return 'text-yellow-500';
            return 'text-red-500';
          };

          return (
            <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-6">
              <style>{`
                @keyframes spin {
                  from { transform: rotate(0deg); }
                  to { transform: rotate(360deg); }
                }
                @keyframes speedLine {
                  from { transform: translateX(0); }
                  to { transform: translateX(-200%); }
                }
                @keyframes moveTrain {
                  0% { transform: translateX(-100%); }
                  100% { transform: translateX(100vw); }
                }
                .train-moving {
                  animation: moveTrain linear infinite;
                }
              `}</style>
              
              <div className="max-w-7xl mx-auto">
                <div className="text-center mb-8">
                  <h1 className="text-4xl font-bold mb-2">Electric Train CAN Bus Monitor</h1>
                  <p className="text-gray-400">Real-time vehicle diagnostics and control</p>
                </div>

                <div className="bg-gray-800 rounded-lg p-6 mb-6 border border-gray-700">
                  <div className="flex items-center gap-6 flex-wrap">
                    <div className={`px-4 py-2 rounded-lg font-semibold ${
                      canConnected ? 'bg-green-600' : 'bg-gray-600'
                    }`}>
                      {canConnected ? '● CAN Connected' : '○ CAN Disconnected'}
                    </div>
                    
                    <button
                      onClick={() => setIsRunning(!isRunning)}
                      className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
                        isRunning ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'
                      }`}
                    >
                      {isRunning ? 'Stop Simulation' : 'Start Simulation'}
                    </button>
                    
                    <div className="flex-1">
                      <label className="block text-sm text-gray-400 mb-2">Target Speed: {targetSpeed} km/h</label>
                      <input
                        type="range"
                        min="0"
                        max="120"
                        value={targetSpeed}
                        onChange={(e) => handleSpeedChange(Number(e.target.value))}
                        className="w-full"
                      />
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  <div className="lg:col-span-2 space-y-6">
                    {/* Moving Train Animation */}
                    {speed > 0 && (
                      <div className="bg-gray-800 rounded-lg p-4 border border-gray-700 overflow-hidden relative h-24">
                        <div className="absolute bottom-4 train-moving" 
                             style={{
                               animationDuration: `${Math.max(2, 20 - (speed / 120) * 18)}s`
                             }}>
                          <Train className="text-blue-400" size={48} />
                        </div>
                        <div className="absolute bottom-2 left-0 right-0 h-1 bg-gray-600"></div>
                      </div>
                    )}
                    
                    <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                      <div className="flex items-center gap-3 mb-4">
                        <Gauge className="text-blue-400" size={24} />
                        <h2 className="text-xl font-semibold">Speed</h2>
                      </div>
                      <div className="relative">
                        <div className="text-6xl font-bold text-center mb-2">{speed.toFixed(1)}</div>
                        <div className="text-center text-gray-400 text-lg">km/h</div>
                        <div className="mt-4 bg-gray-700 rounded-full h-4 overflow-hidden">
                          <div 
                            className="bg-blue-500 h-full transition-all duration-300"
                            style={{ width: `${(speed / 120) * 100}%` }}
                          />
                        </div>
                      </div>
                    </div>

                    <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                      <div className="flex items-center gap-3 mb-4">
                        <Battery className={getBatteryColor()} size={24} />
                        <h2 className="text-xl font-semibold">Battery Status</h2>
                      </div>
                      <div className="grid grid-cols-2 gap-6">
                        <div>
                          <div className={`text-5xl font-bold ${getBatteryColor()}`}>{batteryLevel.toFixed(1)}%</div>
                          <div className="text-gray-400 mt-2">Charge Level</div>
                          <div className="mt-3 bg-gray-700 rounded-full h-6 overflow-hidden border-2 border-gray-600">
                            <div 
                              className={`h-full transition-all duration-300 ${
                                batteryLevel > 60 ? 'bg-green-500' : batteryLevel > 30 ? 'bg-yellow-500' : 'bg-red-500'
                              }`}
                              style={{ width: `${batteryLevel}%` }}
                            />
                          </div>
                        </div>
                        <div>
                          <div className="text-3xl font-bold">{voltage.toFixed(1)} V</div>
                          <div className="text-gray-400 mt-2">Voltage</div>
                          <div className="text-3xl font-bold mt-4">{current.toFixed(1)} A</div>
                          <div className="text-gray-400 mt-2">Current</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-6">
                    <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                      <h2 className="text-xl font-semibold mb-4">Train Status</h2>
                      <div className="text-center py-4">
                        <div className={`text-4xl mb-2`}>
                          {batteryLevel > 60 ? '😊' : batteryLevel > 30 ? '😐' : '😫'}
                        </div>
                        <div className={`font-semibold ${
                          batteryLevel > 60 ? 'text-green-400' : 
                          batteryLevel > 30 ? 'text-yellow-400' : 
                          'text-red-400'
                        }`}>
                          {batteryLevel > 60 ? 'Happy & Energized' : 
                           batteryLevel > 30 ? 'Doing Okay' : 
                           'Tired & Low Battery'}
                        </div>
                        <div className="text-gray-400 text-sm mt-1">
                          {speed === 0 ? 'Stopped' : speed < 30 ? 'Cruising' : speed < 70 ? 'Moving Fast' : 'High Speed!'}
                        </div>
                      </div>
                    </div>

                    {/* Component Status Bars */}
                    <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                      <h2 className="text-xl font-semibold mb-4">Component Status</h2>
                      <div className="space-y-4">
                        {/* Battery Temperature */}
                        <div>
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center gap-2">
                              <Thermometer className={getTempColor()} size={20} />
                              <span className="text-sm">Temperature</span>
                            </div>
                            <span className={`text-sm font-semibold ${getTempColor()}`}>
                              {batteryTemp.toFixed(1)}°C
                            </span>
                          </div>
                          <div className="bg-gray-700 rounded-full h-2 overflow-hidden">
                            <div 
                              className={`h-full transition-all duration-300 ${
                                batteryTemp < 40 ? 'bg-blue-500' : 
                                batteryTemp < 55 ? 'bg-yellow-500' : 
                                'bg-red-500'
                              }`}
                              style={{ width: `${Math.min(100, (batteryTemp / 70) * 100)}%` }}
                            />
                          </div>
                        </div>

                        {/* Fan Speed */}
                        <div>
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center gap-2">
                              <Wind className="text-cyan-400" size={20} />
                              <span className="text-sm">Fan Speed</span>
                            </div>
                            <span className="text-sm font-semibold text-cyan-400">
                              {fanSpeed.toFixed(0)}%
                            </span>
                          </div>
                          <div className="bg-gray-700 rounded-full h-2 overflow-hidden">
                            <div 
                              className="bg-cyan-500 h-full transition-all duration-300"
                              style={{ width: `${fanSpeed}%` }}
                            />
                          </div>
                        </div>

                        {/* Power Consumption */}
                        <div>
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center gap-2">
                              <Zap className="text-yellow-400" size={20} />
                              <span className="text-sm">Power</span>
                            </div>
                            <span className="text-sm font-semibold text-yellow-400">
                              {powerConsumption.toFixed(1)}kW
                            </span>
                          </div>
                          <div className="bg-gray-700 rounded-full h-2 overflow-hidden">
                            <div 
                              className="bg-yellow-500 h-full transition-all duration-300"
                              style={{ width: `${(powerConsumption / 150) * 100}%` }}
                            />
                          </div>
                        </div>

                        {/* Current */}
                        <div>
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center gap-2">
                              <Zap className="text-purple-400" size={20} />
                              <span className="text-sm">Current</span>
                            </div>
                            <span className="text-sm font-semibold text-purple-400">
                              {current.toFixed(1)}A
                            </span>
                          </div>
                          <div className="bg-gray-700 rounded-full h-2 overflow-hidden">
                            <div 
                              className="bg-purple-500 h-full transition-all duration-300"
                              style={{ width: `${Math.min(100, (current / 500) * 100)}%` }}
                            />
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                      <h2 className="text-xl font-semibold mb-4">CAN Messages</h2>
                      <div className="space-y-2 text-xs font-mono">
                        <div className="bg-gray-900 p-2 rounded">
                          <div className="text-blue-400">0x100 SPEED</div>
                          <div className="text-gray-400">{speed.toFixed(1)} km/h</div>
                        </div>
                        <div className="bg-gray-900 p-2 rounded">
                          <div className="text-green-400">0x200 BATTERY</div>
                          <div className="text-gray-400">{batteryLevel.toFixed(1)}%</div>
                        </div>
                        <div className="bg-gray-900 p-2 rounded">
                          <div className="text-yellow-400">0x300 THERMAL</div>
                          <div className="text-gray-400">{batteryTemp.toFixed(1)}°C</div>
                        </div>
                        <div className="bg-gray-900 p-2 rounded">
                          <div className="text-purple-400">0x400 POWER</div>
                          <div className="text-gray-400">{powerConsumption.toFixed(1)}kW</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          );
        };
        
        // Render the app
        const root = ReactDOM.createRoot(document.getElementById('root'));
        root.render(<CANBusTrainMonitor />);
    </script>
</body>
</html>"""
    
    with open('index.html', 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"✓ Created index.html")


async def can_reader(bus):
    """Read CAN messages and broadcast to all WebSocket clients"""
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
            print(f"Error reading CAN: {e}")
            await asyncio.sleep(0.1)


async def websocket_handler(websocket):
    """Handle WebSocket connections"""
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
                print(f"→ Sent CAN: ID=0x{data['id']:X}")
                
            except json.JSONDecodeError:
                print("✗ Invalid JSON received")
            except Exception as e:
                print(f"✗ Error sending CAN: {e}")
    
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        clients.remove(websocket)
        print(f"✗ WebSocket client disconnected (Total: {len(clients)})")


def start_http_server():
    """Start HTTP server in a separate thread"""
    handler = CORSHTTPRequestHandler
    
    with socketserver.TCPServer(("", HTTP_PORT), handler) as httpd:
        print(f"✓ HTTP Server running on http://localhost:{HTTP_PORT}")
        httpd.serve_forever()


async def start_websocket_server(bus):
    """Start WebSocket server for CAN communication"""
    
    asyncio.create_task(can_reader(bus))

    async with websockets.serve(websocket_handler, "localhost", WEBSOCKET_PORT):
        print(f"✓ WebSocket server running on ws://localhost:{WEBSOCKET_PORT}")
        print(f"✓ Connected to CAN interface: {CAN_INTERFACE}")
        await asyncio.Future()  # Run forever


def main():
    """Main entry point"""
    
    print("\n" + "="*60)
    print("CAN Bus Train Monitor - Python Launcher")
    print("="*60 + "\n")
    
    print("Setting up application...")
    create_html_file()

    try:
        global bus
        bus = can.interface.Bus(channel=CAN_INTERFACE, bustype='socketcan')
        print(f"✓ Connected to CAN interface: {CAN_INTERFACE}")
    except Exception as e:
        print(f"✗ Could not connect to CAN interface '{CAN_INTERFACE}': {e}")
        print("  Running in simulation mode (no real CAN data)")
        bus = None
    
    http_thread = threading.Thread(target=start_http_server, daemon=True)
    http_thread.start()
    
    if AUTO_OPEN_BROWSER:
        import time
        time.sleep(1)  # Wait for server to start
        webbrowser.open(f'http://localhost:{HTTP_PORT}')
        print(f"\n✓ Opened browser at http://localhost:{HTTP_PORT}")
    
    print("\n" + "-"*60)
    print("Server is running!")
    print(f"  → Web Interface: http://localhost:{HTTP_PORT}")
    print(f"  → WebSocket: ws://localhost:{WEBSOCKET_PORT}")
    print("  → Press Ctrl+C to stop")
    print("-"*60 + "\n")
    
    # Blocks on the WebSocket server.
    if bus:
        asyncio.run(start_websocket_server(bus))
    else:
        # No SocketCAN interface; still serve the page and WebSocket.
        async def dummy_server():
            async with websockets.serve(websocket_handler, "localhost", WEBSOCKET_PORT):
                print("Running in simulation mode...")
                await asyncio.Future()
        
        asyncio.run(dummy_server())


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n✓ Server stopped by user")
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
