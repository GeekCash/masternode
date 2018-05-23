# GeekCash Masternode
### Bash installer for masternode on Ubuntu 16.04 LTS x64 and Ubuntu 18.04 LTS x64

#### This shell script comes with 3 cronjobs: 
1. Make sure the daemon is always running: `makerun.sh`
2. Make sure the daemon is never stuck: `checkdaemon.sh`
3. Clear the log file every other day: `clearlog.sh`

#### Login to your vps as root, download the install.sh file and then run it:
```
wget https://rawgit.com/GeekCash/masternode/master/install.sh
chmod +x ./install.sh
bash ./install.sh
```

#### On the client-side, add the following line to masternode.conf:
```
mn-alias vps-ip:6889 masternode-genkey collateral-txid vout
```

#### Run the qt wallet, go to Masternodes tab, choose your node and click "start alias" at the bottom.

## Suggest Masternode VPS
Get $10 bonus: [Take it now](https://m.do.co/c/427fd48a9ec5)
