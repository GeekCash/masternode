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
   printf "~/.geekcash/ already exists! The installer will delete this folder. Continue anyway?(Y/n):"
   read REPLY
   if [ ${REPLY} == "Y" ]; then
      #pID=$(ps -ef | grep geekcashd | awk '{print $2}')
      #kill ${pID}
      killall -v geekcashd && sleep 5     
      
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

cd

# Get a new privatekey by going to console >> debug and typing masternode genkey
printf "Enter Masternode PrivateKey: "
read _nodePrivateKey

# The RPC node will only accept connections from your localhost
_rpcUserName=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ; echo '')

# Choose a random and secure password for the RPC
_rpcPassword=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')

# Get the IP address of your vps which will be hosting the masternode

_nodeIpAddress=`curl ifconfig.me/ip`
#_nodeIpAddress=$(curl -s 4.icanhazip.com)
if [[ ${_nodeIpAddress} =~ ^[0-9]+.[0-9]+.[0-9]+.[0-9]+$ ]]; then
  external_ip_line="externalip=${_nodeIpAddress}:6889"
else
  external_ip_line="#externalip=external_IP_goes_here:6889"
fi
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
${external_ip_line}
masternodeprivkey=${_nodePrivateKey}
" > geekcash.conf
cd

# Download geekcash and put executable to /usr/local/bin

echo "GeekCash downloading..."
apt install curl -y
curl -LJO https://github.com/GeekCash/geekcash/releases/download/v1.2.0.1/geekcash-1.2.0-x86_64-linux-gnu.tar.gz

echo "unzip..."
tar -xzvf ./geekcash-1.2.0-x86_64-linux-gnu.tar.gz
chmod +x ./geekcash-1.2.0/bin/


echo "Put executable to /usr/bin"
cp ./geekcash-1.2.0/bin/geekcashd /usr/bin/
cp ./geekcash-1.2.0/bin/geekcash-cli /usr/bin/


rm -rf ./geekcash-1.2.0
rm -rf ./geekcash-1.2.0-x86_64-linux-gnu.tar.gz


# Create a directory for masternode's cronjobs and the anti-ddos script
rm -r masternode/geekcash
mkdir -p masternode/geekcash

# Change the directory to ~/masternode/
cd ~/masternode/geekcash

# Download the appropriate scripts
wget https://raw.githubusercontent.com/GeekCash/masternode/master/makerun.sh
wget https://raw.githubusercontent.com/GeekCash/masternode/master/checkdaemon.sh
wget https://raw.githubusercontent.com/GeekCash/masternode/master/clearlog.sh


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

# Create a cronjob for clearing the log file
if ! crontab -l | grep "~/masternode/geekcash/clearlog.sh"; then
  (crontab -l ; echo "0 0 */2 * * ~/masternode/geekcash/clearlog.sh") | crontab -
fi

# Give execute permission to the cron scripts
chmod 0700 ./makerun.sh
chmod 0700 ./checkdaemon.sh
chmod 0700 ./clearlog.sh

# Firewall security measures
apt install ufw -y
ufw allow 6889
ufw allow ssh
ufw logging on
ufw default allow outgoing
ufw --force enable

# Start GeekCash Deamon
echo "GeekCash server starting..."
geekcashd -reindex

# Reboot the server
#reboot