#!/bin/bash

gotov() {
  exec bash --norc -c "rm /tmp/to100.sh; exit $1"
}

vrti() {
  xcn=0
  ycn=0
  while :; do
    if pactl set-sink-volume @DEFAULT_SINK@ 100%; then gotov 0; fi
    xcn=$(( $xcn + 1 ))
    if [ $xcn = $1 ]; then
      xcn=0
      ycn=$(( $ycn + 1 ))
      if [ $ycn = $2 ]; then break; fi
      sleep 1
    fi
  done
}

systemctl --user start pipewire-pulse
vrti 3 4
vrti 2 5
vrti 1 8

gotov 1
