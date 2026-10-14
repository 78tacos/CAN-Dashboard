import React, { useState, useEffect } from 'react';
import { Battery, Thermometer, Wind, Zap, Gauge } from 'lucide-react';

const CANBusTrainMonitor = () => {
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

  const dbcMessages = {
    SPEED: { id: 0x100, signals: { speed: { start: 0, length: 16, factor: 0.1, unit: 'km/h' } } },
    BATTERY: { id: 0x200, signals: { 
      level: { start: 0, length: 8, factor: 1, unit: '%' },
      voltage: { start: 8, length: 16, factor: 0.1, unit: 'V' }
    }},
    THERMAL: { id: 0x300, signals: { 
      temperature: { start: 0, length: 16, factor: 0.1, offset: -40, unit: '°C' },
      fanSpeed: { start: 16, length: 8, factor: 1, unit: '%' }
    }},
    POWER: { id: 0x400, signals: { 
      consumption: { start: 0, length: 16, factor: 0.1, unit: 'kW' },
      current: { start: 16, length: 16, factor: 0.1, unit: 'A' }
    }}
  };

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

    return () => {
      if (wsConnection) {
        wsConnection.close();
      }
    };
  }, []);

  const parseCANMessage = (canMsg) => {
    const { id, data } = canMsg;
    
    switch(id) {
      case 0x100: // SPEED
        const speedVal = parseSignal(data, 0, 16, 0.1, 0);
        setSpeed(speedVal);
        break;
      case 0x200: // BATTERY
        const level = parseSignal(data, 0, 8, 1, 0);
        const volt = parseSignal(data, 8, 16, 0.1, 0);
        setBatteryLevel(level);
        setVoltage(volt);
        break;
      case 0x300: // THERMAL
        const temp = parseSignal(data, 0, 16, 0.1, -40);
        const fan = parseSignal(data, 16, 8, 1, 0);
        setBatteryTemp(temp);
        setFanSpeed(fan);
        break;
      case 0x400: // POWER
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
    
    // Little-endian; bits that cross a byte boundary are not fully handled.
    const bytesNeeded = Math.ceil((bitOffset + length) / 8);
    for (let i = 0; i < bytesNeeded && (byteIndex + i) < data.length; i++) {
      value |= (data[byteIndex + i] << (i * 8));
    }
    
    const mask = (1 << length) - 1;
    value = (value >> bitOffset) & mask;
    
    return (value * factor) + offset;
  };

  const encodeSignal = (value, startBit, length, factor, offset) => {
    const rawValue = Math.round((value - offset) / factor);
    const byteIndex = Math.floor(startBit / 8);
    const bitOffset = startBit % 8;
    const data = new Array(8).fill(0);
    
    // Same little-endian simplification as parseSignal.
    const mask = (1 << length) - 1;
    const maskedValue = rawValue & mask;
    
    for (let i = 0; i < 8; i++) {
      if (byteIndex + Math.floor((bitOffset + i * 8) / 8) < 8) {
        data[byteIndex + Math.floor(i / 8)] |= 
          ((maskedValue >> i) & 0xFF) << (bitOffset);
      }
    }
    
    return data;
  };

  useEffect(() => {
    if (!isRunning) return;

    const interval = setInterval(() => {
      setSpeed(prev => {
        const diff = targetSpeed - prev;
        return prev + Math.sign(diff) * Math.min(Math.abs(diff), 2);
      });

      const consumption = (speed / 100) * 150; // Max 150 kW
      setPowerConsumption(consumption);

      const calc_current = consumption / (voltage / 1000);
      setCurrent(calc_current);

      setBatteryLevel(prev => Math.max(0, prev - consumption * 0.001));

      setBatteryTemp(prev => {
        const targetTemp = 25 + (consumption / 150) * 45; // Max 70°C
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

  const sendCANMessage = (messageType, data) => {
    console.log(`CAN TX: ${messageType}`, data);
    
    if (wsConnection && canConnected) {
      let canId, canData;
      
      switch(messageType) {
        case 'SPEED':
          canId = 0x100;
          canData = encodeSignal(data.speed, 0, 16, 0.1, 0);
          break;
      }
      
      if (canId && canData) {
        wsConnection.send(JSON.stringify({
          id: canId,
          data: canData,
          timestamp: Date.now()
        }));
      }
    }
  };

  const handleSpeedChange = (newSpeed) => {
    setTargetSpeed(newSpeed);
    sendCANMessage('SPEED', { speed: newSpeed });
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

            <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
              <div className="flex items-center gap-3 mb-4">
                <Thermometer className={getTempColor()} size={24} />
                <h2 className="text-xl font-semibold">Thermal Management</h2>
              </div>
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <div className={`text-5xl font-bold ${getTempColor()}`}>{batteryTemp.toFixed(1)}°C</div>
                  <div className="text-gray-400 mt-2">Battery Temperature</div>
                  <div className="mt-3 bg-gray-700 rounded-full h-4 overflow-hidden">
                    <div 
                      className={`h-full transition-all duration-300 ${
                        batteryTemp < 40 ? 'bg-blue-500' : batteryTemp < 55 ? 'bg-yellow-500' : 'bg-red-500'
                      }`}
                      style={{ width: `${Math.min((batteryTemp / 70) * 100, 100)}%` }}
                    />
                  </div>
                </div>
                <div>
                  <Wind className="text-cyan-400 mb-3" size={32} />
                  <div className="text-5xl font-bold text-cyan-400">{fanSpeed.toFixed(0)}%</div>
                  <div className="text-gray-400 mt-2">Fan Speed</div>
                  <div className="mt-3 bg-gray-700 rounded-full h-4 overflow-hidden">
                    <div 
                      className="bg-cyan-500 h-full transition-all duration-300"
                      style={{ width: `${fanSpeed}%` }}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
              <div className="flex items-center gap-3 mb-4">
                <Zap className="text-yellow-400" size={24} />
                <h2 className="text-xl font-semibold">Power Consumption</h2>
              </div>
              <div className="text-5xl font-bold text-yellow-400">{powerConsumption.toFixed(1)} kW</div>
              <div className="mt-4 bg-gray-700 rounded-full h-4 overflow-hidden">
                <div 
                  className="bg-yellow-500 h-full transition-all duration-300"
                  style={{ width: `${(powerConsumption / 150) * 100}%` }}
                />
              </div>
              <div className="text-gray-400 mt-2">Max: 150 kW</div>
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
              <h2 className="text-xl font-semibold mb-4">CAN Messages (DBC)</h2>
              <div className="space-y-3 text-sm font-mono">
                <div className="bg-gray-900 p-3 rounded">
                  <div className="text-blue-400">0x100 SPEED</div>
                  <div className="text-gray-400">Speed: {speed.toFixed(1)} km/h</div>
                </div>
                <div className="bg-gray-900 p-3 rounded">
                  <div className="text-green-400">0x200 BATTERY</div>
                  <div className="text-gray-400">Level: {batteryLevel.toFixed(1)}%</div>
                  <div className="text-gray-400">Voltage: {voltage.toFixed(1)}V</div>
                </div>
                <div className="bg-gray-900 p-3 rounded">
                  <div className="text-yellow-400">0x300 THERMAL</div>
                  <div className="text-gray-400">Temp: {batteryTemp.toFixed(1)}°C</div>
                  <div className="text-gray-400">Fan: {fanSpeed.toFixed(0)}%</div>
                </div>
                <div className="bg-gray-900 p-3 rounded">
                  <div className="text-purple-400">0x400 POWER</div>
                  <div className="text-gray-400">Power: {powerConsumption.toFixed(1)}kW</div>
                  <div className="text-gray-400">Current: {current.toFixed(1)}A</div>
                </div>
              </div>
            </div>

            <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
              <h2 className="text-xl font-semibold mb-4">Train Status</h2>
              <div className="relative overflow-hidden h-64 bg-gradient-to-b from-blue-950 via-blue-900 to-gray-900 rounded-lg">
                <div className="absolute bottom-0 w-full h-12 bg-gradient-to-t from-green-900 to-transparent opacity-30"></div>
                
                <div className="absolute bottom-16 w-full h-1 bg-gray-600"></div>
                <div className="absolute bottom-14 w-full h-1 bg-gray-500"></div>
                
                {speed > 10 && (
                  <div className="absolute inset-0 opacity-30">
                    {[...Array(5)].map((_, i) => (
                      <div
                        key={i}
                        className="absolute h-px bg-white"
                        style={{
                          top: `${20 + i * 15}%`,
                          width: `${20 + (speed / 120) * 30}%`,
                          left: '100%',
                          animation: `speedLine ${Math.max(0.5, 2 - speed / 60)}s linear infinite`,
                          animationDelay: `${i * 0.2}s`
                        }}
                      />
                    ))}
                  </div>
                )}
                
                <div 
                  className="absolute bottom-20 transition-all duration-1000"
                  style={{
                    left: '50%',
                    transform: `translateX(-50%) ${speed > 5 ? `translateY(${Math.sin(Date.now() / 100) * 2}px)` : ''}`,
                  }}
                >
                  <svg width="140" height="80" viewBox="0 0 140 80">
                    <defs>
                      <linearGradient id="trainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" style={{
                          stopColor: batteryLevel > 60 ? '#3b82f6' : batteryLevel > 30 ? '#eab308' : '#ef4444',
                          stopOpacity: 1
                        }} />
                        <stop offset="100%" style={{
                          stopColor: batteryLevel > 60 ? '#1e40af' : batteryLevel > 30 ? '#ca8a04' : '#991b1b',
                          stopOpacity: 1
                        }} />
                      </linearGradient>
                      
                      {batteryLevel <= 30 && (
                        <filter id="smoke">
                          <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" result="turbulence"/>
                          <feDisplacementMap in2="turbulence" in="SourceGraphic" scale="5" xChannelSelector="R" yChannelSelector="G"/>
                        </filter>
                      )}
                    </defs>
                    
                    <rect x="15" y="15" width="110" height="35" fill="url(#trainGradient)" rx="8" stroke="#1e293b" strokeWidth="2"/>
                    
                    <path d="M 20 15 L 30 5 L 110 5 L 120 15 Z" fill={batteryLevel > 60 ? '#60a5fa' : batteryLevel > 30 ? '#fbbf24' : '#f87171'} stroke="#1e293b" strokeWidth="1.5"/>
                    
                    <rect x="25" y="20" width="18" height="15" fill="#dbeafe" rx="3" opacity="0.9"/>
                    <rect x="48" y="20" width="18" height="15" fill="#dbeafe" rx="3" opacity="0.9"/>
                    <rect x="71" y="20" width="18" height="15" fill="#dbeafe" rx="3" opacity="0.9"/>
                    <rect x="94" y="20" width="18" height="15" fill="#dbeafe" rx="3" opacity="0.9"/>
                    
                    <line x1="25" y1="27" x2="43" y2="27" stroke="#93c5fd" strokeWidth="0.5"/>
                    <line x1="48" y1="27" x2="66" y2="27" stroke="#93c5fd" strokeWidth="0.5"/>
                    <line x1="71" y1="27" x2="89" y2="27" stroke="#93c5fd" strokeWidth="0.5"/>
                    <line x1="94" y1="27" x2="112" y2="27" stroke="#93c5fd" strokeWidth="0.5"/>
                    
                    <rect x="115" y="22" width="8" height="26" fill="#475569" rx="2"/>
                    <circle cx="119" cy="35" r="1" fill="#94a3b8"/>
                    
                    <rect x="22" y="42" width="20" height="6" fill="#1e293b" rx="1" stroke="#475569" strokeWidth="0.5"/>
                    <rect x="23" y="43" width={`${batteryLevel * 0.18}`} height="4" 
                          fill={batteryLevel > 60 ? '#22c55e' : batteryLevel > 30 ? '#eab308' : '#ef4444'} rx="0.5"/>
                    
                    {batteryLevel > 30 ? (
                      <>
                        <ellipse cx="50" cy="10" rx="3" ry={batteryLevel > 60 ? "4" : "3"} fill="#1e293b"/>
                        <ellipse cx="60" cy="10" rx="3" ry={batteryLevel > 60 ? "4" : "3"} fill="#1e293b"/>
                        {batteryLevel > 60 && (
                          <>
                            <ellipse cx="50" cy="9" rx="1" ry="1.5" fill="white"/>
                            <ellipse cx="60" cy="9" rx="1" ry="1.5" fill="white"/>
                          </>
                        )}
                      </>
                    ) : (
                      <>
                        <line x1="48" y1="9" x2="52" y2="11" stroke="#1e293b" strokeWidth="1.5" strokeLinecap="round"/>
                        <line x1="52" y1="9" x2="48" y2="11" stroke="#1e293b" strokeWidth="1.5" strokeLinecap="round"/>
                        <line x1="58" y1="9" x2="62" y2="11" stroke="#1e293b" strokeWidth="1.5" strokeLinecap="round"/>
                        <line x1="62" y1="9" x2="58" y2="11" stroke="#1e293b" strokeWidth="1.5" strokeLinecap="round"/>
                      </>
                    )}
                    
                    {batteryLevel > 60 ? (
                      <path d="M 45 12 Q 55 15 65 12" stroke="#1e293b" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
                    ) : batteryLevel > 30 ? (
                      <line x1="45" y1="13" x2="65" y2="13" stroke="#1e293b" strokeWidth="1.5" strokeLinecap="round"/>
                    ) : (
                      <path d="M 45 14 Q 55 12 65 14" stroke="#1e293b" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
                    )}
                    
                    {batteryLevel <= 30 && (
                      <>
                        <circle cx="70" cy="8" r="3" fill="#6b7280" opacity="0.4" filter="url(#smoke)">
                          <animate attributeName="cy" values="8;0;8" dur="2s" repeatCount="indefinite"/>
                          <animate attributeName="opacity" values="0.4;0;0.4" dur="2s" repeatCount="indefinite"/>
                        </circle>
                        <circle cx="75" cy="8" r="2.5" fill="#6b7280" opacity="0.3" filter="url(#smoke)">
                          <animate attributeName="cy" values="8;2;8" dur="2.5s" repeatCount="indefinite"/>
                          <animate attributeName="opacity" values="0.3;0;0.3" dur="2.5s" repeatCount="indefinite"/>
                        </circle>
                      </>
                    )}
                    
                    <rect x="15" y="48" width="110" height="4" fill="#374151" rx="1"/>
                    
                    <g>
                      <circle cx="35" cy="58" r="10" fill="#1f2937" stroke="#111827" strokeWidth="2"/>
                      <circle cx="35" cy="58" r="7" fill="#374151"/>
                      <circle cx="35" cy="58" r="3" fill="#4b5563"/>
                      <g style={{
                        transformOrigin: '35px 58px',
                        animation: speed > 0 ? `spin ${Math.max(0.3, 2 - speed / 60)}s linear infinite` : 'none'
                      }}>
                        <line x1="35" y1="52" x2="35" y2="64" stroke="#6b7280" strokeWidth="2"/>
                        <line x1="30" y1="58" x2="40" y2="58" stroke="#6b7280" strokeWidth="2"/>
                      </g>
                      
                      <circle cx="55" cy="58" r="10" fill="#1f2937" stroke="#111827" strokeWidth="2"/>
                      <circle cx="55" cy="58" r="7" fill="#374151"/>
                      <circle cx="55" cy="58" r="3" fill="#4b5563"/>
                      <g style={{
                        transformOrigin: '55px 58px',
                        animation: speed > 0 ? `spin ${Math.max(0.3, 2 - speed / 60)}s linear infinite` : 'none'
                      }}>
                        <line x1="55" y1="52" x2="55" y2="64" stroke="#6b7280" strokeWidth="2"/>
                        <line x1="50" y1="58" x2="60" y2="58" stroke="#6b7280" strokeWidth="2"/>
                      </g>
                      
                      <circle cx="85" cy="58" r="10" fill="#1f2937" stroke="#111827" strokeWidth="2"/>
                      <circle cx="85" cy="58" r="7" fill="#374151"/>
                      <circle cx="85" cy="58" r="3" fill="#4b5563"/>
                      <g style={{
                        transformOrigin: '85px 58px',
                        animation: speed > 0 ? `spin ${Math.max(0.3, 2 - speed / 60)}s linear infinite` : 'none'
                      }}>
                        <line x1="85" y1="52" x2="85" y2="64" stroke="#6b7280" strokeWidth="2"/>
                        <line x1="80" y1="58" x2="90" y2="58" stroke="#6b7280" strokeWidth="2"/>
                      </g>
                      
                      <circle cx="105" cy="58" r="10" fill="#1f2937" stroke="#111827" strokeWidth="2"/>
                      <circle cx="105" cy="58" r="7" fill="#374151"/>
                      <circle cx="105" cy="58" r="3" fill="#4b5563"/>
                      <g style={{
                        transformOrigin: '105px 58px',
                        animation: speed > 0 ? `spin ${Math.max(0.3, 2 - speed / 60)}s linear infinite` : 'none'
                      }}>
                        <line x1="105" y1="52" x2="105" y2="64" stroke="#6b7280" strokeWidth="2"/>
                        <line x1="100" y1="58" x2="110" y2="58" stroke="#6b7280" strokeWidth="2"/>
                      </g>
                    </g>
                    
                    <circle cx="10" cy="30" r="4" fill={speed > 0 ? '#fef08a' : '#71717a'} stroke="#1e293b" strokeWidth="1">
                      {speed > 0 && (
                        <animate attributeName="opacity" values="1;0.6;1" dur="2s" repeatCount="indefinite"/>
                      )}
                    </circle>
                    {speed > 0 && (
                      <circle cx="10" cy="30" r="6" fill="#fef08a" opacity="0.3"/>
                    )}
                  </svg>
                </div>
                
                <div className="absolute top-4 left-4 text-sm">
                  <div className={`font-semibold ${
                    batteryLevel > 60 ? 'text-green-400' : 
                    batteryLevel > 30 ? 'text-yellow-400' : 
                    'text-red-400'
                  }`}>
                    {batteryLevel > 60 ? '😊 Battery Good' : 
                     batteryLevel > 30 ? '😐 Battery OK' : 
                     '😫 Low Battery'}
                  </div>
                  <div className="text-gray-400 text-xs mt-1">
                    {speed === 0 ? 'Stopped' : speed < 30 ? 'Cruising' : speed < 70 ? 'Moving Fast' : 'High Speed!'}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-6 bg-gray-800 rounded-lg p-6 border border-gray-700">
          <h2 className="text-xl font-semibold mb-3">DBC File Structure (Sample)</h2>
          <pre className="bg-gray-900 p-4 rounded text-xs overflow-x-auto text-gray-300">
{`BO_ 256 SPEED: 2 VCU
 SG_ speed : 0|16@1+ (0.1,0) [0|120] "km/h" DISPLAY

BO_ 512 BATTERY: 3 BMS
 SG_ level : 0|8@1+ (1,0) [0|100] "%" DISPLAY
 SG_ voltage : 8|16@1+ (0.1,0) [0|500] "V" DISPLAY

BO_ 768 THERMAL: 3 BMS
 SG_ temperature : 0|16@1+ (0.1,-40) [-40|85] "degC" DISPLAY
 SG_ fanSpeed : 16|8@1+ (1,0) [0|100] "%" DISPLAY

BO_ 1024 POWER: 4 VCU
 SG_ consumption : 0|16@1+ (0.1,0) [0|200] "kW" DISPLAY
 SG_ current : 16|16@1+ (0.1,0) [0|500] "A" DISPLAY`}
          </pre>
        </div>
      </div>
    </div>
  );
};

export default CANBusTrainMonitor;