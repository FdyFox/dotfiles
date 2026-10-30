if $FEDORA; then
    if ! is_package_installed "starship"; then
        sudo dnf copr -y enable atim/starship
        install_package starship
    fi
fi

if $ARCH; then
    is_package_installed "starship" || install_package starship
fi

if $DEBIAN; then
    if [ ! -f "/usr/local/bin/starship" ]; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
fi
