FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for CAN support
RUN apt-get update && apt-get install -y \
    iproute2 \
    can-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY server.py .
COPY train-monitor-standalone.html .
COPY demo.dbc .

# Expose ports
EXPOSE 3000 8080

# Create startup script
RUN echo '#!/bin/bash\n\
echo "======================================"\n\
echo "CAN Bus Train Monitor - Docker"\n\
echo "======================================"\n\
echo ""\n\
echo "Starting server..."\n\
echo "Web Interface: http://localhost:3000/train-monitor-standalone.html"\n\
echo "WebSocket: ws://localhost:8080"\n\
echo ""\n\
python3 server.py' > /app/start.sh && chmod +x /app/start.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["/app/start.sh"]
