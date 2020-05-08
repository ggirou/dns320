Run debian on DNS320
--------------------

- Firmwares and documentations: ftp://ftp.dlink.eu/Products/dns/dns-320/
- My firmware version: 2.03
- Wikis: http://dns323.kood.org/dns-320
- Linux kernel support: https://www.kernel.org/doc/html/latest/arm/marvel.html

With fun_plug
-------------

# Deboostrap debian

    docker-compose up deboot

## Debug/Testing

    docker-compose run deboot bash
    ./deboot.sh armel buster http://ftp.fr.debian.org/debian/ openssh-server


# Prepare USB key

## Format to ext2

    sudo parted -l
    sudo parted /dev/sda rm 1
    sudo parted -a optimal /dev/sda mkpart primary 0% 100%
    sudo mkfs -t ext2 /dev/sda1

## Extract Debian

    sudo mkdir -p /mnt/usb/
    sudo mount /dev/sda1 /mnt/usb/
    sudo tar xzf ~/buster-armel.final.tar.gz -C /mnt/usb/
    
# Serial boot

    screen -L /dev/tty.usbserial-AG0JNME1 115200  

At the Hit any key to stop autoboot prompt press space then 1

    Marvel>> printenv

------------------------------

With fun_plug
-------------

Limited by embedded linux kernel: 2.6.22.18  
-> Only Debian Squeeze is supported

# Prerequisites

## Build debian bootstrap

    docker-compose up

## USB Key

Format USB to ext3. Minimun 2Gb

# Copy files to `HD_a2`

# Connect with ssh

    ssh root@<nas_hostname>

> Password is `dlink`

## First things to do

Change root password:

    passwd

Update apt conf :

    echo 'deb http://archive.debian.org/debian squeeze-lts main' >> /etc/apt/sources.list
    echo 'Acquire::Check-Valid-Until false;' >> /etc/apt/apt.conf

Set your locales

    #{ echo export LANG=en_US.UTF-8; echo export LANGUAGE=en_US.UTF-8; echo export LC_ALL=en_US.UTF-8; } >> ~/.bashrc
    #source ~/.bashrc
    
    echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
    dpkg-reconfigure locales

Update apt GPG keys and update apt-cache:

    apt-key list | grep expired | cut -d'/' -f2 | cut -d' ' -f1 | xargs -l apt-key adv --recv-keys --keyserver keys.gnupg.net
    apt-get update

Install few packages:

    apt-get install -y --force-yes locales gnupg apt-transport-https ca-certificates curl nano
    # update-ca-certificates

# NFS

https://guide.ubuntu-fr.org/server/network-file-system.html

    apt-get install -y --force-yes install nfs-kernel-server
    echo "/mnt/HD/HD_a2 *(ro,sync,no_subtree_check)" >> /etc/exports
    service nfs-kernel-server restart

# Openmediavault

https://openmediavault.readthedocs.io/en/5.x/installation/on_debian.html

    apt-get install --yes gnupg
    wget --no-check-certificate -O "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc" https://packages.openmediavault.org/public/archive.key
    apt-key add "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc"
    apt-get update
    apt-get install openmediavault-keyring openmediavault
    apt-get --yes --auto-remove --show-upgraded            --option Dpkg::Options::="--force-confdef"     --option DPkg::Options::="--force-confold"     install openmediavault-keyring openmediavault

# Quickly restart DNS320

    curl 'http://<nas_hostname>/cgi-bin/system_mgr.cgi' -H 'Cookie: username=admin' --data 'cmd=cgi_restart'
