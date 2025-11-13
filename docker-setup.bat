@echo off
REM Docker Build and Run Script for CAN Bus Train Monitor (Windows)

setlocal EnableDelayedExpansion

set IMAGE_NAME=can-train-monitor
set CONTAINER_NAME=can-train-monitor

echo ============================================
echo CAN Bus Train Monitor - Docker Setup
echo ============================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed!
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo [OK] Docker found
echo.

echo Choose an option:
echo   1) Build image
echo   2) Run container
echo   3) Build and run
echo   4) Stop container
echo   5) View logs
echo   6) Remove container
echo   7) Docker Compose (up)
echo   8) Docker Compose (down)
echo   9) Clean up everything
echo.
set /p choice="Enter choice [1-9]: "

if "%choice%"=="1" goto build
if "%choice%"=="2" goto run
if "%choice%"=="3" goto buildrun
if "%choice%"=="4" goto stop
if "%choice%"=="5" goto logs
if "%choice%"=="6" goto remove
if "%choice%"=="7" goto composeup
if "%choice%"=="8" goto composedown
if "%choice%"=="9" goto cleanup
goto invalid

:build
echo.
echo Building Docker image...
docker build -t %IMAGE_NAME% .
if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo [OK] Image built successfully
goto end

:run
echo.
echo Running container...
docker run -d --name %CONTAINER_NAME% -p 3000:3000 -p 8080:8080 %IMAGE_NAME%
if errorlevel 1 (
    echo [ERROR] Failed to start container
    pause
    exit /b 1
)
echo [OK] Container started
echo.
echo Access at: http://localhost:3000/train-monitor-standalone.html
goto end

:buildrun
echo.
echo Building Docker image...
docker build -t %IMAGE_NAME% .
if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo [OK] Image built
echo.
echo Running container...
docker run -d --name %CONTAINER_NAME% -p 3000:3000 -p 8080:8080 %IMAGE_NAME%
if errorlevel 1 (
    echo [ERROR] Failed to start container
    pause
    exit /b 1
)
echo [OK] Container started
echo.
echo Access at: http://localhost:3000/train-monitor-standalone.html
start http://localhost:3000/train-monitor-standalone.html
goto end

:stop
echo.
echo Stopping container...
docker stop %CONTAINER_NAME%
echo [OK] Container stopped
goto end

:logs
echo.
echo Container logs (Ctrl+C to exit):
docker logs -f %CONTAINER_NAME%
goto end

:remove
echo.
echo Removing container...
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME%
echo [OK] Container removed
goto end

:composeup
echo.
echo Starting with Docker Compose...
docker-compose up -d
if errorlevel 1 (
    docker compose up -d
)
echo [OK] Services started
echo.
echo Access at: http://localhost:3000/train-monitor-standalone.html
start http://localhost:3000/train-monitor-standalone.html
goto end

:composedown
echo.
echo Stopping Docker Compose services...
docker-compose down 2>nul
if errorlevel 1 (
    docker compose down
)
echo [OK] Services stopped
goto end

:cleanup
echo.
echo Cleaning up everything...
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME% 2>nul
docker rmi %IMAGE_NAME% 2>nul
echo [OK] Cleanup complete
goto end

:invalid
echo Invalid choice
pause
exit /b 1

:end
echo.
pause
