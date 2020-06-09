#!/bin/bash
set -xeE

mount_drive() {
    mkfs.xfs -f /dev/xvdb
    # Mound disk and add automount entry in /etc/fstab
    mkdir -p /root/.lotus
    mount /dev/xvdb /root/.lotus
    UUID=$(lsblk /dev/xvdb -nr -o UUID)
    echo "UUID=${UUID} /root/.lotus xfs defaults 0 0" >> /etc/fstab
}

install_config() {

cat << EOF > /root/.lotus/config.toml

[API]
  ListenAddress = "/ip4/0.0.0.0/tcp/1234/http"
  Timeout = "60s"

[Libp2p]
  ListenAddresses = ["/ip4/0.0.0.0/tcp/1235", "/ip6/::/tcp/1235"]

[Client]
  UseIpfs = true
  IpfsUseForRetrieval = true
  IpfsMAddr = "/dns4/ipfs/tcp/5001"
EOF

}

install_node() {

    echo "> Installing Lotus node..."
    echo ">> Clonning Filecoin repo..."
    git clone https://github.com/filecoin-project/lotus.git /root/lotus
    cd /root/lotus
    git checkout $VERSION
    echo ">> Repo cloned"
    
    echo ">> Building Lotus..."
    make clean all install install-services
    echo ">> Lotus has been built. Starting node..."
    systemctl daemon-reload && systemctl enable lotus-daemon && systemctl restart lotus-daemon
    echo ">> Node started."
    
    echo ">> Importing snapshot if it exists..."
    if [ "$SNAPSHOT_URL" != "" ]; then
      echo ">>> Snapshot URL is set"
      echo ">>> Sleeping 60s and then stopping node to import snapshot"
      sleep 60 && systemctl stop lotus-daemon
      echo ">>> Attempting to download snapshot..."
      wget -O /root/chain.car $SNAPSHOT_URL
      echo ">>> Done. Importing snapshot. This might take a while..."
      /usr/local/bin/lotus daemon --halt-after-import --import-chain /root/chain.car
      echo ">>> Imported. Starting node to sync..."
      systemctl restart lotus-daemon
      echo ">>> Node started."
    fi
    echo ">> Snapshot imported"
    
    set +eE
    while true; do
           echo ">> Checking node sync status..."
           /usr/local/bin/lotus sync wait && break
           echo ">> Not synced yet, retrying..."
           sleep 60s
    done
    set -eE
    
    echo "> Node is installed"

}

install_ipfs() {

    echo "> Installing the IPFS node..."
    echo ">> Downloading latest release..."
    cd /root
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/ipfs/go-ipfs/releases/latest | jq .tag_name -r)
    wget https://github.com/ipfs/go-ipfs/releases/download/${LATEST_RELEASE}/go-ipfs_${LATEST_RELEASE}_linux-amd64.tar.gz
    echo ">> Downloaded latest release. Unpacking..."
    tar -xzf go-ipfs_${LATEST_RELEASE}_linux-amd64.tar.gz
    echo ">> Unpacked. Installing IPFS..."
    cd /root/go-ipfs
    source install.sh
    echo ">> Installed. Installing SystemD configs..."
    wget -o /etc/systemd/system/ipfs.service  https://raw.githubusercontent.com/ipfs/go-ipfs/master/misc/systemd/ipfs.service
    mkdir -p /etc/systemd/system/ipfs.service.d/
    wget -o /etc/systemd/system/ipfs.service.d/ipfs-api.socket https://raw.githubusercontent.com/ipfs/go-ipfs/master/misc/systemd/ipfs-api.socket
    wget -o /etc/systemd/system/ipfs.service.d/ipfs-sysusers.conf https://raw.githubusercontent.com/ipfs/go-ipfs/master/misc/systemd/ipfs-sysusers.conf
    echo ">> Installed. Reloading SystemD..."
    systemctl daemon-reload
    echo ">> Reloaded. Running and enabling IPFS node via SystemD..."
    systemctl enable ipfs.service && systemctl start ipfs.service
    echo ">> Done."
    echo "> IPFS node installed."
    cd /root
}

install_powergate() {

    echo "> Installing the Textile Powergate..."
    cd /root
    echo ">> Clonning the Powergate repo..."
    git clone https://github.com/textileio/powergate /root/powergate
    cd /root/powergate
    echo ">> Cloned. Building Powergate..."
    GOBIN=/usr/local/bin/
    make build-powd
    echo ">> Built. Installing SystemD service..."

cat <<EOF > /etc/systemd/system/powergate.service
[Unit]
Description=This is the template of simple SystemD service of Powergate applicaton
Requires=lotus-daemon.service
Requires=ipfs.service

[Service]
ExecStart=/usr/local/bin/powd --lotustokenfile /root/.lotus/token

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload && systemctl enable powergate && systemctl start powergate
    echo ">> Service installed."
    echo "> Powergate installed."
    cd /root
}

####################################################################################
##################### MAIN FUNCTION ################################################
####################################################################################

echo "Initial script started."

mount_drive

echo "> Updating apps and installing deps"
add-apt-repository ppa:longsleep/golang-backports && apt-get update -y && apt-get install -yy golang-go gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev && apt-get dist-upgrade
echo "> Apps set installed."

install_config
install_node
install_ipfs
install_powergate

echo "Node launched. Script finished. Please, check the log above for any errors that might occur during the installation."
