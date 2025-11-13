#!/bin/bash
# Script to setup virtual CAN interface (vcan0)

# Load the vcan kernel module
sudo modprobe vcan

# Create vcan0 interface
sudo ip link add dev vcan0 type vcan

# Bring up the interface
sudo ip link set up vcan0

echo "vcan0 interface created and activated"
echo "You can verify with: ip link show vcan0"
