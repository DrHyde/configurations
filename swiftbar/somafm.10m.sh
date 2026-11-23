#!/bin/bash

# https://somafm.com/channels.json

MPV=/opt/homebrew/bin/mpv   # /usr/local/bin/mpv on Intel Macs
STATE="$HOME/.somafm_current"

if [ "$1" = "play" ]; then
  pkill -x mpv
  echo "${3//_/ }" > "$STATE"
  nohup "$MPV" --no-video --really-quiet "$2" >/dev/null 2>&1 &
  exit 0
fi

if [ "$1" = "stop" ]; then
  pkill -x mpv
  rm -f "$STATE"
  exit 0
fi

station() {  # usage: station "Display Name" streamname
  local checked=""
  [ "$(cat "$STATE" 2>/dev/null)" = "$1" ] && pgrep -x mpv >/dev/null && checked="checked=true"
  echo "$1 | bash=$0 param1=play param2=$2 param3=${1// /_} terminal=false refresh=true $checked"
}

if pgrep -x mpv >/dev/null && [ -f "$STATE" ]; then
  echo "📻 ▶ Soma FM"
else
  echo "📻 Soma FM"
fi
echo "---"
station "Defcon radio" https://somafm.com/defcon256.pls
station "Doomed" https://somafm.com/doomed256.pls
station "Groove Salad" https://somafm.com/groovesalad256.pls
station "Heavyweight Reggae" https://somafm.com/reggae256.pls
station "Metal Detector" https://somafm.com/metal.pls
station "Suburbs of Goa" https://somafm.com/suburbsofgoa.pls
station "The Dark Zone" https://somafm.com/darkzone256.pls
echo "---"
echo "Stop | bash=$0 param1=stop terminal=false refresh=true"
