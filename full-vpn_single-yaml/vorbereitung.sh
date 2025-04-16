apt-get update && apt-get install nfs-common -y
mkdir /mnt/media
echo '#nfs' >> /etc/fstab
echo '10.0.10.10:/volume3/PlexMediaServer /mnt/media nfs auto,defaults,nofail 0 0' >> /etc/fstab