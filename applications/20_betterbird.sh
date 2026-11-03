# Betterbird: Arch -> betterbird-bin (CachyOS-Repo bzw. AUR), Fedora -> Flathub
if $ARCH; then
  is_package_installed "betterbird-bin" || install_yay betterbird-bin
fi

if $FEDORA; then
  flatpak info eu.betterbird.Betterbird &>/dev/null || flatpak install -y flathub eu.betterbird.Betterbird
fi
