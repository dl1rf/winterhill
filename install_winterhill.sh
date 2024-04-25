#!/bin/bash

# WinterHill 3v20 install file
# G8GKQ 6 Mar 2021
# DL1RF 17 Apr 2024

# Winterhill for a 1920 x 1080 screen

# force to users $HOME directory
cd $HOME

# setup the log file
LOGFILE=$HOME/whinstall.log

# log install start message
echo "" | tee -a $LOGFILE
echo "INSTALL WinterHill: started $(date -u)" | tee -a $LOGFILE

# Check which source needs to be loaded
GIT_SRC="BritishAmateurTelevisionClub"
GIT_SRC_FILE=".wh_gitsrc"

if [ "$1" == "-d" ]; then
  GIT_SRC="dl1rf";       # DL1RF
  #GIT_SRC="tomvdb";     # ZR6TG
  #GIT_SRC="davecrump";  # G8GKQ
  #GIT_SRC="foxcube";    # G4EWJ
  echo "INSTALL WinterHill: Installing ${GIT_SRC} development version of WinterHill" | tee -a $LOGFILE
elif [ "$1" == "-u" -a ! -z "$2" ]; then
  GIT_SRC="$2"
  echo "WARNING: Installing ${GIT_SRC} development version, press enter to continue or 'q' to quit."
  read -n1 -r -s key;
  if [ $key == q ]; then
    echo "INSTALL WinterHill: Aborted by user" | tee -a $LOGFILE
    echo "INSTALL WinterHill: exit" | tee -a $LOGFILE
    exit
  fi
  echo "INSTALL WinterHill: Installing ${GIT_SRC} development version of WinterHill" | tee -a $LOGFILE
else
  echo "INSTALL WinterHill: Installing BATC Production version of WinterHill" | tee -a $LOGFILE
fi

# detect system
echo "INSTALL WinterHill: perform system detection" | tee -a $LOGFILE

if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_NAME=$PRETTY_NAME
  OS_VERSION_ID=$VERSION_ID
  OS_VERSION_CODENAME=$VERSION_CODENAME
  ARCH=$(uname -m)
  echo "INSTALL WinterHill: system detected: $OS_NAME $ARCH" | tee -a $LOGFILE
else
  echo "INSTALL WinterHill: Error: canot detect system" | tee -a $LOGFILE
  echo "INSTALL WinterHill:        File '/etc/os-release' not found" | tee -a $LOGFILE
  echo "INSTALL WinterHill: exit" | tee -a $LOGFILE
  exit
fi

# check if system is supported
# supported systems:
#     Raspbian GNU/Linux 10 (buster) 32 and 64 Bit
if [ "$OS_NAME" == "Raspbian GNU/Linux 10 (buster)" ]; then
  echo "INSTALL WinterHill: $OS_NAME supported" | tee -a $LOGFILE
elif [ "$OS_NAME" == "Debian GNU/Linux 10 (buster)" ]; then
  echo "INSTALL WinterHill: $OS_NAME supported" | tee -a $LOGFILE
else
  echo "INSTALL WinterHill: $OS_NAME not supported" | tee -a $LOGFILE
  echo "INSTALL WinterHill: exit" | tee -a $LOGFILE
  exit
fi

# Disabling the raspberry ssh password warning
if [ -f /etc/xdg/lxsession/LXDE-pi/sshpwd.sh ]; then
  echo "INSTALL WinterHill: Remove the raspberry ssh password warning" | tee -a $LOGFILE
  sudo mv /etc/xdg/lxsession/LXDE-pi/sshpwd.sh /etc/xdg/lxsession/LXDE-pi/sshpwd.sh.old
fi

# Load required packages
echo "INSTALL WinterHill: Loading required packages" | tee -a $LOGFILE
sudo apt-get -y install xdotool xterm raspberrypi-kernel-headers cmake | tee -a $LOGFILE

# search systems 'config.txt' file
echo "INSTALL WinterHill: search systems 'config.txt' file" | tee -a $LOGFILE
if [ -e /boot/firmware/config.txt ] ; then
  FIRMWARE=/firmware
else
  FIRMWARE=
fi

CONFIG_DIR=/boot${FIRMWARE}

echo "INSTALL WinterHill: use '$CONFIG_DIR/config.txt' file" | tee -a $LOGFILE

# save systems 'config.txt' file to 'config.txt.orig' but only the first time
if [ ! -f $CONFIG_DIR/config.txt.orig ]; then
  echo "INSTALL WinterHill: Save '$CONFIG_DIR/config.txt' file as '$CONFIG_DIR/config.txt.orig'" | tee -a $LOGFILE
  sudo cp $CONFIG_DIR/config.txt $CONFIG_DIR/config.txt.orig
fi

# Put the Desktop Toolbar at the bottom of the screen
echo "INSTALL WinterHill: Put the Desktop Toolbar at the bottom of the screen" | tee -a $LOGFILE
sed -i "s/edge=top/edge=bottom/" $HOME/.config/lxpanel/LXDE-pi/panels/panel

# Remove desktop icons
echo "INSTALL WinterHill: Remove icons from Desktop" | tee -a $LOGFILE
sed -i "s/show_documents=1/show_documents=0/" $HOME/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
sed -i "s/show_trash=1/show_trash=0/" $HOME/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
sed -i "s/show_mounts=1/show_mounts=0/" $HOME/.config/pcmanfm/LXDE-pi/desktop-items-0.conf

# Check gpu memory allocation setting in 'config.txt'
echo "INSTALL WinterHill: Check if gpu_mem= parameter is present" | tee -a $LOGFILE
grep -q "^gpu_mem=" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: Found. Check for gpu_mem=128" | tee -a $LOGFILE
  grep -q "^gpu_mem=128" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Nothing to do" | tee -a $LOGFILE
  else
    echo "INSTALL WinterHill: Change gpu_mem=... to gpu_mem=128" | tee -a $LOGFILE
    sudo sed -i "s/gpu_mem=.*/gpu_mem=128/" $CONFIG_DIR/config.txt
  fi
else
  echo "INSTALL WinterHill: Not Found. Check for #gpu_mem=..." | tee -a $LOGFILE
  grep -q "^#gpu_mem=" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Change to gpu_mem=128" | tee -a $LOGFILE
    sudo sed -i "s/#gpu_mem=.*/gpu_mem=128/" $CONFIG_DIR/config.txt
  else
    echo "INSTALL WinterHill: Not found. Add gpu_mem=128" | tee -a $LOGFILE
    sudo sed -i "\$a\\\n# Increase GPU Memory\ngpu_mem=128\n" $CONFIG_DIR/config.txt
  fi
fi

# Check force_turbo setting in 'config.txt'
echo "INSTALL WinterHill: Check force_turbo= for constant spi speed" | tee -a $LOGFILE
grep -q "^force_turbo=" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: Found. Check for force_turbo=1" | tee -a $LOGFILE
  grep -q "^force_turbo=1" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Nothing to do" | tee -a $LOGFILE
  else
    echo "INSTALL WinterHill: Change force_turbo=... to force_turbo=1" | tee -a $LOGFILE
    sudo sed -i "s/force_turbo=.*/force_turbo=1/" $CONFIG_DIR/config.txt
  fi
else
  echo "INSTALL WinterHill: Not found. Check for #force_turbo=..." | tee -a $LOGFILE
  grep -q "^#force_turbo=" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Change #force_turbo=... to force_turbo=1" | tee -a $LOGFILE
    sudo sed -i "s/#force_turbo=.*/force_turbo=1/" $CONFIG_DIR/config.txt
  else
    echo "INSTALL WinterHill: Not Found. Add force_turbo=1" | tee -a $LOGFILE
    sudo sed -i "\$a\\\n# Set force_turbo for constant spi speed\nforce_turbo=1\n" $CONFIG_DIR/config.txt
  fi
fi

# Check dtparam=spi parameter setting in 'config.txt'
echo "INSTALL WinterHill: Check if dtparam=spi= parameter is present" | tee -a $LOGFILE
grep -q "^dtparam=spi=" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: Found: Check for dtparam=spi=off" | tee -a $LOGFILE
  grep -q "^dtparam=spi=off" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Nothing to do" | tee -a $LOGFILE
  else
    echo "INSTALL WinterHill: Not found. Change dtparam=spi=... to dtparam=spi=off" | tee -a $LOGFILE
    sudo sed -i "s/dtparam=spi=on/dtparam=spi=off/" $CONFIG_DIR/config.txt
  fi
else
  echo "INSTALL WinterHill: Not found. Check for #dtparam=spi=..." | tee -a $LOGFILE
  grep -q "^#dtparam=spi=" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Change #dtparam=spi=... to dtparam=spi=off" | tee -a $LOGFILE
    sudo sed -i "s/#dtparam=spi=.*/dtparam=spi=off/" $CONFIG_DIR/config.txt
  else
    echo "INSTALL WinterHill: Not found. Add dtparam=spi=off" | tee -a $LOGFILE
    sudo sed -i "\$a\\\n# Set needed SPI parameters\ndtparam=spi=off\n" $CONFIG_DIR/config.txt
  fi
fi

# Check dtoverlay=spi5-1cs parameter setting in 'config.txt'
echo "INSTALL WinterHill: Check if dtoverlay=spi5-1cs parameter is present" | tee -a $LOGFILE
grep -q "^dtoverlay=spi5-1cs" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: Found. Nothing to do" | tee -a $LOGFILE
else
  echo "INSTALL WinterHill: Not found. Check for #dtoverlay=spi5-1cs" | tee -a $LOGFILE
  grep -q "^#dtoverlay=spi5-1cs" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Change #dtoverlay=spi5-1cs... to dtoverlay=spi5-1cs" | tee -a $LOGFILE
    sudo sed -i "s/#dtoverlay=spi5-1cs/dtoverlay=spi5-1cs/" $CONFIG_DIR/config.txt
  else
    echo "INSTALL WinterHill: Not found. Add dtoverlay=spi5-1cs setting" | tee -a $LOGFILE
    sudo sed -i "s/dtparam=spi=off/dtparam=spi=off\ndtoverlay=spi5-1cs/" $CONFIG_DIR/config.txt
  fi
fi

# Check dtparam=i2c_arm parameter setting in 'config.txt'
echo "INSTALL WinterHill: Check if dtparam=i2c_arm= parameter is present" | tee -a $LOGFILE
grep -q "^dtparam=i2c_arm=" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: Found. Check for dtparam=i2c_arm=on" | tee -a $LOGFILE
  grep -q "^dtparam=i2c_arm=on" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Nothing to do" | tee -a $LOGFILE
  else
    echo "INSTALL WinterHill: Not found. Change dtparam=i2c_arm=... to dtparam=i2c_arm=on" | tee -a $LOGFILE
    sudo sed -i "s/dtparam=i2c_arm=.*/dtparam=i2c_arm=on/" $CONFIG_DIR/config.txt
  fi
else
  echo "INSTALL WinterHill: Not found. Check for #dtparam=i2c_arm=..." | tee -a $LOGFILE
  grep -q "^#dtparam=i2c_arm=" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Change #dtparam=i2c_arm=... to dtparam=i2c_arm=on" | tee -a $LOGFILE
    sudo sed -i "s/#dtparam=i2c_arm=.*/dtparam=i2c_arm=on/" $CONFIG_DIR/config.txt
  else
    echo "INSTALL WinterHill: Not Found. Add dtparam=i2c_arm=on" | tee -a $LOGFILE
    sudo sed -i "\$a\\\ndtparam=i2c_arm=on\n" $CONFIG_DIR/config.txt
  fi
fi

# Check dtoverlay=vc4-fkms-v3d parameter setting in 'config.txt'
echo "INSTALL WinterHill: Check dtoverlay=vc4-fkms-v3d parameter setting" | tee -a $LOGFILE
grep -q "^dtoverlay=vc4-fkms-v3d" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: change dtoverlay=vc4-fkms-v3d... to #dtoverlay=vc4-fkms-v3d" | tee -a $LOGFILE
  sudo sed -i "s/^dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/" $CONFIG_DIR/config.txt
else
  echo "INSTALL WinterHill: Not Found. Nothing to do" | tee -a $LOGFILE
fi

# Check dtoverlay=vc4-kms-v3d parameter setting in 'config.txt'
echo "INSTALL WinterHill: Check dtoverlay=vc4-kms-v3d parameter setting" | tee -a $LOGFILE
grep -q "^dtoverlay=vc4-kms-v3d" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: change dtoverlay=vc4-kms-v3d... to #dtoverlay=vc4-kms-v3d" | tee -a $LOGFILE
  sudo sed -i "s/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/" $CONFIG_DIR/config.txt
else
  echo "INSTALL WinterHill: Not Found. Nothing to do" | tee -a $LOGFILE
fi

# Check hdmi_force_hotplug parameter setting in 'config.txt'
echo "INSTALL WinterHill: Check if hdmi_force_hotplug= parameter is present" | tee -a $LOGFILE
grep -q "^hdmi_force_hotplug=" $CONFIG_DIR/config.txt
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: Found, Check for hdmi_force_hotplug=1" | tee -a $LOGFILE
  grep -q "^hdmi_force_hotplug=1" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Nothing to do" | tee -a $LOGFILE
  else
    echo "INSTALL WinterHill: Not found. Change hdmi_force_hotplug=... to hdmi_force_hotplug=1" | tee -a $LOGFILE
    sudo sed -i "s/hdmi_force_hotplug=.*/hdmi_force_hotplug=1/" $CONFIG_DIR/config.txt
  fi
else
  echo "INSTALL WinterHill: Not found. Check for #hdmi_force_hotplug=" | tee -a $LOGFILE
  grep -q "^#hdmi_force_hotplug=" $CONFIG_DIR/config.txt
  if [ $? == 0 ]; then
    echo "INSTALL WinterHill: Found. Change #hdmi_force_hotplug=... to hdmi_force_hotplug=1" | tee -a $LOGFILE
    sudo sed -i "s/#hdmi_force_hotplug=.*/hdmi_force_hotplug=1/" $CONFIG_DIR/config.txt
  else
    echo "INSTALL WinterHill: Not found. Add hdmi_force_hotplug=1" | tee -a $LOGFILE
    sudo sed -i "\$a\\\n# Set needed hdmi_force_hotplug parameters\nhdmi_force_hotplug=1\n" $CONFIG_DIR/config.txt
  fi
fi

echo "INSTALL WinterHill: Download & Install Dependencies for WinterHill Software" | tee -a $LOGFILE
if [ ! -f /usr/local/lib/libwebsockets.so ]; then
  git clone https://github.com/warmcat/libwebsockets.git | tee -a $LOGFILE
  cd $HOME/libwebsockets/
  git checkout 2445793d15af39fac9ce527bb28ffd42a974bf4f | tee -a $LOGFILE
  mkdir build
  cd $HOME/libwebsockets/build/
  cmake -DLWS_WITH_SSL=0 .. 2>&1 | tee -a $LOGFILE
  make 2>&1 | tee -a $LOGFILE
  sudo make install 2>&1 | tee -a $LOGFILE
  sudo ldconfig 2>&1 | tee -a $LOGFILE
else
  echo "INSTALL WinterHill: Already installed." | tee -a $LOGFILE
fi

# Download the WinterHill Software
echo "INSTALL WinterHill: Download the WinterHill Software" | tee -a $LOGFILE
cd $HOME
if [ -e $HOME/winterhill ] ; then
  rm -rf winterhill
fi
if [ -e $HOME/main.zip ] ; then
  rm main.zip
fi
wget https://github.com/${GIT_SRC}/winterhill/archive/main.zip
unzip -o main.zip | tee -a $LOGFILE
mv winterhill-main winterhill
rm main.zip

BUILD_VERSION=$(<$HOME/winterhill/latest_version.txt)
echo "INSTALL WinterHill: Build started version $BUILD_VERSION" | tee -a $LOGFILE

echo "INSTALL WinterHill: Building spi driver for install" | tee -a $LOGFILE
cd $HOME/winterhill/whsource-3v20/whdriver-3v20
make 2>&1 | tee -a $LOGFILE
if [ ! -f ./whdriver-3v20.ko ]; then
  echo "INSTALL WinterHill: Failed to build the WinterHill Driver" | tee -a $LOGFILE
  exit
fi

cat /proc/modules | grep -q "whdriver_3v20"
if [ $? == 0 ]; then
  sudo rmmod whdriver-3v20.ko
fi

sudo insmod whdriver-3v20.ko
if [ $? != 0 ]; then
  echo "INSTALL WinterHill: Failed to load WinterHill Driver" | tee -a $LOGFILE
  exit
fi

cat /proc/modules | grep -q "whdriver_3v20"
if [ $? == 0 ]; then
  echo "INSTALL WinterHill: Successfully loaded  WinterHill Driver" | tee -a $LOGFILE
else
  echo "INSTALL WinterHill: Failed to find previously loaded  WinterHill Driver" | tee -a $LOGFILE
  exit
fi
cd $HOME

grep -q "whdriver-3v20" /etc/rc.local
if [ $? != 0 ]; then
  echo "INSTALL WinterHill: Set up to load the spi driver at boot" | tee -a $LOGFILE
  sudo sed -i "/^exit 0/c\cd $HOME/winterhill/whsource-3v20/whdriver-3v20\nsudo insmod whdriver-3v20.ko\nexit 0" /etc/rc.local
fi

echo "INSTALL WinterHill: Building the main WinterHill Application" | tee -a $LOGFILE
cd $HOME/winterhill/whsource-3v20/whmain-3v20
make 2>&1 | tee -a $LOGFILE
if [ ! -f ./winterhill-3v20 ]; then
  echo "INSTALL WinterHill: Failed to build the WinterHill Application" | tee -a $LOGFILE
  exit
fi
cp winterhill-3v20 $HOME/winterhill/RPi-3v20/winterhill-3v20
cd $HOME

echo "INSTALL WinterHill: Building the PIC Programmer" | tee -a $LOGFILE
cd $HOME/winterhill/whsource-3v20/whpicprog-3v20
make 2>&1 | tee -a $LOGFILE
if [ ! -f ./whpicprog-3v20 ]; then
  echo "INSTALL WinterHill: Failed to build the PIC Programmer" | tee -a $LOGFILE
  exit
fi
cp whpicprog-3v20 $HOME/winterhill/PIC-3v20/whpicprog-3v20
cd $HOME

# Copy the shortcuts to the desktop
echo "INSTALL WinterHill: Copy the shortcuts to the desktop" | tee -a $LOGFILE
cd $HOME/winterhill/configs
cp templates/Kill_WH           Kill_WH
cp templates/WH_Local          WH_Local
cp templates/WH_Anyhub         WH_Anyhub
cp templates/WH_Anywhere       WH_Anywhere
cp templates/WH_Multihub       WH_Multihub
cp templates/WH_Fixed          WH_Fixed
cp templates/PIC_Prog          PIC_Prog
cp templates/Show_IP           Show_IP
cp templates/Shutdown          Shutdown
cp templates/Check_for_Update  Check_for_Update
cp templates/startup.desktop   startup.desktop

sed -i "s|<HOME>|$HOME|" Kill_WH
sed -i "s|<HOME>|$HOME|" WH_Local
sed -i "s|<HOME>|$HOME|" WH_Anyhub
sed -i "s|<HOME>|$HOME|" WH_Anywhere
sed -i "s|<HOME>|$HOME|" WH_Multihub
sed -i "s|<HOME>|$HOME|" WH_Fixed
sed -i "s|<HOME>|$HOME|" PIC_Prog
sed -i "s|<HOME>|$HOME|" Show_IP
sed -i "s|<HOME>|$HOME|" Shutdown
sed -i "s|<HOME>|$HOME|" Check_for_Update
sed -i "s|<HOME>|$HOME|" startup.desktop
cd $HOME

cp $HOME/winterhill/configs/Kill_WH           $HOME/Desktop/Kill_WH
cp $HOME/winterhill/configs/WH_Local          $HOME/Desktop/WH_Local
cp $HOME/winterhill/configs/WH_Anyhub         $HOME/Desktop/WH_Anyhub
cp $HOME/winterhill/configs/WH_Anywhere       $HOME/Desktop/WH_Anywhere
cp $HOME/winterhill/configs/WH_Multihub       $HOME/Desktop/WH_Multihub
cp $HOME/winterhill/configs/WH_Fixed          $HOME/Desktop/WH_Fixed
cp $HOME/winterhill/configs/PIC_Prog          $HOME/Desktop/PIC_Prog
cp $HOME/winterhill/configs/Show_IP           $HOME/Desktop/Show_IP
cp $HOME/winterhill/configs/Shutdown          $HOME/Desktop/Shutdown
cp $HOME/winterhill/configs/Check_for_Update  $HOME/Desktop/Check_for_Update

# Enable Autostart for the selected WinterHill mode at boot
echo "INSTALL WinterHill: Enable Autostart for the selected WinterHill mode at boot" | tee -a $LOGFILE
if [ ! -e $HOME/.config/autostart ] ; then
  echo "INSTALL WinterHill: Create Autostart directory" | tee -a $LOGFILE
  mkdir $HOME/.config/autostart
fi
cp $HOME/winterhill/configs/startup.desktop $HOME/.config/autostart/startup.desktop

# Save git source used
echo "INSTALL WinterHill: Save git source '${GIT_SRC}' to $HOME/${GIT_SRC_FILE}" | tee -a $LOGFILE
echo "${GIT_SRC}" > $HOME/${GIT_SRC_FILE}

echo "" | tee -a $LOGFILE
echo "INSTALL WinterHill: SD Card Serial:" | tee -a $LOGFILE
cat /sys/block/mmcblk0/device/cid | tee -a $LOGFILE

# Reboot
echo | tee -a $LOGFILE
echo "INSTALL WinterHill: ----- Complete.  Rebooting -----" | tee -a $LOGFILE
echo "INSTALL WinterHill: Reached end of install script" | tee -a $LOGFILE

echo "INSTALL WinterHill: Rebooting now" | tee -a $LOGFILE

sleep 5

sudo reboot now
exit

