FROM python:3.11-slim

WORKDIR /app

# SocketCAN tools, so an interface can be brought up in the container
RUN apt-get update && apt-get install -y \
    iproute2 \
    can-utils \
    && rm -rf /var/lib/apt/lists/*

# Dependencies before the app so this layer stays cached
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .
COPY train-monitor-standalone.html .
COPY demo.dbc .

EXPOSE 3000 8080

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

ENV PYTHONUNBUFFERED=1

CMD ["/app/start.sh"]
