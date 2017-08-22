#!/bin/bash

export LC_ALL=C

ERR='\033[0;31m'
INFO='\033[0;32m'
NC='\033[0m' # No Color

KERNEL=$(uname -r)


clear
WELCOME="These drivers will be compiled and installed:\n
- CAN driver (SocketCAN)\n
These software components will be installed:\n
- autoconf, libtool, unzip, libsocketcan, can-utils\n
Important: create a backup copy of the system before installation!\n
continue installation?"

if (whiptail --title "emPC-CX+ Installation Script" --yesno "$WELCOME" 20 60) then
    echo ""
else
    exit 0
fi

apt-get update -y
apt-get -y install bc build-essential unzip linux-headers-$(uname -r)


if [ ! -f "/lib/modules/$KERNEL/build" ]; then
 ln -s /usr/src/linux-headers-$KERNEL/ /lib/modules/$KERNEL/build
fi 

# get installed gcc version
GCCVERBACKUP=$(gcc --version | egrep -o '[0-9]+\.[0-9]+' | head -n 1)
# get gcc version of installed kernel
GCCVER=$(cat /proc/version | egrep -o 'gcc version [0-9]+\.[0-9]+' | egrep -o '[0-9.]+')


gcc --version | grep "$GCCVER" || (echo "$ERR Error: gcc $GCCVER not found! $NC"; exit 1);


rm -rf /tmp/empc-cxplus-linux-drivers
mkdir -p /tmp/empc-cxplus-linux-drivers
cd /tmp/empc-cxplus-linux-drivers


CPU=$(if uname -a | grep "x86_64" >/dev/null; then echo "x86_64"; else echo "x86"; fi)

# compile jhal driver
tar -xzvf /home/jhal.tar.gz
cd /tmp/empc-cxplus-linux-drivers/jhal
make driver

cd /tmp/empc-cxplus-linux-drivers

if [ ! -f "jhal/arch/$CPU/$KERNEL/jhal.ko" ]; then
 echo -e "$ERR Error: Installation failed! (driver module jhal build failed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (driver module jhal build failed)" 10 60
 exit 1
fi

/bin/cp -rf jhal/arch/$CPU/$KERNEL/jhal.ko /lib/modules/$KERNEL/kernel/drivers/misc/jhal.ko

# compile jtec_can driver
wget -nv https://github.com/janztec/empc-x-linux-drivers/raw/master/src/jtec_can.zip -O jtec_can.zip
unzip jtec_can.zip
cd jtec_can
make

if [ ! -f "jtec_can.ko" ]; then
 echo -e "$ERR Error: Installation failed! (driver module jtec_can build failed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (driver module jtec_can build failed)" 10 60
 exit 1
fi

/bin/cp -rf jtec_can.ko /lib/modules/$KERNEL/kernel/drivers/net/can/


depmod -a




# Install jtec_can init service
wget -nv https://raw.githubusercontent.com/janztec/empc-cxplus-linux-drivers/master/src/jtec_can -O /etc/init.d/jtec_can
if [ ! -f "/etc/init.d/jtec_can" ]; then
 echo -e "$ERR Error: Installation failed! (jtec_can not installed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (jtec_can not installed)" 10 60
 exit 1
fi

chmod 755 /etc/init.d/jtec_can
update-rc.d jtec_can defaults




wget -nv https://raw.githubusercontent.com/janztec/empc-cxplus-linux-drivers/master/scripts/empc-can-configbaudrate.sh -O /usr/bin/empc-can-configbaudrate.sh
if [ ! -f "/usr/bin/empc-can-configbaudrate.sh" ]; then
 echo -e "$ERR Error: Installation failed! (empc-can-configbaudrate not installed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (empc-can-configbaudrate not installed)" 10 60
 exit 1
fi

chmod 755 /usr/bin/empc-can-configbaudrate.sh
bash /usr/bin/empc-can-configbaudrate.sh


if [ ! -f "/usr/local/bin/cansend" ]; then
 if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "Third party SocketCan library and utilities\n\n- libsocketcan-0.0.10\n- can-utils\n - candump\n - cansend\n - cangen\n\ninstall?" 16 60) then

    apt-get -y install git
    apt-get -y install autoconf
    apt-get -y install libtool

    cd /usr/src/

    wget http://www.pengutronix.de/software/libsocketcan/download/libsocketcan-0.0.10.tar.bz2
    tar xvjf libsocketcan-0.0.10.tar.bz2
    rm -rf libsocketcan-0.0.10.tar.bz2
    cd libsocketcan-0.0.10
    ./configure && make && make install

    cd /usr/src/

    git clone https://github.com/linux-can/can-utils.git
    cd can-utils
    ./autogen.sh
    ./configure && make && make install

 fi
fi




cd /



if (whiptail --title "emPC-CX+ Installation Script" --yesno "Installation completed! reboot required\n\nreboot now?" 12 60) then

    reboot

fi
