#!/bin/bash

# whlaunch-anyhub-3v20.sh

# sends the TS to wherever the command came from
# does not start any local VLC windows
# the final zero is the interface IP address which should be set if the RPi has more than one network interface

# First kill any previous instancess of Winterhill

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

# Now launch
cd $HOME/winterhill/RPi-3v20/
./winterhill-anyhub-3v20.sh 0 9900 0

