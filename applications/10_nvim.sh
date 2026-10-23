is_package_installed "vim" || install_package "vim"
is_package_installed "npm" || install_package "npm"

if $DEBIAN; then
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    sudo apt update
    is_package_installed "neovim" || install_package "neovim"
fi

ensure_directories "$HOME/.config/"

create_symlink "$SCRIPT_DIR/config/nvim" "$HOME/.config/nvim"
create_symlink "$SCRIPT_DIR/config/vim/vimrc" "$HOME/.vimrc"
