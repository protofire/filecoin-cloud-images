#!/bin/bash
set -xeE

mkfs.xfs -f /dev/xvdb
# Mound disk and add automount entry in /etc/fstab
mkdir -p /root/.lotus
mount /dev/xvdb /root/.lotus
UUID=$(lsblk /dev/xvdb -nr -o UUID)
echo "UUID=${UUID} /root/.lotus xfs defaults 0 0" >> /etc/fstab

echo "Initial script started."

add-apt-repository ppa:longsleep/golang-backports && apt-get update -y && apt-get install -yy golang-go gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev
echo "Apps set installed."

echo "Clonning Filecoin repo"
git clone https://github.com/filecoin-project/lotus.git /home/ubuntu/lotus
cd /home/ubuntu/lotus
git checkout $VERSION
echo "Repo cloned"

echo "Building Lotus..."
make clean all install install-services
echo "Lotus has been built. Starting node..."
systemctl daemon-reload && systemctl enable lotus-daemon && systemctl restart lotus-daemon
echo "Done. Started node"

if [ "$SNAPSHOT_URL" != "" ]; then
  echo "Sleeping 60s and then stopping node to import snapshot"
  sleep 60 && systemctl stop lotus-daemon
  echo "Downloading snapshot..."
  wget -O /home/ubuntu/chain.car $SNAPSHOT_URL
  echo "Done. Importing snapshot..."
  /usr/local/bin/lotus daemon --halt-after-import --import-chain /home/ubuntu/chain.car
  echo "Imported. Starting node to sync..." && systemctl restart lotus-daemon
fi

set +eE
while true; do
       echo "Checking node sync status..."
       /usr/local/bin/lotus sync wait && break
       echo "Not synced yet, retrying..."
       sleep 60s
done
set -eE

echo "Node launched. Script finished. Please, check the log above for any errors that might occur during the installation."
