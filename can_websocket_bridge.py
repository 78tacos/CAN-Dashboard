#!/usr/bin/env python3
import asyncio
import websockets
import json
import can
from datetime import datetime

bus = can.interface.Bus(channel='vcan0', interface='socketcan')

clients = set()

async def can_reader():
    """Read CAN messages and broadcast to all WebSocket clients"""
    loop = asyncio.get_event_loop()
    
    while True:
        # Read CAN message (non-blocking)
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

async def websocket_handler(websocket, path):
    """Handle WebSocket connections"""
    clients.add(websocket)
    print(f"Client connected. Total clients: {len(clients)}")
    
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
                print(f"Sent CAN message: ID=0x{data['id']:X}")
                
            except json.JSONDecodeError:
                print("Invalid JSON received")
            except Exception as e:
                print(f"Error sending CAN message: {e}")
    
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        clients.remove(websocket)
        print(f"Client disconnected. Total clients: {len(clients)}")

async def main():
    asyncio.create_task(can_reader())

    async with websockets.serve(websocket_handler, "localhost", 8080):
        print("WebSocket server started on ws://localhost:8080")
        print("Connected to CAN interface: vcan0")
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main())
