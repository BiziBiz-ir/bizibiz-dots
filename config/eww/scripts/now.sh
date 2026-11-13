#!/usr/bin/env bash
# One-line now-playing text for the eww HUD.

status=$(playerctl status 2>/dev/null) || { echo "nothing playing"; exit 0; }

artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
title=$(playerctl metadata --format '{{title}}' 2>/dev/null)

case "$status" in
    Playing) icon="▶" ;;
    Paused)  icon="‖" ;;
    *)       icon="▸" ;;
esac

if [[ -n $artist && -n $title ]]; then
    printf '%s %s — %s\n' "$icon" "$artist" "$title"
elif [[ -n $title ]]; then
    printf '%s %s\n' "$icon" "$title"
else
    printf '%s %s\n' "$icon" "${artist:-nothing playing}"
fi
