# Bing-Bild des Tages als Dux-Wallpaper (Ersatz für Variety)
if $RUNNING_HYPRLAND; then
  is_package_installed "jq" || install_package jq

  unit_dir="$HOME/.config/systemd/user"
  ensure_directories "$unit_dir"

  for unit in bing-wallpaper.service bing-wallpaper.timer; do
    install -m644 "$SCRIPT_DIR/config/hyprland/systemd/$unit" "$unit_dir/$unit"
  done

  systemctl --user daemon-reload
  systemctl --user enable --now bing-wallpaper.timer
fi
