# Basic packages for headless servers (only used with --server)
if [ "$SERVER" = true ]; then
    log "INFO" "SERVER: Installing basic packages"

    packages=(
        git
        curl
        wget
        rsync
        unzip
        zsh
        tmux
        vim
        htop
        btop
        ripgrep
    )

    case "$BASE_DISTRO" in
    debian) packages+=(whiptail fd-find bat) ;;
    fedora) packages+=(newt fd-find bat eza) ;;
    arch) packages+=(libnewt fd bat eza) ;;
    esac

    for package in "${packages[@]}"; do
        if ! is_package_installed "$package"; then
            install_package "$package"
        fi
    done

    create_symlink "$SCRIPT_DIR/config/vim/vimrc" "$HOME/.vimrc"
fi
