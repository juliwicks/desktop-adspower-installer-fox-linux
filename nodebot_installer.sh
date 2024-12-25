#!/bin/bash

# Define color codes
INFO='\033[0;36m'  # Cyan
BANNER='\033[0;35m' # Magenta
WARNING='\033[0;33m'
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
NC='\033[0m' # No Color

# Display the banner
echo -e "${BANNER}"
echo "___________________________________________________________________________"
echo "   ________                 __      __                                    "
echo "   \______ \   ____   _____|  | ___/  |_  ____ ______                      "
echo "    |    |  \_/ __ \ /  ___/  |/ /\   __\/  _ \\____ \                     "
echo "    |    \`   \  ___/ \___ \|    <  |  | (  <_> )  |_> >                    "
echo "   /_______  /\___  >____  >__|_ \ |__|  \____/|   __/                     "
echo "           \/     \/     \/     \/             |__|                        "
echo "     ____       _____       .___     __________                            "
echo "    /  _ \     /  _  \    __| _/_____\______   \______  _  __ ___________  "
echo "    >  _ </\  /  /_\  \  / __ |/  ___/|     ___/  _ \ \/ \/ // __ \_  __ \ "
echo "   /  <_\ \/ /    |    \/ /_/ |\___ \ |    |  (  <_> )     /\  ___/|  | \/ "
echo "   \_____\ \ \____|__  /\____ /____  >|____|   \____/ \/\_/  \___  >__|    "
echo "          \/         \/      \/    \/                            \/        "
echo "   .___                 __         .__  .__                               "
echo "   |   | ____   _______/  |______  |  | |  |   ___________                 "
echo "   |   |/    \ /  ___/\   __\__  \ |  | |  | _/ __ \_  __ \                "
echo "   |   |   |  \\___ \  |  |  / __ \|  |_|  |_\  ___/|  | \/                "
echo "   |___|___|  /____  > |__| (____  /____/____/\___  >__|                   "
echo "            \/     \/            \/               \/                       "
echo "___________________________________________________________________________"
echo "                     Script by NodeBot (Juliwicks)                         "
echo "___________________________________________________________________________"
echo -e "${NC}"

# Prompt for username and password
while true; do
    read -p "Enter the username for remote desktop: " USER
    if [[ "$USER" == "root" ]]; then
        echo -e "${ERROR}Error: 'root' cannot be used as the username. Please choose a different username.${NC}"
    elif [[ "$USER" =~ [^a-zA-Z0-9] ]]; then
        echo -e "${ERROR}Error: Username contains forbidden characters. Only alphanumeric characters are allowed.${NC}"
    else
        break
    fi
done

while true; do
    read -sp "Enter the password for $USER: " PASSWORD
    echo
    if [[ "$PASSWORD" =~ [^a-zA-Z0-9] ]]; then
        echo -e "${ERROR}Error: Password contains forbidden characters. Only alphanumeric characters are allowed.${NC}"
    else
        break
    fi
done

# Install XFCE and XRDP
echo -e "${INFO}Installing XFCE Desktop for lower resource usage...${NC}"
sudo apt install -y xfce4 xfce4-goodies xubuntu-desktop

echo -e "${INFO}Installing XRDP for remote desktop...${NC}"
sudo apt install -y xrdp

echo -e "${INFO}Adding the user $USER with the specified password...${NC}"
sudo useradd -m -s /bin/bash $USER
echo "$USER:$PASSWORD" | sudo chpasswd

echo -e "${INFO}Adding $USER to the sudo group...${NC}"
sudo usermod -aG sudo $USER

# Configure XRDP to use XFCE
echo -e "${INFO}Configuring XRDP to use XFCE desktop...${NC}"
echo "xfce4-session" | sudo tee /home/$USER/.xsession

echo -e "${INFO}Configuring XRDP to use lower resolution by default...${NC}"
sudo sed -i 's/^#xserverbpp=24/xserverbpp=16/' /etc/xrdp/xrdp.ini
echo -e "${SUCCESS}XRDP configuration updated to use lower color depth.${NC}"

echo -e "${INFO}Limiting the resolution to a maximum (800x600)...${NC}"
sudo sed -i '/\[xrdp1\]/a max_bpp=16\nxres=800\nyres=600' /etc/xrdp/xrdp.ini
echo -e "${SUCCESS}XRDP configuration updated to use lower resolution (1280x720).${NC}"

echo -e "${INFO}Restarting XRDP service...${NC}"
sudo systemctl restart xrdp

echo -e "${INFO}Enabling XRDP service at startup...${NC}"
sudo systemctl enable xrdp

# Ensure the Desktop directory exists
DESKTOP_DIR="/home/$USER/Desktop"
if [ ! -d "$DESKTOP_DIR" ]; then
    echo -e "${INFO}Desktop directory not found. Creating Desktop directory for $USER...${NC}"
    sudo mkdir -p "$DESKTOP_DIR"
    sudo chown $USER:$USER "$DESKTOP_DIR"
fi

# Set permissions for the desktop file
sudo chmod +x $DESKTOP_FILE
sudo chown $USER:$USER $DESKTOP_FILE

# Get the server IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

# Final message
echo -e "${SUCCESS}Installation complete. XFCE Desktop, XRDP, AdsPower, and a desktop shortcut have been installed.${NC}"
echo -e "${INFO}You can now connect via Remote Desktop with the following details:${NC}"
echo -e "${INFO}IP ADDRESS: ${SUCCESS}$IP_ADDR${NC}"
echo -e "${INFO}USER: ${SUCCESS}$USER${NC}"
echo -e "${INFO}PASSWORD: ${SUCCESS}$PASSWORD${NC}"

# Restart the system
echo -e "${INFO}Rebooting system to apply all changes...${NC}"
sudo reboot
