FROM debian

RUN apt-get update \
    && apt-get install -y debootstrap

COPY deboot.sh .

ENTRYPOINT [ "./deboot.sh" ]

# RUN debootstrap --arch=armel --include=openssh-server stretch /chroots/stretch-armel http://ftp.debian.org/debian/ \
#     && tar cf /chroots/stretch-armel.tar -C /chroots/ stretch-armel \
#     && rm -rf /chroots/stretch-armel

# # tar xf /chroots/stretch-armel.tar -C /tmp

# RUN debootstrap --arch=armel --include=openssh-server jessie /chroots/jessie-armel http://ftp.debian.org/debian/ \
#     && tar cf /chroots/jessie-armel.tar -C /chroots/ jessie-armel \
#     && rm -rf /chroots/jessie-armel

# # tar xf /chroots/jessie-armel.tar -C /tmp

# RUN debootstrap --arch=armel --include=openssh-server squeeze /chroots/squeeze-armel http://archive.debian.org/debian/ \
#     && tar cf /chroots/squeeze-armel.tar -C /chroots/ squeeze-armel \
#     && rm -rf /chroots/squeeze-armel

# # tar xf /chroots/squeeze-armel.tar -C /tmp

# RUN debootstrap --arch=armel --include=openssh-server wheezy /chroots/wheezy-armel http://archive.debian.org/debian/ \
#     && tar cf /chroots/wheezy-armel.tar -C /chroots/ wheezy-armel \
#     && rm -rf /chroots/wheezy-armel

# # tar xf /chroots/wheezy-armel.tar -C /tmp

# ENTRYPOINT [ "sh", "-c", "cp -r /chroots/* /dist" ]
