#!/usr/bin/env bash
# Prints the now-playing line for waybar's custom/media module.
# Title only - the bar has limited room; the eww HUD shows artist + title.
# Exits 1 (module hidden) when nothing is playing.

status=$(playerctl status 2>/dev/null) || exit 1

title=$(playerctl metadata --format '{{title}}' 2>/dev/null)
artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)

case "$status" in
    Playing) icon="▶" ;;
    Paused)  icon="‖" ;;
    *)       icon="▸" ;;
esac

if [[ -n $title ]]; then
    printf '%s %s\n' "$icon" "$title"
elif [[ -n $artist ]]; then
    printf '%s %s\n' "$icon" "$artist"
fi
