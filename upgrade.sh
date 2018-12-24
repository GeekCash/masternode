#!/bin/bash
# upgrade.sh
# Make sure geekcashd is up-to-date

# geekcash stop
geekcash-cli stop

echo "GeekCash downloading..."

sudo apt-get install curl -y
curl -LJO https://github.com/GeekCash/geekcash/releases/download/v1.2.0.1/geekcash-1.2.0-x86_64-linux-gnu.tar.gz

echo "unzip..."
tar -xzvf ./geekcash-1.2.0-x86_64-linux-gnu.tar.gz
chmod +x ./geekcash-1.2.0/bin/

echo "Put executable to /usr/bin"
sudo cp ./geekcash-1.2.0/bin/geekcashd /usr/bin/
sudo cp ./geekcash-1.2.0/bin/geekcash-cli /usr/bin/

# remove temp
rm -rf ./geekcash-1.2.0
rm -rf ./geekcash-1.2.0-x86_64-linux-gnu.tar.gz

#start geekcashd
echo "GeekCash start..."
sleep 15 && geekcashd