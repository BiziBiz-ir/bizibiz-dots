#!/usr/bin/env bash
# install.sh — copy bizibiz-dots into the standard locations.
# Backs up anything it would overwrite into ~/.config/theme-backups/<date>-dots-install

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.config/theme-backups/$(date +%Y%m%d-%H%M%S)-dots-install"

backup() {
    if [[ -e $1 ]]; then
        mkdir -p "$BACKUP$(dirname "$1")"
        cp -a "$1" "$BACKUP$(dirname "$1")/"
    fi
}

echo "backups go to $BACKUP (only files that already exist)"

for f in \
    config/hypr/hyprland.conf config/hypr/hypridle.conf \
    config/hypr/hyprlock.conf config/hypr/hyprpaper.conf \
    config/waybar/config.jsonc config/waybar/style.css \
    config/waybar/scripts/media.sh \
    config/wofi/config config/wofi/style.css \
    config/wlogout/layout config/wlogout/style.css \
    config/dunst/dunstrc \
    config/kitty/kitty.conf config/kitty/theme.conf \
    config/eww/eww.yuck config/eww/eww.scss \
    config/eww/scripts/cpu.sh config/eww/scripts/now.sh \
    config/eww/scripts/gh-contribs.sh config/eww/scripts/gh-calendar.sh \
    config/eww/scripts/gh-cal-render.py \
    config/starship.toml; do
    backup "$HOME/.config/${f#config/}"
done

for f in bluetooth-menu wifi-menu desktop-widget ws-sound ws-sound-toggle clipboard-history screenshot brightness; do
    backup "$HOME/.local/bin/$f"
done

echo "copying..."
mkdir -p ~/.config/{hypr,waybar/scripts,wofi,wlogout,dunst,kitty,eww/scripts} \
         ~/.local/bin ~/.local/share/sounds ~/.local/share/wlogout/icons
cp -a "$DIR"/config/hypr/*.conf      ~/.config/hypr/
cp -a "$DIR"/config/waybar/*.jsonc "$DIR"/config/waybar/*.css ~/.config/waybar/
cp -a "$DIR"/config/waybar/scripts/* ~/.config/waybar/scripts/
cp -a "$DIR"/config/wofi/*           ~/.config/wofi/
cp -a "$DIR"/config/wlogout/*        ~/.config/wlogout/
cp -a "$DIR"/config/dunst/*          ~/.config/dunst/
cp -a "$DIR"/config/kitty/*          ~/.config/kitty/
cp -a "$DIR"/config/eww/*.yuck "$DIR"/config/eww/*.scss ~/.config/eww/
cp -a "$DIR"/config/eww/scripts/*    ~/.config/eww/scripts/
cp -a "$DIR"/config/starship.toml    ~/.config/starship.toml
cp -a "$DIR"/bin/*                   ~/.local/bin/
cp -a "$DIR"/sounds/*                ~/.local/share/sounds/
cp -a "$DIR"/assets/wlogout-icons/*  ~/.local/share/wlogout/icons/

# wlogout's CSS needs absolute icon paths; rewrite the placeholder
sed -i "s|/home/USER/|$HOME/|g" ~/.config/wlogout/style.css

chmod +x ~/.local/bin/{bluetooth-menu,wifi-menu,desktop-widget,ws-sound,ws-sound-toggle,clipboard-history,screenshot,brightness} \
         ~/.config/waybar/scripts/media.sh \
         ~/.config/eww/scripts/*.sh

echo "done. reload with: hyprctl reload && pkill -SIGUSR2 waybar && dunstctl reload"
echo "github calendar: paste a classic PAT (read:user) into ~/.config/gh-contribs-token for private contributions"
