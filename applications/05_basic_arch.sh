if $ARCH; then

    packages=(
        noto-fonts-emoji
        base-devel
        python-pipx
        fd
        bat
        eza
        starship
        lazygit
        libnewt
		yay
    )

    for package in "${packages[@]}"; do
        if ! is_package_installed "$package"; then
            install_package "$package"
        fi
    done

    if [ "$DISTRO" == "manjaro" ]; then
        # Enable third party packages
        create_symlink "$SCRIPT_DIR/config/misc/pamac/pamac.conf" "/etc/pamac.conf"
    fi

    # make yay faster - do not use compression
    sudo sed -i "s/PKGEXT=.*/PKGEXT='.pkg.tar'/g" /etc/makepkg.conf
    sudo sed -i "s/SRCEXT=.*/SRCEXT='.src.tar'/g" /etc/makepkg.conf
fi
