Samba
-----

https://ubuntu.com/tutorials/install-and-configure-samba#1-overview

    sudo apt update
    sudo apt install -y samba

    sudo nano /etc/samba/smb.conf

    [Volume_1]
        comment = Volume 1
        path = /mnt/HD/HD_a2
        read only = no
        public = no
        browsable = yes
        oplocks = no
        map archive = no
        read list = 
        write list = "@Administrators"
        invalid users = "nobody"
        valid users = "@Administrators"


    [Volume_2]
        comment = Volume 2
        path = /mnt/HD/HD_b2
        read only = no
        public = no
        browsable = yes
        oplocks = no
        map archive = no
        read list = 
        write list = "@Administrators"
        invalid users = "nobody"
        valid users = "@Administrators"

    sudo service smbd restart
    # sudo ufw allow samba

    sudo smbpasswd -a dlink
    