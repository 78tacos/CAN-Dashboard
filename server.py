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
CAN_INTERFACE = 'vcan0'  # Change to your CAN interface
AUTO_OPEN_BROWSER = True

# Store connected WebSocket clients
clients = set()

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler with CORS support for React development"""
    
    def end_headers(self):
        # Add CORS headers
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
                
                # Create CAN message
                can_msg = can.Message(
                    arbitration_id=data['id'],
                    data=data['data'],
                    is_extended_id=data.get('is_extended', False)
                )
                
                # Send to CAN bus
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
    
    # Start CAN reader task
    asyncio.create_task(can_reader(bus))
    
    # Start WebSocket server
    async with websockets.serve(websocket_handler, "localhost", WEBSOCKET_PORT):
        print(f"✓ WebSocket server running on ws://localhost:{WEBSOCKET_PORT}")
        print(f"✓ Connected to CAN interface: {CAN_INTERFACE}")
        await asyncio.Future()  # Run forever


def main():
    """Main entry point"""
    
    print("\n" + "="*60)
    print("CAN Bus Train Monitor - Python Server")
    print("="*60 + "\n")
    
    print("Starting server...")
    
    # Initialize CAN bus
    try:
        global bus
        bus = can.interface.Bus(channel=CAN_INTERFACE, interface='socketcan')
        print(f"✓ Connected to CAN interface: {CAN_INTERFACE}")
    except Exception as e:
        print(f"✗ Could not connect to CAN interface '{CAN_INTERFACE}': {e}")
        print("  Running in simulation mode (no real CAN data)")
        bus = None
    
    # Start HTTP server in background thread
    http_thread = threading.Thread(target=start_http_server, daemon=True)
    http_thread.start()
    
    # Open browser
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
    
    # Start WebSocket server (blocks)
    if bus:
        asyncio.run(start_websocket_server(bus))
    else:
        # Run without CAN if not available
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
