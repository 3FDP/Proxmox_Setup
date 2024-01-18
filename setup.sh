####################################
### Useful Scripts
####################################

### From https://tteck.github.io/Proxmox/

# bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
# bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/kernel-clean.sh)"
# bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/microcode.sh)"
# bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/cron-update-lxcs.sh)"

####################################
### Software Setup
####################################

# Update and upgrade
apt update -y
apt upgrade -y

# Flatpak setup
apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Nvidia drivers (if needed)
if lspci | grep -i "nvidia" > /dev/null; then
    echo "NVIDIA GPU detected. Installing drivers..."
    echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | tee -a /etc/apt/sources.list    apt install nvidia-driver firmware-misc-nonfree
    apt update -y
    apt install -y pve-headers build-essential nvidia-driver

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
else
    # echo "No NVIDIA GPU detected."
fi

# Terminal essentials
apt install -y wget git neofetch

####################################
### Docker Setup
####################################

apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
# groupadd docker
usermod -aG docker $USER
systemctl enable docker.service
systemctl start docker.service

# Docker-Compose Setup
cp docker-compose.yml ~/docker/docker-compose.yml
cp .env ~/docker/.env
cd ~/docker
docker-compose up -d

####################################
### Stable Diffusion Setup
####################################

# Cloning the dockerized Stable Diffusion WebUI
git clone https://github.com/AbdBarho/stable-diffusion-webui-docker.git
cd stable-diffusion-webui-docker

# Adding restart policy to the Automatic1111 service
awk '
/auto: &automatic/ { print; print "    restart: unless-stopped"; next }
1' docker-compose.yml > tmpfile && mv tmpfile docker-compose.yml

# Download and deploy
docker compose --profile download up --build -d
docker compose --profile auto up --build -d

####################################
### Wrap-up
####################################

# Restart
reboot