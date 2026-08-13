#!/usr/bin/env bash
# Animated wallpaper via mpvpaper, falling back to hyprpaper (which paints the
# still image named in hyprpaper.conf) when mpvpaper isn't installed OR the
# video is absent — the video is optional, so don't exec mpvpaper on a file
# that isn't there.
VIDEO="$HOME/Pictures/wallpapers/wallpaper.mp4"
if command -v mpvpaper >/dev/null 2>&1 && [ -r "$VIDEO" ]; then
    pkill -x hyprpaper 2>/dev/null
    exec mpvpaper -o "no-audio loop-file=inf hwdec=auto" "*" "$VIDEO"
else
    exec hyprpaper
fi
