# Masternode
Automation Scripts for XSN Masternodes


## Update Masternode

To update your masternode to the latest version, follow below steps:

1. SSH into your VPS and clone this repo (remember to replace uppercase values):
```
ssh USER@VPS_IP
git clone https://github.com/carlosmmelo/masternode.git
```

2. CD into the cloned project and Execute the masternode script with the update argument to update:
```
cd masternode
bash masternode.sh update
```


The script assumes your xsncore directory is at `~/.xsncore/` however
you can set where is your xsncore directory with `XSNCORE_PATH`:

```
XSNCORE_PATH=your_xsncore_dir_path bash masternode.sh update
```


# Sentinel (WatchDog)

## Install, Configure and Execute WatchDog

### Prerequisite:

In order for Sentinel to be able to connect to XSN network, you have to add the following into `xsn.conf` (use nano to edit the file):
```
rpcport=9998
```
Please note that everytime you update `xsn.conf` file you MUST restart your Masternode in order for the new update take effect.

To restart, simply kill xsnd:
```
ps aux | grep xsnd | grep -v grep | awk '{print $2}' | xargs kill -9
```
And then start it again:
```
~/.xsncore/xsnd --reindex
```
**WAIT** for it to sync (AssetID should reach 999):
```
~/.xsncore/xsn-cli mnsync status
```

If you already have `rpcport=9998` in your `xsn.conf` file, you just need to proceed with Sentinel installation and execution.

### Installation

To install or update sentinel to the latest version, follow below steps:

1. SSH into your VPS and clone this repo (remember to replace uppercase values):
```
ssh USER@VPS_IP
git clone https://github.com/carlosmmelo/masternode.git
```

2. CD into the cloned project and Execute the masternode script with the `execute_sentinel` argument:
```
cd masternode
git pull
bash masternode.sh execute_sentinel
```


The script assumes your xsncore directory is at `~/.xsncore/` however
you can set where is your xsncore directory with `XSNCORE_PATH`:

```
XSNCORE_PATH=your_xsncore_dir_path bash masternode.sh execute_sentinel
```

* **NOTE: This script ONLY works for Linux and for single MN in a single VPS.
For now, multi MN on single VPS requires a lot of manual intervention, stay tunned for upcoming updates here for automating that too.**
