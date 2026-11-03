# Install Hyprland (Lua config) + Dux Shell

copr_pkgs=(
  solopasha/hyprland
  duxlabs/dms
)

packages_fedora=(
  hyprland
  xdg-desktop-portal-hyprland
  dms
  matugen
  kitty
  wl-clipboard
  xclip
)

packages_arch=(
  hyprland
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  dux-shell
  matugen
  cava
  qt6-multimedia
  kitty
  wl-clipboard
  xclip
  libfido2
  udisks2
  yubikey-touch-detector
  openbsd-netcat
)

# Dux-Ökosystem aus dem AUR
packages_yay=(
  dux-files-bin
  dux-search-bin
  dux-calendar-bin
  dux-gop-git
  dux-greeter-bin
)

# Terminal, für das Dux Config + Theme deployt (ghostty | kitty | alacritty)
DUX_TERMINAL=kitty

HYPR_DIR="$HOME/.config/hypr"
HYPR_REPO="$SCRIPT_DIR/config/hyprland"
USER_HOOK='require("user.main")'

if $FEDORA; then
  for pkg in "${copr_pkgs[@]}"; do
    sudo dnf copr enable -y "$pkg"
  done

  dnf check-update

  for package in "${packages_fedora[@]}"; do
    is_package_installed "$package" || install_package "$package"
  done
fi

if $ARCH; then
  for package in "${packages_arch[@]}"; do
    is_package_installed "$package" || install_package "$package"
  done

  for package in "${packages_yay[@]}"; do
    is_package_installed "$package" || install_yay "$package"
  done
fi

# --- ~/.config/hypr ----------------------------------------------------------
# hyprland.lua und dms/*.lua gehören Dux. Aus dem Repo kommen nur user/ und
# scripts/, eingebunden über eine require-Zeile am Ende von hyprland.lua.

# Altes Layout: ganzes Verzeichnis war ein Symlink ins Repo
if [ -L "$HYPR_DIR" ]; then
  log "INFO" "Removing old symlink $HYPR_DIR"
  rm "$HYPR_DIR"
fi
# Zwischenstand: hyprland.lua als Symlink ins Repo
if [ -L "$HYPR_DIR/hyprland.lua" ]; then
  rm "$HYPR_DIR/hyprland.lua"
fi

ensure_directories "$HYPR_DIR"

# Alte hyprlang-Config sichern
if [ -f "$HYPR_DIR/hyprland.conf" ]; then
  mv "$HYPR_DIR/hyprland.conf" "$HYPR_DIR/hyprland.conf.bak.$(date +%s)"
fi

create_symlink "$HYPR_REPO/user" "$HYPR_DIR/user"
create_symlink "$HYPR_REPO/scripts" "$HYPR_DIR/scripts"

# Dux-Stock-Config deployen (bestehende Dateien bleiben unangetastet)
if command -v dms &>/dev/null; then
  dms setup headless --compositor hyprland --terminal "$DUX_TERMINAL" --skip-existing ||
    log "WARNING" "dms setup failed"
else
  log "ERROR" "dms not found, Dux Shell not installed?"
fi

# Eigene Config einhängen (idempotent, überlebt `dms setup --force` durch erneuten Lauf)
if [ -f "$HYPR_DIR/hyprland.lua" ] && ! grep -qF "$USER_HOOK" "$HYPR_DIR/hyprland.lua"; then
  printf '\n-- Dotfiles: eigene Ergänzungen (~/.config/hypr/user)\n%s\n' "$USER_HOOK" >>"$HYPR_DIR/hyprland.lua"
  log "SUCCESS" "Added $USER_HOOK to hyprland.lua"
fi

# --- Dux Files als Standard-Dateimanager ------------------------------------
if command -v dfiles &>/dev/null; then
  xdg-mime default dev.duxlabs.files.desktop inode/directory
fi

# --- Dux Greeter (ersetzt SDDM/GDM durch greetd) ----------------------------
if command -v dms-greeter &>/dev/null && ! systemctl is-enabled -q greetd 2>/dev/null; then
  dms-greeter install
fi

systemctl --user daemon-reload
systemctl --user enable --now yubikey-touch-detector.service
