#!/bin/bash
set -xeE

install_config() {

mkdir -p /root/.lotus

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
    [ ! -d "/root/lotus" ] && git clone https://github.com/filecoin-project/lotus.git /root/lotus
    cd /root/lotus
    git fetch
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
      /usr/local/bin/lotus daemon --halt-after-import --import-chain /root/chain.car || true
      echo ">>> Imported. Starting node to sync..."
      systemctl restart lotus-daemon
      echo ">>> Node started."
    else
      echo ">> Snapshot does not exist."
    fi
    
    set +eE
    while /bin/true; do
	/usr/local/bin/lotus sync status
	sleep 60s
    done &

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
    mv ipfs /usr/bin/ 
    chmod a+x /usr/bin/ipfs
    echo ">> Installed. Installing SystemD configs..."
    wget -O /etc/systemd/system/ipfs.service  https://raw.githubusercontent.com/ipfs/go-ipfs/master/misc/systemd/ipfs.service
    sed -e s/Environment=IPFS_PATH=\"\${HOME}\"//g -i /etc/systemd/system/ipfs.service
    echo ">> Installed. Reloading SystemD..."
    systemctl daemon-reload
    echo ">> Reloaded. Creating ipfs user..."
    id -u ipfs &>/dev/null || useradd -m ipfs
    echo ">> Added. Running and enabling IPFS node via SystemD..."
    systemctl enable ipfs.service && systemctl start ipfs.service
    echo ">> Done."
    echo "> IPFS node installed."
    cd /root
}

install_powergate() {

    echo "> Installing the Textile Powergate..."
    cd /root
    echo ">> Clonning the Powergate repo..."
    [ ! -d "/root/powergate" ] && git clone https://github.com/textileio/powergate /root/powergate
    echo ">> Cloned. Building Powergate..."
    cd /root/powergate
    make build-powd
    cp /root/go/bin/powd /usr/local/bin/powd
    echo ">> Built. Installing SystemD service..."

cat <<EOF > /etc/systemd/system/powergate.service
[Unit]
Description=This is the template of simple SystemD service of Powergate applicaton
Requires=lotus-daemon.service
Requires=ipfs.service

[Service]
ExecStart=/usr/local/bin/powd --lotustokenfile /root/.lotus/token
WorkingDirectory=/root/powergate/iplocation/maxmind

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

echo "> Updating apps and installing deps"
add-apt-repository ppa:longsleep/golang-backports && apt-get update -y && apt-get install -yy make golang-go gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev && apt-get dist-upgrade -y
echo "> Apps set installed."

install_config
install_node
install_ipfs
install_powergate

systemctl status lotus-daemon
systemctl status ipfs
systemctl status powergate || true # Workaround since powergate supports only latest network

echo "Node launched. Script finished. Please, check the log above for any errors that might occur during the installation."
