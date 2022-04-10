#!/bin/bash
#
# sudo apt install imagemagick jpegoptim libsox-fmt-all sox

set -euo pipefail
cd "$(dirname "$0")"

# Courtesy of https://pxhere.com/en/photo/1593211

[ -f ocean-original.jpg ] || wget -O ocean-original.jpg \
  https://get.pxhere.com/photo/ocean-atlantic-body-of-water-beach-shore-sky-sand-sea-coast-natural-environment-natural-landscape-wave-cloud-grass-water-wind-wave-coastal-and-oceanic-landforms-vacation-bay-ecoregion-horizon-landscape-summer-calm-wind-tropics-plant-plain-tide-inlet-1593211.jpg

convert ocean-original.jpg -resize 1600x ocean-large.jpg
convert ocean-original.jpg -resize 800x ocean-small.jpg

jpegoptim --quiet --strip-all --all-progressive -S100 ocean-large.jpg
jpegoptim --quiet --strip-all --all-progressive -S40 ocean-small.jpg

# Courtesy of https://soundbible.com/338-Beach-Waves.html

[ -f ocean-original.wav ] || wget -O ocean-original.wav \
  'https://soundbible.com/grab.php?id=338&type=wav'

TRIM_LENGTH=3
FADE_LENGTH=5

ORIGINAL_LENGTH="$(soxi -D ocean-original.wav)"
TRIMMED_LENGTH="$(scale=6; echo "$ORIGINAL_LENGTH - ($TRIM_LENGTH * 2)" | bc)"
NEW_LENGTH="$(echo "scale=6; $TRIMMED_LENGTH - $FADE_LENGTH" | bc)"
MID_POSITION="$(echo "scale=6; ($FADE_LENGTH + $NEW_LENGTH) / 2" | bc)"

sox ocean-original.wav ocean-t1.wav remix - gain -n -3 \
  trim "$TRIM_LENGTH" "$TRIMMED_LENGTH"

sox ocean-t1.wav ocean-t2.wav fade t "$FADE_LENGTH" -0 "$FADE_LENGTH"

sox ocean-t2.wav ocean-t3.wav delay "$NEW_LENGTH"

sox -m ocean-t2.wav ocean-t3.wav ocean-t4.wav

sox ocean-t4.wav ocean-t5.wav trim "$MID_POSITION" "$NEW_LENGTH"

sox ocean-t5.wav ocean.mp3
sox ocean-t5.wav ocean.ogg

rm -f ocean-t*.wav
