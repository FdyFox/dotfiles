# Install Gnome Plasma

copr_pkgs=()

packages_fedora=()

packages_arch=(
  gnome
  kitty
  blueman
  brightnessctl
  slurp
  grim
  xclip
  libfido2
  udisks2
  yubikey-touch-detector
  openbsd-netcat
)

packages_yay=(
  #swww-git
  #pyprland
  #wallust
  #wlr-layout-ui
)

sddm_conf_dir=/etc/sddm.conf.d

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

# You need to be in the input group to be able to access the keyboard state
sudo usermod -aG input $USER

# Screenshot dir
ensure_directories "$HOME/Pictures/screenshots/"

# SDDM
sudo git clone -b master --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/

echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf

sudo cat <<EOF | sudo tee /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop
[SddmGreeterTheme]
Name=sddm-astronaut-theme
Description=sddm-astronaut-theme
Author=keyitdev
Website=https://github.com/Keyitdev/sddm-astronaut-theme
License=GPL-3.0-or-later
Type=sddm-theme
Version=1.3
ConfigFile=Themes/post-apocalyptic_hacker.conf
Screenshot=Previews/astronaut.png
MainScript=Main.qml
TranslationsDirectory=translations
Theme-Id=sddm-astronaut-theme
Theme-API=2.0
QtVersion=6
EOF

systemctl --user daemon-reload
systemctl --user enable --now yubikey-touch-detector.service
