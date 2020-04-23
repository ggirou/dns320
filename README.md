Run debian on DNS320
--------------------

# Build debian bootstrap

    docker-compose up

# Copy files to `HD_a2`

# Connect with ssh



# Some infos

    root@DNS320:~# dpkg --print-architecture
    armel

    root@DNS320:~# uname -a
    Linux DNS320 2.6.22.18 #23 Wed May 25 15:48:30 CST 2011 armv5tejl GNU/Linux

    root@DNS320:~# cat /proc/cpuinfo 
    Processor	: ARM926EJ-S rev 1 (v5l)
    BogoMIPS	: 791.34
    Features	: swp half thumb fastmult edsp 
    CPU implementer	: 0x56
    CPU architecture: 5TE
    CPU variant	: 0x2
    CPU part	: 0x131
    CPU revision	: 1
    Cache type	: write-back
    Cache clean	: cp15 c7 ops
    Cache lockdown	: format C
    Cache format	: Harvard
    I size		: 16384
    I assoc		: 4
    I line length	: 32
    I sets		: 128
    D size		: 16384
    D assoc		: 4
    D line length	: 32
    D sets		: 128

    Hardware	: Feroceon-KW
    Revision	: 0000
    Serial		: 0000000000000000
