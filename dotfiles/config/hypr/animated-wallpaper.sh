#!/usr/bin/env bash
# Animated wallpaper via mpvpaper (falls back to hyprpaper if mpvpaper missing)
VIDEO="$HOME/Pictures/wallpapers/wallpaper.mp4"
STILL="$HOME/Pictures/wallpapers/wallpaper.png"
if command -v mpvpaper >/dev/null 2>&1; then
    pkill -x hyprpaper 2>/dev/null
    exec mpvpaper -o "no-audio loop-file=inf hwdec=auto" "*" "$VIDEO"
else
    exec hyprpaper
fi
