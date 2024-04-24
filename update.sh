#!/bin/bash

# Updated by davecrump 202103080 for WinterHill

reset

echo "------------------------------------------------"
echo "------ Commencing WinterHill Update ------------"
echo "------------------------------------------------"
echo

cd $HOME

## Check which update to load
GIT_SRC_FILE=".wh_gitsrc"
if [ -e ${GIT_SRC_FILE} ]; then
  GIT_SRC=$(<$(HOME)/${GIT_SRC_FILE})
else
  GIT_SRC="BritishAmateurTelevisionClub"
fi

# Define Location of Dev version
GIT_DEV="davecrump"  # G8GKQ
#GIT_DEV="foxcube"     # G4EWJ

## If previous version was Dev, load production by default
if [ "$GIT_SRC" == "$GIT_DEV" ]; then
  GIT_SRC="BritishAmateurTelevisionClub"
fi

if [ "$1" == "-d" ]; then
  echo "Overriding to update to latest development version"
  GIT_SRC=$GIT_DEV
fi

if [ "$GIT_SRC" == "BritishAmateurTelevisionClub" ]; then
  echo "Updating to latest Production WinterHill build";
elif [ "$GIT_SRC" == "$GIT_DEV" ]; then
  echo "Updating to latest development WinterHill build";
else
  echo "Updating to latest ${GIT_SRC} development WinterHill build";
fi

echo
echo "------------------------------------------------"
echo "-- Making Sure that WinterHill is not running --"
echo "------------------------------------------------"
echo

pgrep winterhill
WHRUNS=$?
while [ $WHRUNS = 0 ]
do
  PID=$(pgrep winterhill | head -n 1)
  echo $PID
  sudo kill "$PID"
  sleep 1
  PID=$(pgrep winterhill | head -n 1)
  echo $PID
  sudo kill -9 "$PID"
  pgrep winterhill
  WHRUNS=$?
done

echo "------------------------------------------------"
echo "-- Making a Back-up of the User Configuration --"
echo "------------------------------------------------"
echo

PATHINI="$HOME/winterhill"
PATHUBACKUP="$HOME/user_backups"
mkdir "$PATHUBACKUP" >/dev/null 2>/dev/null

# Note previous version number
cp -f -r $HOME/winterhill/installed_version.txt "$PATHUBACKUP"/prev_installed_version.txt

# Make a safe copy of the user .ini file
cp -f -r "$PATHINI"/winterhill.ini "$PATHUBACKUP"/winterhill.ini

echo
echo "Updating the OS and Installed Packages"
echo

sudo dpkg --configure -a                         # Make sure that all the packages are properly configured
sudo apt-get clean                               # Clean up the old archived packages
sudo apt-get update --allow-releaseinfo-change   # Update the package list
sudo apt-get -y dist-upgrade                     # Upgrade all the installed packages to their latest version

# --------- Install new packages as Required ---------

# Add code here to install any new packages required by updates

# --------- Now update WinterHill ---------

echo
echo "Updating the WinterHill Software"
echo

cd $HOME

# Delete the previous winterhill code
rm -rf winterhill >/dev/null 2>/dev/null

echo "--------------------------------------------------"
echo "---- Downloading the new WinterHill Software -----"
echo "--------------------------------------------------"
echo
cd $HOME
wget https://github.com/${GIT_SRC}/winterhill/archive/main.zip
unzip -o main.zip
mv winterhill-main winterhill
rm main.zip

BUILD_VERSION=$(<$(HOME)/winterhill/latest_version.txt)
sudo chown pi $HOME/winterhill/whlog.txt  # Will be owned by root in some conditions
echo UPDATE WinterHill update started version $BUILD_VERSION >> $HOME/winterhill/whlog.txt
echo UPDATE from $GIT_SRC repository >> $HOME/winterhill/whlog.txt

# spi driver may need rebuilding after OS update
echo "--------------------------------------------"
echo "---- Rebuilding spi driver for install -----"
echo "--------------------------------------------"
echo
cd $HOME/winterhill/whsource-3v20/whdriver-3v20
make
if [ $? != 0 ]; then
  echo "------------------------------------------"
  echo "- Failed to build the WinterHill Driver --"
  echo "------------------------------------------"
  echo UPDATE Failed to build the WinterHill Driver >> $HOME/winterhill/whlog.txt
  exit
fi

# Remove any old drivers, and the current one  
# Add current driver to this list after a driver update
sudo rmmod whdriver-2v22.ko >/dev/null 2>/dev/null
sudo rmmod whdriver-3v20.ko >/dev/null 2>/dev/null

# Load the new driver
sudo insmod whdriver-3v20.ko
if [ $? != 0 ]; then
  echo "------------------------------------------"
  echo "--- Failed to load WinterHill Driver -----"
  echo "------------------------------------------"
  echo UPDATE Failed to load the WinterHill Driver >> $HOME/winterhill/whlog.txt
  exit
fi

cat /proc/modules | grep -q 'whdriver_3v20'
if [ $? != 0 ]; then
  echo "-----------------------------------------------------"
  echo "--- Failed to find new loaded WinterHill Driver -----"
  echo "-----------------------------------------------------"
  echo UPDATE Failed to find the new loaded WinterHill Driver >> $HOME/winterhill/whlog.txt
  exit
else
  echo
  echo "------------------------------------------------"
  echo "--- Successfully loaded  WinterHill Driver -----"
  echo "------------------------------------------------"
  echo UPDATE Successfully loaded  WinterHill Driver >> $HOME/winterhill/whlog.txt
  echo
fi
cd $HOME

#echo "----------------------------------------------------"
#echo "---- Set up to load the new spi driver at boot -----"
#echo "----------------------------------------------------"
#echo

# A new sed line will be required here when the driver name is changed
# sudo sed -i "/^exit 0/c\cd $HOME/winterhill/whsource-3v20/whdriver-3v20\nsudo insmod whdriver-3v20.ko\nexit 0" /etc/rc.local

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
  echo UPDATE Failed to build the WinterHill Application >> $HOME/winterhill/whlog.txt
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
  echo UPDATE Failed to build the PIC Programmer >> $HOME/winterhill/whlog.txt
  exit
fi
cp whpicprog-3v20 $HOME/winterhill/PIC-3v20/whpicprog-3v20
cd $HOME

# Any desktop shortcuts needing replacement will need deleting here

# rm $HOME/Desktop/WH_Local
# rm $HOME/Desktop/WH_Anyhub
# rm $HOME/Desktop/WH_Anywhere
# rm $HOME/Desktop/WH_Multihub
# rm $HOME/Desktop/PIC_Prog

#echo "------------------------------------------------"
#echo "---- Copy the new shortcuts to the desktop -----"
#echo "------------------------------------------------"
#echo

#cp $HOME/winterhill/configs/WH_Local     $HOME/Desktop/WH_Local
#cp $HOME/winterhill/configs/WH_Anyhub    $HOME/Desktop/WH_Anyhub
#cp $HOME/winterhill/configs/WH_Anywhere  $HOME/Desktop/WH_Anywhere
#cp $HOME/winterhill/configs/WH_Multihub  $HOME/Desktop/WH_Multihub
#cp $HOME/winterhill/configs/PIC_Prog     $HOME/Desktop/PIC_Prog

# Note previous version number
cp -f -r "$PATHUBACKUP"/prev_installed_version.txt $HOME/winterhill//prev_installed_version.txt 

# Restore the user .ini file
cp -f -r "$PATHUBACKUP"/winterhill.ini "$PATHINI"/winterhill.ini

# Update the version number
cp -f -r $HOME/winterhill/latest_version.txt $HOME/winterhill/installed_version.txt

# Save (overwrite) the git source used
echo "${GIT_SRC}" > $HOME/${GIT_SRC_FILE}

echo "--------------------"
echo "---- Rebooting -----"
echo "--------------------"
echo UPDATE Reached the end of the update script >> $HOME/winterhill/whlog.txt

sleep 1
# Turn off swap to prevent reboot hang
sudo swapoff -a
sudo shutdown -r now  # Seems to be more reliable than reboot

exit
