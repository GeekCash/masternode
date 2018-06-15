#!/bin/bash
# install.sh
# Installs masternode on Ubuntu 16.04 x64 & Ubuntu 18.04
# ATTENTION: The anti-ddos part will disable http, https and dns ports.


if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

while true; do
 if [ -d ~/.geekcash ]; then
   printf "~/.geekcash/ already exists! The installer will delete this folder. Continue anyway?(Y/n)"
   read REPLY
   if [ ${REPLY} == "Y" ]; then
      pID=$(ps -ef | grep geekcashd | awk '{print $2}')
      kill ${pID}
      rm -rf ~/.geekcash/
      break
   else
      if [ ${REPLY} == "n" ]; then
        exit
      fi
   fi
 else
   break
 fi
done


# Warning that the script will reboot the server
echo "WARNING: This script will reboot the server when it's finished."
printf "Press Ctrl+C to cancel or Enter to continue: "
read IGNORE

cd
# Changing the SSH Port to a custom number is a good security measure against DDOS attacks
printf "Custom SSH Port(Enter to ignore): "
read VARIABLE
_sshPortNumber=${VARIABLE:-22}

# Get a new privatekey by going to console >> debug and typing masternode genkey
printf "Enter Masternode PrivateKey: "
read _nodePrivateKey

# The RPC node will only accept connections from your localhost
_rpcUserName=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ; echo '')

# Choose a random and secure password for the RPC
_rpcPassword=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')

# Get the IP address of your vps which will be hosting the masternode
_nodeIpAddress=`curl ipecho.net/plain`
echo _nodeIpAddress
# Make a new directory for geekcash daemon
rm -r ~/.geekcash/
mkdir ~/.geekcash/
touch ~/.geekcash/geekcash.conf

# Change the directory to ~/.geekcash
cd ~/.geekcash/

# Create the initial geekcash.conf file
echo "rpcuser=${_rpcUserName}
rpcpassword=${_rpcPassword}
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=64
txindex=1
masternode=1
externalip=${_nodeIpAddress}:6889
masternodeprivkey=${_nodePrivateKey}
" > geekcash.conf
cd

# Install geekcashd using apt-get
#apt-get install software-properties-common
#add-apt-repository ppa:geekcash/ppa -y && apt update && apt install geekcashd -y && geekcashd

# Download geekcash and put executable to /usr/local/bin

echo "Download GeekCash..."
#wget -qO- --no-check-certificate --content-disposition https://github.com/GeekCash/geekcash/releases/download/v1.0.1.2/geekcash-1.0.1-x86_64-linux-gnu.tar.gz | tar -xzvf geekcash-1.0.1-x86_64-linux-gnu.tar.gz

apt install curl -y
curl -LJO https://github.com/GeekCash/geekcash/releases/download/v1.0.1.3/geekcash-1.0.1-x86_64-linux-gnu.tar.gz

echo "unzip..."
tar -xzvf ./geekcash-1.0.1-x86_64-linux-gnu.tar.gz
chmod +x ./geekcash-1.0.1/bin/

#

echo "Put executable to /usr/bin"
cp ./geekcash-1.0.1/bin/geekcashd /usr/bin/
cp ./geekcash-1.0.1/bin/geekcash-cli /usr/bin/
cp ./geekcash-1.0.1/bin/geekcash-tx /usr/bin/

rm -rf ./geekcash-1.0.1
rm -rf ./geekcash-1.0.1-x86_64-linux-gnu.tar.gz


# Create a directory for masternode's cronjobs and the anti-ddos script
rm -r masternode/geekcash
mkdir -p masternode/geekcash

# Change the directory to ~/masternode/
cd ~/masternode/geekcash

# Download the appropriate scripts
#wget https://raw.githubusercontent.com/GeekCash/masternode/master/anti-ddos.sh
wget https://raw.githubusercontent.com/GeekCash/masternode/master/makerun.sh
wget https://raw.githubusercontent.com/GeekCash/masternode/master/checkdaemon.sh
wget https://raw.githubusercontent.com/GeekCash/masternode/master/clearlog.sh
#wget https://raw.githubusercontent.com/GeekCash/masternode/master/upgrade.sh

# Create a cronjob for making sure geekcashd runs after reboot
if ! crontab -l | grep "@reboot geekcashd"; then
  (crontab -l ; echo "@reboot geekcashd") | crontab -
fi

# Create a cronjob for making sure geekcashd is always running
if ! crontab -l | grep "~/masternode/geekcash/makerun.sh"; then
  (crontab -l ; echo "*/5 * * * * ~/masternode/geekcash/makerun.sh") | crontab -
fi

# Create a cronjob for making sure the daemon is never stuck
if ! crontab -l | grep "~/masternode/geekcash/checkdaemon.sh"; then
  (crontab -l ; echo "*/30 * * * * ~/masternode/geekcash/checkdaemon.sh") | crontab -
fi

# Create a cronjob for making sure geekcashd is always up-to-date
#if ! crontab -l | grep "~/masternode/geekcash/upgrade.sh"; then
#  (crontab -l ; echo "0 0 */1 * * ~/masternode/geekcash/upgrade.sh") | crontab -
#fi

# Create a cronjob for clearing the log file
if ! crontab -l | grep "~/masternode/geekcash/clearlog.sh"; then
  (crontab -l ; echo "0 0 */2 * * ~/masternode/geekcash/clearlog.sh") | crontab -
fi

# Give execute permission to the cron scripts
chmod 0700 ./makerun.sh
chmod 0700 ./checkdaemon.sh
#chmod 0700 ./upgrade.sh
chmod 0700 ./clearlog.sh

# Change the SSH port
sed -i "s/[#]\{0,1\}[ ]\{0,1\}Port [0-9]\{2,\}/Port ${_sshPortNumber}/g" /etc/ssh/sshd_config

# Firewall security measures
apt install ufw -y
ufw disable
ufw allow 6889
ufw allow "$_sshPortNumber"/tcp
ufw limit "$_sshPortNumber"/tcp
ufw logging on
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# Reboot the server
reboot