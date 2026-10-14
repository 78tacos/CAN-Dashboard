# CAN Dashboard

Web dashboard for CAN data from an electric train. `index.html` loads `monitor.js`, which shows speed, battery, voltage, current, temperature, fan speed, power, and odometer, and a map of a Harrisburg–Pittsburgh route. The page can simulate those values in the browser. With the WebSocket up, it also applies frames from the bus.

## Run locally

Python 3, then:

```bash
pip install -r requirements.txt
python3 server.py
```

`server.py` serves this directory on port 3000 and a WebSocket on `localhost:8080`. It opens http://localhost:3000, which is `index.html`.

On Linux, `server.py` opens the SocketCAN channel `vcan0`:

```bash
sudo ./setup_vcan.sh
```

If `vcan0` is missing, HTTP and the WebSocket still start. The in-page simulation does not need the bus.

`./start-monitor.sh` picks `python3` or `python`, installs `python-can` and `websockets` when they are missing, and runs `server.py`.

`install-portable.sh` (Linux/macOS) and `install-portable.ps1` / `install-portable.bat` (Windows) install a copy under `~/CANTrainMonitor` or `%USERPROFILE%\CANTrainMonitor`.

## Docker

```bash
docker compose up --build
```

`docker-compose.yml` uses `network_mode: host` so the container can use the host's SocketCAN interfaces. The WebSocket binds to `localhost`, which is the host in that mode. The image includes `server.py` and `train-monitor-standalone.html` (the same UI, script inlined). Open http://localhost:3000/train-monitor-standalone.html.

Compose also starts `vcan-setup`, which loads the `vcan` module and brings up `vcan0` on a Linux host. Both services run privileged.

## CAN IDs

`demo.dbc` and `monitor.js` use:

| ID | Name | Layout |
| --- | --- | --- |
| 0x100 | SPEED | 16 bits at bit 0, factor 0.1, km/h |
| 0x200 | BATTERY | level: 8 bits at 0, %; voltage: 16 bits at 8, factor 0.1, V |
| 0x300 | THERMAL | temperature: 16 bits at 0, factor 0.1, offset -40, °C; fan: 8 bits at 16, % |
| 0x400 | POWER | consumption: 16 bits at 0, factor 0.1, kW; current: 16 bits at 16, factor 0.1, A |
| 0x500 | ODOMETER | 32 bits at 0, factor 0.1, km |

`can_websocket_bridge.py` is the WebSocket bridge only. It listens on `localhost:8080` and opens `vcan0` at import, so it exits when that interface is absent.

`can_monitor_server.sh` is Python. It overwrites `index.html`, then serves the page the same way `server.py` does.
