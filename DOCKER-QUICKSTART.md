# Docker Quick Start - CAN Bus Train Monitor

## 🚀 Fastest Way to Run

### Using Docker Compose (Easiest)
```bash
docker-compose up -d
```
Open: http://localhost:3000/train-monitor-standalone.html

### Using Helper Scripts

**Windows:**
```cmd
docker-setup.bat
# Select option 3 (Build and run)
```

**Linux/Mac:**
```bash
chmod +x docker-setup.sh
./docker-setup.sh
# Select option 3 (Build and run)
```

### Manual Docker Commands
```bash
# Build
docker build -t can-train-monitor .

# Run
docker run -d -p 3000:3000 -p 8080:8080 can-train-monitor

# Access
http://localhost:3000/train-monitor-standalone.html
```

---

## 📋 Common Commands

```bash
# View running containers
docker ps

# View logs
docker logs -f can-train-monitor

# Stop
docker stop can-train-monitor

# Start
docker start can-train-monitor

# Restart
docker restart can-train-monitor

# Remove container
docker rm can-train-monitor

# Remove image
docker rmi can-train-monitor

# Shell access
docker exec -it can-train-monitor bash
```

---

## 🔧 Docker Compose Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Rebuild and restart
docker-compose up -d --build
```

---

## 🌐 Access URLs

- **Web Interface:** http://localhost:3000/train-monitor-standalone.html
- **HTTP Server:** http://localhost:3000
- **WebSocket:** ws://localhost:8080

---

## ⚙️ Configuration

### Change Ports
```bash
docker run -d \
  -p 8000:3000 \
  -p 9000:8080 \
  can-train-monitor
```

### Set Environment Variables
```bash
docker run -d \
  -e CAN_INTERFACE=can0 \
  -p 3000:3000 \
  -p 8080:8080 \
  can-train-monitor
```

---

## 🐛 Troubleshooting

**Container won't start:**
```bash
docker logs can-train-monitor
```

**Port already in use:**
```bash
# Check what's using the port
docker ps
netstat -tulpn | grep 3000

# Use different ports
docker run -d -p 3001:3000 -p 8081:8080 can-train-monitor
```

**Need to rebuild:**
```bash
docker-compose down
docker-compose up -d --build
```

---

## 📦 Distribution

### Save image to file
```bash
docker save can-train-monitor > can-train-monitor.tar
```

### Load image from file
```bash
docker load < can-train-monitor.tar
```

### Push to Docker Hub
```bash
docker tag can-train-monitor username/can-train-monitor:latest
docker push username/can-train-monitor:latest
```

---

## ✅ Complete Workflow

```bash
# 1. Build the image
docker build -t can-train-monitor .

# 2. Run the container
docker run -d \
  --name can-train-monitor \
  -p 3000:3000 \
  -p 8080:8080 \
  can-train-monitor

# 3. Open browser
# http://localhost:3000/train-monitor-standalone.html

# 4. View logs if needed
docker logs -f can-train-monitor

# 5. Stop when done
docker stop can-train-monitor
docker rm can-train-monitor
```

---

## 🎯 One-Line Commands

### Quick test (auto-remove after stop)
```bash
docker run --rm -p 3000:3000 -p 8080:8080 can-train-monitor
```

### Run with custom name
```bash
docker run -d --name my-monitor -p 3000:3000 -p 8080:8080 can-train-monitor
```

### Run multiple instances
```bash
docker run -d --name monitor1 -p 3001:3000 -p 8081:8080 can-train-monitor
docker run -d --name monitor2 -p 3002:3000 -p 8082:8080 can-train-monitor
```

---

For detailed information, see **DOCKER-GUIDE.md**
