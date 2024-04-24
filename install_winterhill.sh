#!/bin/bash

# WinterHill 3v20 install file
# G8GKQ 6 Mar 2021

# Winterhill for a 1920 x 1080 screen

# Check which source needs to be loaded
GIT_SRC="BritishAmateurTelevisionClub"
GIT_SRC_FILE=".wh_gitsrc"

if [ "$1" == "-d" ]; then
  GIT_SRC="dl1rf";       # DL1RF
  #GIT_SRC="tomvdb";     # ZR6TG
  #GIT_SRC="davecrump";  # G8GKQ
  #GIT_SRC="foxcube";    # G4EWJ
  echo
  echo "-------------------------------------------------------"
  echo "----- Installing development version of WinterHill-----"
  echo "-------------------------------------------------------"
elif [ "$1" == "-u" -a ! -z "$2" ]; then
  GIT_SRC="$2"
  echo
  echo "WARNING: Installing ${GIT_SRC} development version, press enter to continue or 'q' to quit."
  read -n1 -r -s key;
  if [[ $key == q ]]; then
    exit 1;
  fi
  echo "ok!";
else
  echo
  echo "------------------------------------------------------------"
  echo "----- Installing BATC Production version of WinterHill -----"
  echo "------------------------------------------------------------"
fi

cd $HOME

echo "--------------------------------------------------------"
echo "----- Disabling the raspberry ssh password warning -----"
echo "--------------------------------------------------------"
echo
sudo mv /etc/xdg/lxsession/LXDE-pi/sshpwd.sh /etc/xdg/lxsession/LXDE-pi/sshpwd.sh.old

echo "------------------------------------"
echo "---- Loading required packages -----"
echo "------------------------------------"
echo
sudo apt-get -y install xdotool xterm raspberrypi-kernel-headers cmake

# save systems 'config.txt' file to 'config.txt.orig' but only the first time
if [ ! -f $CONFIG_DIR/config.txt.orig ]; then
  sudo cp $CONFIG_DIR/config.txt $CONFIG_DIR/config.txt.orig
fi

echo "--------------------------------------------------------------"
echo "---- Put the Desktop Toolbar at the bottom of the screen -----"
echo "--------------------------------------------------------------"
echo
cd $HOME/.config/lxpanel/LXDE-pi/panels
sed -i "/^  edge=top/c\  edge=bottom" panel
cd $HOME

echo "----------------------------------------------------"
echo "---- Increasing gpu memory in /boot/config.txt -----"
echo "----------------------------------------------------"
echo
sudo bash -c 'echo -e "\n##Increase GPU Memory" >> /boot/config.txt'
sudo bash -c 'echo -e "gpu_mem=128\n" >> /boot/config.txt'

echo "-------------------------------------------------"
echo "---- Set force_turbo for constant spi speed -----"
echo "-------------------------------------------------"
echo
sudo bash -c 'echo -e "##Set force_turbo for constant spi speed" >> /boot/config.txt'
sudo bash -c 'echo -e "force_turbo=1\n" >> /boot/config.txt'

echo "--------------------------------------"
echo "---- Set the spi ports correctly -----"
echo "--------------------------------------"
echo
sudo sed -i "/^#dtparam=spi=on/c\dtparam=spi=off\ndtoverlay=spi5-1cs" /boot/config.txt

echo "----------------------------------------------"
echo "---- Setting Framebuffer to 32 bit depth -----"
echo "----------------------------------------------"
echo
sudo sed -i "/^dtoverlay=vc4-fkms-v3d/c\#dtoverlay=vc4-fkms-v3d" /boot/config.txt

echo "------------------------------------------------------------"
echo "---- Setting GUI to start with or without HDMI display -----"
echo "------------------------------------------------------------"
echo
sudo sed -i "/^#hdmi_force_hotplug=1/c\hdmi_force_hotplug=1" /boot/config.txt

echo "-------------------------------------------------------------------"
echo "---- Download & Install Dependencies for WinterHill Software ------"
echo "-------------------------------------------------------------------"
echo
if [ ! -f /usr/local/lib/libwebsockets.so ]; then
  git clone https://github.com/warmcat/libwebsockets.git
  cd $HOME/libwebsockets/
  git checkout 2445793d15af39fac9ce527bb28ffd42a974bf4f
  mkdir build
  cd $HOME/libwebsockets/build/
  cmake -DLWS_WITH_SSL=0 ..
  make
  sudo make install
  sudo ldconfig
fi

echo "-------------------------------------------"
echo "---- Download the WinterHill Software -----"
echo "-------------------------------------------"
echo
cd $HOME
wget https://github.com/${GIT_SRC}/winterhill/archive/main.zip
unzip -o main.zip
mv winterhill-main winterhill
rm main.zip

BUILD_VERSION=$(<$HOME/winterhill/latest_version.txt)
echo INSTALL WinterHill build started version $BUILD_VERSION > $HOME/winterhill/whlog.txt

echo "------------------------------------------"
echo "---- Building spi driver for install -----"
echo "------------------------------------------"
echo
cd $HOME/winterhill/whsource-3v20/whdriver-3v20
make
if [ $? != 0 ]; then
  echo "------------------------------------------"
  echo "- Failed to build the WinterHill Driver --"
  echo "------------------------------------------"
  echo INSTALL Initial make of driver failed >> $HOME/winterhill/whlog.txt
  exit
fi

# sudo rmmod whdriver-2v22.ko  # Use in future update scripts

sudo insmod whdriver-3v20.ko
if [ $? != 0 ]; then
  echo "------------------------------------------"
  echo "--- Failed to load WinterHill Driver -----"
  echo "------------------------------------------"
  echo INSTALL Initial insmod of driver failed >> $HOME/winterhill/whlog.txt
  exit
fi

cat /proc/modules | grep -q 'whdriver_3v20'
if [ $? != 0 ]; then
  echo "-------------------------------------------------------------"
  echo "--- Failed to find previously loaded  WinterHill Driver -----"
  echo "-------------------------------------------------------------"
  echo INSTALL Initial check of driver failed >> $HOME/winterhill/whlog.txt
  exit
else
  echo
  echo "------------------------------------------------"
  echo "--- Successfully loaded  WinterHill Driver -----"
  echo "------------------------------------------------"
  echo INSTALL Driver Successfully loaded >> $HOME/winterhill/whlog.txt
  echo
fi
cd $HOME

echo "------------------------------------------------"
echo "---- Set up to load the spi driver at boot -----"
echo "------------------------------------------------"
echo
sudo sed -i "/^exit 0/c\cd $HOME/winterhill/whsource-3v20/whdriver-3v20\nsudo insmod whdriver-3v20.ko\nexit 0" /etc/rc.local

echo "---------------------------------------------------"
echo "---- Building the main WinterHill Application -----"
echo "---------------------------------------------------"
echo
cd $HOME/winterhill/whsource-3v20/whmain-3v20
make
if [ $? != 0 ]; then
  echo "----------------------------------------------"
  echo "- Failed to build the WinterHill Application -"
  echo "----------------------------------------------"
  echo INSTALL make of main application failed >> $HOME/winterhill/whlog.txt
  exit
fi
cp winterhill-3v20 $HOME/winterhill/RPi-3v20/winterhill-3v20
cd $HOME

echo "--------------------------------------"
echo "---- Building the PIC Programmer -----"
echo "--------------------------------------"
echo
cd $HOME/winterhill/whsource-3v20/whpicprog-3v20
./make.sh
if [ $? != 0 ]; then
  echo "--------------------------------------"
  echo "- Failed to build the PIC Programmer -"
  echo "--------------------------------------"
  echo INSTALL make of PIC Programmer failed >> $HOME/winterhill/whlog.txt
  exit
fi
cp whpicprog-3v20 $HOME/winterhill/PIC-3v20/whpicprog-3v20
cd $HOME

echo "--------------------------------------------"
echo "---- Copy the shortcuts to the desktop -----"
echo "--------------------------------------------"
echo
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

echo "--------------------------------------------------------------------"
echo "---- Enable Autostart for the selected WinterHill mode at boot -----"
echo "--------------------------------------------------------------------"
echo
mkdir $HOME/.config/autostart
cp $HOME/winterhill/configs/startup.desktop $HOME/.config/autostart/startup.desktop

# Save git source used
echo "${GIT_SRC}" > $HOME/${GIT_SRC_FILE}

echo
echo "SD Card Serial:"
cat /sys/block/mmcblk0/device/cid

# Reboot
echo
echo "--------------------------------"
echo "----- Complete.  Rebooting -----"
echo "--------------------------------"
echo INSTALL Reached end of install script >> $HOME/winterhill/whlog.txt

sleep 1

sudo reboot now
exit


