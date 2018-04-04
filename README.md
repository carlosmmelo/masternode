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

