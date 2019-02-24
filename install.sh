#!/bin/bash
# install.sh
# Installs masternode on Ubuntu 16.04 x64 & Ubuntu 18.04
# ATTENTION: The anti-ddos part will disable http, https and dns ports.

sudo apt-get install curl ufw -y;

while true; do
 if [ -d ~/.geekcash ]; then
   printf "~/.geekcash/ already exists! The installer will delete this folder. Continue anyway?(Y/n):"
   read REPLY
   if [[ $REPLY == "" || $REPLY == "y" || $REPLY == "Y" ]]; then
      #pID=$(ps -ef | grep geekcashd | awk '{print $2}')
      #kill ${pID}
      geekcash-cli stop && sleep 5    

      rm -rf ~/.geekcash 
      
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

# Choose a random and secure password for the RPC
_rpcPassword=$(head /dev/urandom | tr -dc A-Z0-9 | head -c 32 ; echo '')

# Get the IP address of your vps which will be hosting the masternode

_nodeIpAddress=`curl ifconfig.me/ip`
#_nodeIpAddress=$(curl -s 4.icanhazip.com)
if [[ ${_nodeIpAddress} =~ ^[0-9]+.[0-9]+.[0-9]+.[0-9]+$ ]]; then
  external_ip_line="externalip=${_nodeIpAddress}:6889"
else
  external_ip_line="#externalip=external_IP_goes_here:6889"
fi

# Make a new directory for geekcash daemon
mkdir -p ~/.geekcash/ && touch ~/.geekcash/geekcash.conf

# Change the directory to ~/.geekcash
cd ~/.geekcash/

# Create the initial geekcash.conf file
echo "rpcuser=root
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
curl -LJO https://github.com/GeekCash/geek/releases/download/v1.3.0.1/geekcash-1.3.0-x86_64-linux-gnu.tar.gz

echo "unzip..."
tar -xzvf ./geekcash-1.3.0-x86_64-linux-gnu.tar.gz
chmod +x ./geekcash-1.3.0/bin/

echo "Put executable to /usr/bin"
sudo cp ./geekcash-1.3.0/bin/geekcashd /usr/bin/
sudo cp ./geekcash-1.3.0/bin/geekcash-cli /usr/bin/

rm -rf ./geekcash-1.3.0
rm -rf ./geekcash-1.3.0-x86_64-linux-gnu.tar.gz

# Create a cronjob for making sure geekcashd runs after reboot
if ! crontab -l | grep "@reboot geekcashd"; then
  (crontab -l ; echo "@reboot geekcashd") | crontab -
fi

# Firewall security measures
sudo ufw allow 6889
sudo ufw allow ssh
sudo ufw logging on
sudo ufw default allow outgoing
sudo ufw --force enable

# Start GeekCash Deamon
echo "GeekCash server starting..."
geekcashd

# Reboot the server
#reboot