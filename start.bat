@echo off

:: Function to check if a package is installed
:check_installed
where %1 >nul 2>nul
if %errorlevel% neq 0 (
    exit /b 1
)
exit /b 0

:: Install Chocolatey
where choco >nul 2>nul
if %errorlevel% neq 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
)

:: Attempt to install Docker via Chocolatey
echo Installing Docker via Chocolatey...
choco install docker-desktop -y
choco install docker-compose -y
call :check_installed docker
if %errorlevel% equ 0 goto :docker_installed

:: Attempt to install Docker via Winget
echo Trying to install Docker via Winget...
winget install Docker.DockerDesktop -y
winget install Docker.DockerCompose -y
call :check_installed docker
if %errorlevel% equ 0 goto :docker_installed

:: Attempt to install Docker via Scoop
echo Trying to install Docker via Scoop...
scoop install docker-desktop
scoop install docker-compose
call :check_installed docker
if %errorlevel% equ 0 goto :docker_installed

:: If all installations fail, open Docker's official website
echo Docker installation failed. Please install Docker manually from the official site.
start https://www.docker.com/products/docker-desktop
goto :eof

:docker_installed
:: Create a new terminal to start the containers
echo Docker installed successfully. Starting Docker Compose...
start cmd /k "docker-compose build && docker-compose up"
