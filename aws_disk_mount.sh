set -xeE

echo "Disk mount script started"
echo "> Creating file system..."

set +eE
while true; do
  mkfs.xfs -f /dev/xvdb && break
  echo ">> Error. Sleeping 10s and then retrying..."
  sleep 10s
done

echo "> Created. Creating directory in /root/.lotus and mounting disk there..."
mkdir -p /root/.lotus
mount /dev/xvdb /root/.lotus
echo "> Done. Adding entry to fstab..."
UUID=$(lsblk /dev/xvdb -nr -o UUID)
echo "UUID=${UUID} /root/.lotus xfs defaults 0 0" >> /etc/fstab
echo "> Added."
echo "Disk mount script finished."
