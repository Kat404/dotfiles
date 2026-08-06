#!/bin/bash
# Script to enable ALSA Auto-Mute Mode on boot/login, especially for Realtek ALC294.

# Find the card index of the ALC294 codec
card_idx=$(grep -l "ALC294" /proc/asound/card*/codec#* 2>/dev/null | grep -o 'card[0-9]\+' | head -n1 | sed 's/card//')

if [ -n "$card_idx" ]; then
    echo "Found Realtek ALC294 at card $card_idx. Enabling Auto-Mute Mode..."
    amixer -c "$card_idx" sset "Auto-Mute Mode" Enabled
else
    echo "Realtek ALC294 codec not found by name. Enabling Auto-Mute Mode on all cards that support it..."
    for card_path in /proc/asound/card[0-9]*; do
        card_num=$(basename "$card_path" | sed 's/card//')
        amixer -c "$card_num" sset "Auto-Mute Mode" Enabled 2>/dev/null || true
    done
fi
