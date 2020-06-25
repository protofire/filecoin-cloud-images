set -xeE

echo "Disk mount script started"
echo "> Creating file system..."

set +eE

TO_MOUNT=/dev/sdc

while true; do
  flag=0
  for DISK in /dev/sd?; do
	echo ">> Trying to mount $DISK..."
	TO_MOUNT=$DISK
	DISK_TYPE=$(blkid -o value -s TYPE $DISK)
	if [[ "$DISK_TYPE" == "xfs" ]]; then
		echo ">>> Existing disk, mounting..."
		flag=1
		break
	else
  		mkfs.xfs $DISK && echo ">>> Mounted." && flag=1 && break
	fi
	echo ">>> Error. Sleeping 10s and then retrying..."
	sleep 10s
  done
  if [[ $flag -eq 1 ]]; then
	  break
  fi
done

set -eE
echo "> Created. Creating directory in /root/.lotus and mounting disk there..."
mkdir -p /root/.lotus
mount $TO_MOUNT /root/.lotus
echo "> Done. Adding entry to fstab..."
UUID=$(lsblk $TO_MOUNT -nr -o UUID)
echo "UUID=${UUID} /root/.lotus xfs defaults 0 0" >> /etc/fstab
echo "> Added."
echo "Disk mount script finished."
