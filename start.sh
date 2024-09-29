#!/bin/bash

# Terminal colors
GREEN='\033[0;32m'
WHITE='\033[0;37m'
CYAN='\033[0;36m'
RED='\033[0;31m'

# Function to download files
download() {
    wget -q --show-progress -O "$2" "$1"
}

# Function to install Cloudflared
install_cloudflared() { 
    # Cria o diretório .server se não existir
    mkdir -p .server

    if [[ -e ".server/cloudflared" ]]; then
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Cloudflared already installed."
    else
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing Cloudflared..."${WHITE}
        arch=$(uname -m)
        if [[ "$arch" == *'arm'* || "$arch" == *'Android'* ]]; then
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm' 'cloudflared'
        elif [[ "$arch" == *'aarch64'* ]]; then
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64' 'cloudflared'
        elif [[ "$arch" == *'x86_64'* ]]; then
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64' 'cloudflared'
        else
            download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386' 'cloudflared'
        fi
        
        chmod +x ./cloudflared
        mv ./cloudflared .server/cloudflared
        
        # Verifica se o arquivo foi movido corretamente
        if [[ -e ".server/cloudflared" ]]; then
            echo -e "${GREEN}[${WHITE}+${GREEN}]${CYAN} Cloudflared installed successfully."
        else
            echo -e "${RED}[${WHITE}--${RED}]${CYAN} Failed to move Cloudflared to .server directory."
        fi
    fi
}

# Function to start the HTTP server
start_http_server() {
    echo "Starting HTTP server for index.html on port 8080..."
    python3 -m http.server 8080 --directory "$(pwd)" > /dev/null 2>&1 &
}

# Function to start Cloudflared without authentication
start_cloudflared() { 
    echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Launching Cloudflared..."

    # Launch Cloudflared for redirection
    ./.server/cloudflared tunnel --url http://localhost:8080 --logfile .server/.cld.log > /dev/null 2>&1 &
    
    sleep 8
    cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".server/.cld.log" | head -n 1)
    
    if [ -z "$cldflr_url" ]; then
        echo -e "${RED}[${WHITE}--${RED}]${CYAN} Log file not found. Unable to retrieve Cloudflared URL."
    else
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Connect to the Minecraft server using the following link: ${WHITE}$cldflr_url:${RED}25565"
    fi
}

# Java installation
install_java() {
    echo "Detecting system architecture..."
    ARCH=$(uname -m)

    if [[ "$ARCH" == "x86_64" ]]; then
        echo "Installing Java 21 for x86_64..."
        URL="https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz"
    elif [[ "$ARCH" == "aarch64" ]]; then
        echo "Installing Java 21 for aarch64..."
        URL="https://download.oracle.com/java/21/latest/jdk-21_linux-aarch64_bin.tar.gz"
    else
        echo "Unsupported architecture: $ARCH"
        return 1
    fi

    echo "Downloading Java from $URL..."
    wget $URL -O jdk-21.tar.gz

    echo "Extracting files..."
    tar -xzf jdk-21.tar.gz

    echo "Installing Java..."
    sudo mv jdk-21 /usr/local/
    sudo update-alternatives --install /usr/bin/java java /usr/local/jdk-21/bin/java 1
    sudo update-alternatives --install /usr/bin/javac javac /usr/local/jdk-21/bin/javac 1

    echo "Java installed successfully!"
    java -version
}

# Main function
main() {
    HOST="localhost"
    PORT="25565" # Change to your server's port

    # Install Cloudflared
    install_cloudflared

    # Check Cloudflared installation
    if [[ ! -e ".server/cloudflared" ]]; then
        echo -e "${RED}[${WHITE}--${RED}]${CYAN} Cloudflared not installed correctly. Exiting."
        exit 1
    fi

    # Install Java
    install_java
    
    # Start the HTTP server
    start_http_server

    # Start Cloudflared
    start_cloudflared

    # Start the Minecraft server
    echo "Starting Minecraft server..."
    java -Xmx1024M -Xms1024M -jar paper-1.21.1-110.jar nogui

    echo "Minecraft server started with Cloudflared IP."
}

# Execute the main function
main
