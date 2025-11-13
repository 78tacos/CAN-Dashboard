# CAN Bus Train Monitor - Docker Guide

## 🐳 Docker Deployment

The CAN Bus Train Monitor is now available as a Docker container, making it even easier to deploy across any platform!

---

## Quick Start

### Option 1: Docker Compose (Recommended)
```bash
# Start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

Then open: http://localhost:3000/train-monitor-standalone.html

### Option 2: Docker CLI
```bash
# Build the image
docker build -t can-train-monitor .

# Run the container
docker run -d \
  --name can-train-monitor \
  -p 3000:3000 \
  -p 8080:8080 \
  can-train-monitor

# View logs
docker logs -f can-train-monitor

# Stop the container
docker stop can-train-monitor
docker rm can-train-monitor
```

---

## Files Created

- **`Dockerfile`** - Container definition
- **`docker-compose.yml`** - Orchestration configuration
- **`requirements.txt`** - Python dependencies
- **`.dockerignore`** - Files to exclude from build

---

## Docker Compose Configuration

### Basic Setup (Simulation Mode)
```yaml
services:
  can-train-monitor:
    build: .
    ports:
      - "3000:3000"
      - "8080:8080"
```

### With Virtual CAN (Linux Only)
```yaml
services:
  can-train-monitor:
    build: .
    privileged: true
    network_mode: host
    
  vcan-setup:
    image: alpine:latest
    privileged: true
    network_mode: host
    command: >
      sh -c "modprobe vcan && 
             ip link add dev vcan0 type vcan && 
             ip link set up vcan0"
```

---

## Environment Variables

Configure the container using environment variables:

```yaml
environment:
  - HTTP_PORT=3000
  - WEBSOCKET_PORT=8080
  - CAN_INTERFACE=vcan0
  - AUTO_OPEN_BROWSER=false
```

Or with Docker CLI:
```bash
docker run -d \
  -e HTTP_PORT=3000 \
  -e WEBSOCKET_PORT=8080 \
  -e CAN_INTERFACE=vcan0 \
  -e AUTO_OPEN_BROWSER=false \
  -p 3000:3000 \
  -p 8080:8080 \
  can-train-monitor
```

---

## Platform-Specific Instructions

### Windows (Docker Desktop)
```powershell
# Start Docker Desktop first

# Build and run
docker-compose up -d

# Open browser to:
# http://localhost:3000/train-monitor-standalone.html

# Note: Virtual CAN not supported on Windows
# Container runs in simulation mode
```

### Linux (Docker Engine)
```bash
# Install Docker
sudo apt install docker.io docker-compose

# Build and run with virtual CAN
docker-compose up -d

# Setup virtual CAN (if needed)
docker-compose run vcan-setup

# Access at:
# http://localhost:3000/train-monitor-standalone.html
```

### macOS (Docker Desktop)
```bash
# Start Docker Desktop first

# Build and run
docker-compose up -d

# Open browser to:
# http://localhost:3000/train-monitor-standalone.html

# Note: Virtual CAN not supported on macOS
# Container runs in simulation mode
```

---

## Advanced Usage

### Custom Port Mapping
```bash
docker run -d \
  -p 8000:3000 \
  -p 9000:8080 \
  can-train-monitor
```
Access at: http://localhost:8000/train-monitor-standalone.html

### Mount Custom Configuration
```bash
docker run -d \
  -v $(pwd)/custom-server.py:/app/server.py \
  -p 3000:3000 \
  -p 8080:8080 \
  can-train-monitor
```

### Access Real CAN Interface (Linux)
```bash
docker run -d \
  --privileged \
  --network host \
  -e CAN_INTERFACE=can0 \
  can-train-monitor
```

### Development Mode (Live Reload)
```bash
docker run -d \
  -v $(pwd):/app \
  -p 3000:3000 \
  -p 8080:8080 \
  can-train-monitor
```

---

## Building and Publishing

### Build for Multiple Architectures
```bash
# Setup buildx
docker buildx create --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t yourusername/can-train-monitor:latest \
  --push .
```

### Tag and Push to Docker Hub
```bash
# Login
docker login

# Tag
docker tag can-train-monitor yourusername/can-train-monitor:latest
docker tag can-train-monitor yourusername/can-train-monitor:v1.0.0

# Push
docker push yourusername/can-train-monitor:latest
docker push yourusername/can-train-monitor:v1.0.0
```

### Pull and Run Published Image
```bash
docker pull yourusername/can-train-monitor:latest
docker run -d -p 3000:3000 -p 8080:8080 yourusername/can-train-monitor:latest
```

---

## Docker Hub Usage

Once published, users can run without building:

```bash
# Pull and run
docker run -d \
  --name can-train-monitor \
  -p 3000:3000 \
  -p 8080:8080 \
  yourusername/can-train-monitor:latest

# Or with docker-compose.yml:
services:
  can-train-monitor:
    image: yourusername/can-train-monitor:latest
    ports:
      - "3000:3000"
      - "8080:8080"
```

---

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs can-train-monitor

# Check if ports are in use
docker ps -a
netstat -tulpn | grep -E '3000|8080'

# Remove and recreate
docker-compose down
docker-compose up -d
```

### Can't Access Web Interface
```bash
# Check if container is running
docker ps

# Check port mapping
docker port can-train-monitor

# Test from inside container
docker exec -it can-train-monitor curl http://localhost:3000/train-monitor-standalone.html
```

### CAN Interface Not Working
```bash
# Check if running with privileges (Linux)
docker inspect can-train-monitor | grep Privileged

# Setup vcan manually
docker exec -it can-train-monitor bash
modprobe vcan
ip link add dev vcan0 type vcan
ip link set up vcan0
```

### Permission Denied (Linux)
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo docker-compose up -d
```

---

## Docker vs Native Installation

### Use Docker When:
✅ Need consistent environment across platforms  
✅ Want easy deployment and cleanup  
✅ Running on servers or cloud  
✅ Need isolation from host system  
✅ Deploying to multiple machines

### Use Native When:
✅ Need direct access to CAN hardware  
✅ Developing/debugging the application  
✅ Want minimal overhead  
✅ Need host network features  
✅ Running on resource-constrained devices

---

## Docker Image Details

**Base Image:** python:3.11-slim  
**Size:** ~150 MB  
**Included:**
- Python 3.11
- python-can
- websockets
- iproute2 (for CAN)
- can-utils (for CAN)

**Ports:**
- 3000: HTTP Server
- 8080: WebSocket Server

**Volumes:**
- `/app/logs`: Optional log directory

---

## Production Deployment

### Docker Swarm
```bash
docker swarm init
docker stack deploy -c docker-compose.yml can-monitor
```

### Kubernetes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: can-train-monitor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: can-train-monitor
  template:
    metadata:
      labels:
        app: can-train-monitor
    spec:
      containers:
      - name: can-train-monitor
        image: yourusername/can-train-monitor:latest
        ports:
        - containerPort: 3000
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: can-train-monitor
spec:
  selector:
    app: can-train-monitor
  ports:
  - name: http
    port: 3000
    targetPort: 3000
  - name: websocket
    port: 8080
    targetPort: 8080
  type: LoadBalancer
```

---

## Health Checks

The container includes a health check:
```bash
# Check health status
docker inspect can-train-monitor | grep Health -A 10

# Manual health check
curl http://localhost:3000/train-monitor-standalone.html
```

---

## Multi-Container Setup

Run multiple instances on different ports:
```yaml
services:
  monitor-1:
    build: .
    ports:
      - "3001:3000"
      - "8081:8080"
  
  monitor-2:
    build: .
    ports:
      - "3002:3000"
      - "8082:8080"
```

---

## Security Considerations

### Production Best Practices:
1. Don't run as privileged unless needed
2. Use specific version tags, not `latest`
3. Scan for vulnerabilities:
   ```bash
   docker scan can-train-monitor
   ```
4. Use read-only filesystem where possible
5. Limit resources:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

---

## Benefits of Docker Deployment

✅ **Consistent Environment** - Same behavior everywhere  
✅ **Easy Distribution** - Single `docker pull` command  
✅ **Isolation** - Doesn't affect host system  
✅ **Version Control** - Tag and track versions  
✅ **Scalability** - Run multiple instances easily  
✅ **Cloud Ready** - Deploy to AWS, Azure, GCP  
✅ **CI/CD Integration** - Automate builds and deployments  

---

## Quick Commands Reference

```bash
# Build
docker build -t can-train-monitor .

# Run
docker run -d -p 3000:3000 -p 8080:8080 can-train-monitor

# Stop
docker stop can-train-monitor

# Start
docker start can-train-monitor

# Logs
docker logs -f can-train-monitor

# Shell access
docker exec -it can-train-monitor bash

# Remove
docker rm can-train-monitor

# Remove image
docker rmi can-train-monitor

# Clean up
docker system prune -a
```

---

*Docker support added: November 10, 2025*
*Container ready for production deployment!*
