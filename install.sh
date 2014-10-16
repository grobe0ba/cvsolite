#!/bin/sh

IDIR=$(pwd)

if [ -z "$1" ];
then
    echo "Usage: $0 [public key]"
    exit 255
fi

pkg install -y cvs sudo

cp $IDIR/cvsshell /usr/local/sbin/cvsshell
chmod -R 755 /usr/local/sbin/cvsshell

echo /usr/local/sbin/cvsshell >> /etc/shells

patch -R /etc/ssh/sshd_config < sshd_config.patch
patch -R /etc/pam.d/sshd < sshd.patch
service sshd restart

pw useradd anoncvs -h - -d /tmp
pw usermod anoncvs -w none
pw useradd config -m -g anoncvs -s /usr/local/sbin/cvsshell -h -

echo "root ALL=(ALL:ALL) NOPASSWD: ALL" >> /usr/local/etc/sudoers
echo "config ALL=(ALL:ALL) NOPASSWD: ALL" >> /usr/local/etc/sudoers

cvs -d /cvs init
chown -R config:anoncvs /cvs
chmod -R 775 /cvs

cd /tmp
mkdir keys
cd keys
echo "$1" > authorized_keys
cvs -d /cvs import -m'Initial import' keys config v1

cd /tmp
rm -rf /tmp/keys

mkdir config
cp $IDIR/cvs-config .
touch userlist
cat >sec_repos <<EOF
config
keys
EOF
chmod -R 755 cvs-config
cvs -d /cvs import -m'Initial import' config config v1
cd /tmp
rm -rf /tmp/config

chown -R config:anoncvs /cvs
chmod -R 775 /cvs/CVSROOT

mkdir /home/config/.ssh
chown -R config /home/config/.ssh
chmod -R 700 /home/config/.ssh

cd /home/config
sudo -u config cvs -d /cvs co -P config
sudo -u config cvs -d /cvs co -P keys
sudo -u config ln -s /home/config/keys/authorized_keys /home/config/.ssh/authorized_keys
