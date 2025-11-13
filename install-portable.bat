@echo off
REM CAN Bus Train Monitor - Simple Batch Installer
REM This creates a portable installation in the current directory

echo =============================================
echo CAN Bus Train Monitor - Portable Installer
echo =============================================
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found!
    echo Please install Python from https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [OK] Python found
echo.

REM Create installation directory
set INSTALL_DIR=%USERPROFILE%\CANTrainMonitor
echo Installation directory: %INSTALL_DIR%
echo.

if exist "%INSTALL_DIR%" (
    echo Directory already exists. Delete it? (Y/N)
    set /p CONFIRM=
    if /i "%CONFIRM%"=="Y" (
        rmdir /s /q "%INSTALL_DIR%"
    ) else (
        echo Installation cancelled.
        pause
        exit /b 0
    )
)

mkdir "%INSTALL_DIR%"
echo [OK] Created directory
echo.

REM Install Python packages
echo Installing Python packages...
python -m pip install python-can websockets --quiet
if errorlevel 1 (
    echo [ERROR] Failed to install packages
    pause
    exit /b 1
)
echo [OK] Packages installed
echo.

REM Copy files
echo Copying files...

REM Copy standalone HTML if it exists
if exist "train-monitor-standalone.html" (
    copy /Y "train-monitor-standalone.html" "%INSTALL_DIR%\" >nul
    echo [OK] Copied train-monitor-standalone.html
) else (
    echo [WARNING] train-monitor-standalone.html not found
)

REM Copy server.py if it exists
if exist "server.py" (
    copy /Y "server.py" "%INSTALL_DIR%\" >nul
    echo [OK] Copied server.py
) else (
    echo [WARNING] server.py not found
)

REM Copy demo.dbc if it exists
if exist "demo.dbc" (
    copy /Y "demo.dbc" "%INSTALL_DIR%\" >nul
    echo [OK] Copied demo.dbc
)

echo.

REM Create launcher
echo Creating launcher script...
(
echo @echo off
echo echo ============================================
echo echo CAN Bus Train Monitor
echo echo ============================================
echo echo.
echo echo Starting server...
echo echo.
echo python server.py
echo pause
) > "%INSTALL_DIR%\start-monitor.bat"
echo [OK] Created start-monitor.bat
echo.

REM Create README
echo Creating README...
(
echo CAN Bus Train Monitor - Portable Installation
echo ==============================================
echo.
echo Quick Start:
echo 1. Double-click start-monitor.bat
echo 2. Browser will open automatically
echo 3. Press Ctrl+C in terminal to stop
echo.
echo Manual Start:
echo   python server.py
echo   Then open: http://localhost:3000/train-monitor-standalone.html
echo.
echo Configuration:
echo   Edit server.py to change ports and settings
echo.
echo Files:
echo   - server.py: Backend server
echo   - train-monitor-standalone.html: Web interface
echo   - start-monitor.bat: Launcher
echo   - demo.dbc: CAN database ^(optional^)
echo.
echo Requirements:
echo   - Python 3.7+
echo   - python-can and websockets packages
echo.
) > "%INSTALL_DIR%\README.txt"
echo [OK] Created README.txt
echo.

echo =============================================
echo Installation Complete!
echo =============================================
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo To start the monitor:
echo   1. Open: %INSTALL_DIR%
echo   2. Run: start-monitor.bat
echo.
echo Opening installation directory...
echo.
pause

REM Open installation directory
explorer "%INSTALL_DIR%"
