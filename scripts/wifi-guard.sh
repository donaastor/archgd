#!/bin/bash

while :; do
  if ! getent hosts archlinux.org; then
    while ! iwctl station wlan0 connect "$1"; do
      sleep 1
    done
  fi
  sleep 2
done
