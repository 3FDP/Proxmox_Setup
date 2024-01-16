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
    apt install -y nvidia-driver
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

####################################
### Wrap-up
####################################

# Restart
reboot