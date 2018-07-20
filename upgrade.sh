#!/bin/bash
# upgrade.sh
# Make sure geekcashd is up-to-date

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

echo "GeekCash downloading..."

apt install curl -y
curl -LJO https://github.com/GeekCash/geekcash/releases/download/v1.0.1.3/geekcash-1.0.1-x86_64-linux-gnu.tar.gz

echo "unzip..."
tar -xzvf ./geekcash-1.0.1-x86_64-linux-gnu.tar.gz
chmod +x ./geekcash-1.0.1/bin/

# check geekcash runing & stop

if ps ax | grep -v grep | grep geekcashd > /dev/null
then
    geekcash-cli stop && sleep 5
fi

echo "Put executable to /usr/bin"
cp ./geekcash-1.0.1/bin/geekcashd /usr/bin/
cp ./geekcash-1.0.1/bin/geekcash-cli /usr/bin/

# remove temp
rm -rf ./geekcash-1.0.1
rm -rf ./geekcash-1.0.1-x86_64-linux-gnu.tar.gz


#start geekcashd

geekcashd