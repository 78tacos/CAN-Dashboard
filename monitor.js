const { useState, useEffect } = React;

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

const Navigation = ({ className, size = 24 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
         strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
        <polygon points="3 11 22 2 13 21 11 13 3 11"/>
    </svg>
);

const CANBusTrainMonitor = () => {
  const [speed, setSpeed] = useState(0);
  const [batteryLevel, setBatteryLevel] = useState(100);
  const [batteryTemp, setBatteryTemp] = useState(25);
  const [fanSpeed, setFanSpeed] = useState(0);
  const [powerConsumption, setPowerConsumption] = useState(0);
  const [voltage, setVoltage] = useState(400);
  const [current, setCurrent] = useState(0);
  const [odometer, setOdometer] = useState(0);

  const BATTERY_CAPACITY_AH = 300;
  const NOMINAL_VOLTAGE = 400;
  const MAX_VOLTAGE = 420; // full charge
  const MIN_VOLTAGE = 340; // cutoff
  const [batteryCapacityRemaining, setBatteryCapacityRemaining] = useState(BATTERY_CAPACITY_AH);
  
  const [isRunning, setIsRunning] = useState(false);
  const [targetSpeed, setTargetSpeed] = useState(0);
  const [canConnected, setCanConnected] = useState(false);
  const [wsConnection, setWsConnection] = useState(null);

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
        setTargetSpeed(speedVal); // keep the slider aligned with the bus speed
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
      case 0x500:
        const odo = parseSignal(data, 0, 32, 0.1, 0);
        setOdometer(odo);
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
      if (batteryLevel <= 0) {
        setSpeed(0);
        setTargetSpeed(0);
        setIsRunning(false);
        return;
      }

      setSpeed(prev => {
        const diff = targetSpeed - prev;
        const newSpeed = prev + Math.sign(diff) * Math.min(Math.abs(diff), 2);

        if (newSpeed > 0) {
          setOdometer(prevOdo => prevOdo + (newSpeed * (0.1 / 3600))); // 100ms in hours
        }
        
        return newSpeed;
      });

      const consumption = (speed / 120) * 150; // 120 km/h maps to 150 kW
      setPowerConsumption(consumption);

      const calc_current = (consumption * 1000) / voltage; // kW to W
      setCurrent(calc_current);

      const timeInterval = 0.1 / 3600; // 100ms in hours
      const ahConsumed = calc_current * timeInterval;
      
      setBatteryCapacityRemaining(prev => Math.max(0, prev - ahConsumed));

      const newBatteryLevel = (batteryCapacityRemaining / BATTERY_CAPACITY_AH) * 100;
      setBatteryLevel(Math.max(0, newBatteryLevel));

      const voltageRange = MAX_VOLTAGE - MIN_VOLTAGE;
      const newVoltage = MIN_VOLTAGE + (voltageRange * (newBatteryLevel / 100));
      setVoltage(newVoltage);

      // I^2R losses: current adds heat on top of the power term
      setBatteryTemp(prev => {
        const baseTemp = 25;
        const powerHeat = (consumption / 150) * 30; // up to 30°C
        const currentHeat = (calc_current / 400) * 15; // up to 15°C
        const targetTemp = baseTemp + powerHeat + currentHeat;
        return prev + (targetTemp - prev) * 0.05;
      });

      setFanSpeed(prev => {
        const targetFan = Math.max(0, Math.min(100, (batteryTemp - 30) * 2.5));
        return prev + (targetFan - prev) * 0.1;
      });

    }, 100);

    return () => clearInterval(interval);
  }, [isRunning, speed, targetSpeed, batteryTemp, voltage, batteryLevel, batteryCapacityRemaining]);

  const handleSpeedChange = (newSpeed) => {
    if (batteryLevel <= 0) {
      return;
    }
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

  useEffect(() => {
    if (typeof L === 'undefined') {
      console.log('Leaflet not loaded yet, waiting...');
      return;
    }

    const mapContainer = document.getElementById('map');
    if (!mapContainer || mapContainer._leaflet_id) {
      console.log('Map already initialized');
      return;
    }

    const startPoint = [40.2737, -76.8844]; // Harrisburg, PA
    const endPoint = [40.4406, -79.9959];   // Pittsburgh, PA

    const routePoints = [
      [40.2737, -76.8844],  // Harrisburg
      [40.3369, -77.1189],  // Marysville
      [40.3934, -77.3678],  // Duncannon
      [40.4881, -77.7208],  // Lewistown
      [40.5967, -78.0061],  // Huntingdon
      [40.4817, -78.3947],  // Altoona (Horseshoe Curve)
      [40.5187, -78.6325],  // Gallitzin
      [40.4261, -78.9206],  // Johnstown
      [40.3256, -79.1522],  // Latrobe
      [40.3431, -79.4556],  // Greensburg
      [40.4406, -79.9959]   // Pittsburgh
    ];

    const map = L.map('map', {
      zoomControl: true,
      scrollWheelZoom: true
    }).setView([40.45, -78.4], 8);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(map);

    const routeLine = L.polyline(routePoints, {
      color: '#3b82f6',
      weight: 4,
      opacity: 0.7,
      dashArray: '10, 5'
    }).addTo(map);

    const startMarker = L.marker(startPoint, {
      icon: L.divIcon({
        className: 'station-marker',
        html: '<div style="background: #10b981; width: 16px; height: 16px; border-radius: 50%; border: 3px solid white;"></div>',
        iconSize: [22, 22]
      })
    }).addTo(map)
      .bindPopup('<b>Harrisburg Station</b><br>Starting Point');

    const endMarker = L.marker(endPoint, {
      icon: L.divIcon({
        className: 'station-marker',
        html: '<div style="background: #ef4444; width: 16px; height: 16px; border-radius: 50%; border: 3px solid white;"></div>',
        iconSize: [22, 22]
      })
    }).addTo(map)
      .bindPopup('<b>Pittsburgh Station</b><br>Destination');

    const createTrainIcon = (batteryLevel) => {
      return L.divIcon({
        className: 'train-marker',
        html: `<div style="
          background: ${batteryLevel > 60 ? '#3b82f6' : batteryLevel > 30 ? '#eab308' : '#ef4444'};
          width: 24px;
          height: 24px;
          border-radius: 50%;
          border: 3px solid white;
          box-shadow: 0 0 10px rgba(0,0,0,0.5);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 14px;
        ">🚂</div>`,
        iconSize: [30, 30],
        iconAnchor: [15, 15]
      });
    };

    const trainMarker = L.marker(startPoint, { icon: createTrainIcon(100) })
      .addTo(map)
      .bindPopup('<b>Train Position</b><br>Speed: 0 km/h');

    // Point sits on the coordinate; the train icon is a larger overlay.
    const positionMarker = L.circleMarker(startPoint, {
      radius: 8,
      fillColor: '#22c55e',
      color: '#fff',
      weight: 2,
      opacity: 1,
      fillOpacity: 0.8
    }).addTo(map);

    let currentSegment = 0;
    let progress = 0;

    const animateTrain = () => {
      if (!isRunning || speed === 0) {
        return;
      }

      const progressIncrement = speed / 120000; // tuned so the marker eases along the route
      progress += progressIncrement;

      if (progress >= 1) {
        progress = 0;
        currentSegment = (currentSegment + 1) % (routePoints.length - 1);
      }

      const start = routePoints[currentSegment];
      const end = routePoints[(currentSegment + 1) % routePoints.length];
      
      const lat = start[0] + (end[0] - start[0]) * progress;
      const lng = start[1] + (end[1] - start[1]) * progress;

      trainMarker.setLatLng([lat, lng]);
      trainMarker.setIcon(createTrainIcon(batteryLevel));
      trainMarker.setPopupContent(`<b>Train Position</b><br>Speed: ${speed.toFixed(1)} km/h<br>Battery: ${batteryLevel.toFixed(1)}%`);

      positionMarker.setLatLng([lat, lng]);

      map.panTo([lat, lng], {
        animate: true,
        duration: 0.5,
        easeLinearity: 0.25
      });
    };

    const animationInterval = setInterval(animateTrain, 50);

    return () => {
      clearInterval(animationInterval);
      map.remove();
    };
  }, []); // map is created once

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
          <h1 className="text-4xl font-bold mb-2">CAN Dashboard</h1>
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
              onClick={() => {
                if (batteryLevel <= 0) {
                  alert('Battery is dead! Cannot start train.');
                  return;
                }
                setIsRunning(!isRunning);
              }}
              className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
                batteryLevel <= 0 ? 'bg-gray-600 cursor-not-allowed' :
                isRunning ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'
              }`}
              disabled={batteryLevel <= 0}
            >
              {batteryLevel <= 0 ? 'Battery Dead' : isRunning ? 'Stop Simulation' : 'Start Simulation'}
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
                disabled={batteryLevel <= 0}
              />
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
              <div className="flex items-center gap-3 mb-4">
                <Navigation className="text-green-400" size={24} />
                <h2 className="text-xl font-semibold">Odometer</h2>
              </div>
              <div className="relative">
                <div className="text-5xl font-bold text-center mb-2">{odometer.toFixed(2)}</div>
                <div className="text-center text-gray-400 text-lg">kilometers</div>
              </div>
            </div>
            
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
                  {batteryLevel <= 0 && (
                    <div className="mt-2 text-red-500 font-semibold text-sm">⚠ BATTERY DEAD</div>
                  )}
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
              <h2 className="text-xl font-semibold mb-4">Train Route - Pennsylvania Railroad</h2>
              
              <div id="map" className="w-full h-96 rounded-lg overflow-hidden border border-gray-600 relative">
              </div>

              <div className="mt-4 grid grid-cols-2 gap-4 text-sm">
                <div>
                  <div className="text-gray-400">Route</div>
                  <div className="font-semibold">Harrisburg → Pittsburgh</div>
                  <div className="text-gray-400 text-xs mt-1">Historic Pennsylvania Railroad Mainline</div>
                </div>
                <div>
                  <div className="text-gray-400">Distance</div>
                  <div className="font-semibold">~315 km (196 mi)</div>
                  <div className="text-gray-400 text-xs mt-1">Following Juniata & Conemaugh Rivers</div>
                </div>
              </div>
              
              <div className="mt-4 text-center">
                <div className={`font-semibold text-lg ${
                  batteryLevel <= 0 ? 'text-red-500' :
                  batteryLevel > 60 ? 'text-green-400' : 
                  batteryLevel > 30 ? 'text-yellow-400' : 
                  'text-red-400'
                }`}>
                  {batteryLevel <= 0 ? '💀 Dead - Need Charge!' :
                   batteryLevel > 60 ? '😊 Happy & Energized' : 
                   batteryLevel > 30 ? '😐 Doing Okay' : 
                   '😫 Tired & Low Battery'}
                </div>
                <div className="text-gray-400 text-sm mt-1">
                  {speed === 0 ? 'Stopped at Station' : speed < 30 ? 'Cruising Speed' : speed < 70 ? 'Moving Fast' : 'High Speed Express!'}
                </div>
              </div>
            </div>

            <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
              <h2 className="text-xl font-semibold mb-4">Component Status</h2>
              <div className="space-y-4">
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
                <div className="bg-gray-900 p-2 rounded">
                  <div className="text-green-400">0x500 ODOMETER</div>
                  <div className="text-gray-400">{odometer.toFixed(2)} km</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<CANBusTrainMonitor />);
