# Backup Current Network Config
echo -e "Setting NIC to DHCP..."
cp /etc/network/interfaces /etc/network/interfaces.bak

# Set Network Interface to DHCP
echo -e 'auto lo' > /etc/network/interfaces
echo -e 'iface lo inet loopback' >> /etc/network/interfaces
echo -e '' >> /etc/network/interfaces
echo -e 'iface wlo1 inet manual' >> /etc/network/interfaces
echo -e '' >> /etc/network/interfaces
echo -e 'auto enp89s0' >> /etc/network/interfaces
echo -e 'iface enp89s0 inet manual' >> /etc/network/interfaces
echo -e '' >> /etc/network/interfaces
echo -e 'auto vmbr0' >> /etc/network/interfaces
echo -e 'iface vmbr0 inet dhcp' >> /etc/network/interfaces
echo -e '    bridge-ports enp89s0' >> /etc/network/interfaces
echo -e '    bridge-stp off' >> /etc/network/interfaces
echo -e '    bridge-fd 0' >> /etc/network/interfaces

# Update Sources
echo -e "Updating Sources..."
echo -e '#deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise' > /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" >> /etc/apt/sources.list.d/pve-enterprise.list

# Remove Subscription Message
echo -e "Removing Subscription Alert..."
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service

# Initialize SSH
echo -e "Initializing SSH..."
cd /etc/ssh
update-rc.d -f ssh remove
update-rc.d -f ssh defaults
mkdir default_kali_keys
mv ssh_host_* default_kali_keys/
dpkg-reconfigure openssh-server
service ssh restart
systemctl enable ssh.service
systemctl start ssh.service
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Add SSH Keys
echo -e "Adding SSH Keys..."
mkdir -p ~/.ssh
chmod -R go= ~/.ssh
echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6QEsAkdhOOks8fHgteZF7h4gMSxJXUgWz1Uvl3OUnu root@sbs >> ~/.ssh/authorized_keys
echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINA+yhJj8+GAQspyCyEMRZVwfyIuGI7UEbbz+nlgDtBH dealers@s3 >> ~/.ssh/authorized_keys
echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHo3Rw6MBJX21RhRQMPJnCN/4a7UMUYQEAW8XPDZApOe ddaniels@s3 >> ~/.ssh/authorized_keys
echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjjd9fxd9pmLVYNWYGEvFJSbjLnn6uDsiKNvGAOttWU kevin@s3  >> ~/.ssh/authorized_keys
echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOfLWJcwmLLEu92UzISkfRpWNRhIPUVfO2xMjyVx3TaxNJZYNPulkdpgHXEQIwy2zZ5bpXOe0+FNETRXm0qGv24Lvy9V7dCHowpDiAyASrjjkbP00S/B58HM+tE4IIo1HhfiOibJG/fMRW5FLhS7JLJ+3J/EBXpW/yKO72MjVR1jJpZRstBGw8s6f8wD3zOcSRGZy1GyTzBi+Kjd17Tj4CZ6byGKFgMZoH6HHE1TSsqdIKzJBwHfzKc5eypJ/t2GDcIRe7Dzs+5PeTkPcbLkuDJp3Mdnl1l9ClIwokQGdKHaEfO2KFEbpBumXbHFB1LZnSuQLWEmf4Pr40uivj3Jwjzzp6VShY1CLXHrghVuYUQOHOJjrfeEGxbF4KbqpAqNcTuOZ5LtRZYmzGWdRAmLVqtGRCVn13q00hFiLxyR9Uom/5xaPMJrhZ0q/Tu/R3uUDujV3fK1zaf03QD0iYJ3lwmAqUPE7d86w3SKfI2RrlOnUqjhhO8UhRLy8sR4XliOE= Brian Dunnohew >> ~/.ssh/authorized_keys

# Update
echo -e "Updating System Files & Apps..."
apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && apt autoremove -y

# Install Policy Utils & Network Manager
apt-get -y install policycoreutils -y
apt-get install network-manager -y

# Install NinjaOne
echo -e "Installing RMM Tool..."
cd /opt
wget -O 1NinjaRMM.deb https://www.dropbox.com/s/xp05xa6zr1h0jrp/1dlnucmanagementmainoffice-5.3.5097-installer.deb?dl=1
dpkg -i 1NinjaRMM.deb

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Prompt for Password Change
echo -e 'You should change the ROOT password!'
while true; do
    read -p "Would you like to change the ROOT password now?" yn
    case $yn in
        [Yy]* ) passwd root; break;;
        [Nn]* ) echo -e "Password NOT Changed"; break;;
        * ) echo "Please answer yes (Y/y) or no (N/n).";;
    esac
done

# Prompt for NW Restart
echo -e 'You should restart netwrking services to initialize DHCP!'
while true; do
    read -p "Would you like to restart netwrking services now?" yn
    case $yn in
        [Yy]* ) systemctl restart networking; break;;
        [Nn]* ) echo -e "Networking Services NOT Restarted -- Reboot is recommended!"; break;;
        * ) echo "Please answer yes (Y/y) or no (N/n).";;
    esac
done

# Prompt for Tailscale Start
while true; do
    read -p "Would you like to start Tailscale now?" yn
    case $yn in
        [Yy]* ) tailscale up; break;;
        [Nn]* ) echo -e "Tailscale NOT Started!"; break;;
        * ) echo "Please answer yes (Y/y) or no (N/n).";;
    esac
done