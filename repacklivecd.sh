#!/bin/sh
mount --bind /dev chroot/dev

cp /etc/hosts chroot/etc/hosts && \
cp /etc/resolv.conf chroot/etc/resolv.conf && \
cp /etc/apt/sources.list chroot/etc/apt/sources.list

cat << EOF | chroot chroot /bin/sh
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C
apt-get update
apt-get install --yes dbus
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 12345678
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl

apt-get install --yes ubuntu-standard casper lupin-casper
apt-get install --yes discover laptop-detect os-prober
apt-get install --no-install-recommends network-manager

rm /var/lib/dbus/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/*
rm /etc/resolv.conf
umount -lf /proc
umount -lf /sys
umount -lf /dev/pts
exit
EOF

umount chroot/dev

apt-get install --yes syslinux squashfs-tools genisoimage

mksquashfs chroot image/casper/filesystem.squashfs && \
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

cd image && mkisofs -r -V "$IMAGE_NAME" \
-cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
-boot-load-size 4 -boot-info-table -o ../ubuntu-remix.iso . && cd .. && mv ubuntu-remix.iso /macos/
