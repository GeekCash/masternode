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
curl -LJO https://github.com/GeekCash/geekcash/releases/download/v1.2.0.1/geekcash-1.2.0-x86_64-linux-gnu.tar.gz

echo "unzip..."
tar -xzvf ./geekcash-1.2.0-x86_64-linux-gnu.tar.gz
chmod +x ./geekcash-1.2.0/bin/

# check geekcash runing & stop

if ps ax | grep -v grep | grep geekcashd > /dev/null
then
    geekcash-cli stop && sleep 15
fi

echo "Put executable to /usr/bin"
cp ./geekcash-1.2.0/bin/geekcashd /usr/bin/
cp ./geekcash-1.2.0/bin/geekcash-cli /usr/bin/

# remove temp
rm -rf ./geekcash-1.2.0
rm -rf ./geekcash-1.2.0-x86_64-linux-gnu.tar.gz


#start geekcashd
echo "GeekCash start..."
sleep 5 && geekcashd