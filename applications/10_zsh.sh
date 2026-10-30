
is_package_installed "zsh" || install_package "zsh"

ensure_directories "$HOME/.config/"

# Config variant: .server > .work > default
ZSH_SUFFIX="${WORK:+.work}"
[ "$SERVER" = true ] && ZSH_SUFFIX=".server"

create_symlink "$SCRIPT_DIR/config/zsh/alias${ZSH_SUFFIX}" "$HOME/.alias"

create_symlink "$SCRIPT_DIR/config/zsh/custom_env${ZSH_SUFFIX}" "$HOME/.custom_env"
create_symlink "$SCRIPT_DIR/config/zsh/starship.toml" "$HOME/.config/starship.toml"

# Test is .oh-my-zsh is installed from git
if [ -d $HOME/.oh-my-zsh ]; then
    if [ ! -d $HOME/.oh-my-zsh/.git ]; then
        rm -rf $HOME/.oh-my-zsh
    fi
fi

# Install oh-my-zsh
if [ ! -d $HOME/.oh-my-zsh ]; then
	sh -c "$(curl -fsSLk https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

create_symlink "$SCRIPT_DIR/config/zsh/zshrc${ZSH_SUFFIX}" "$HOME/.zshrc"

if [ -d ~/.oh-my-zsh ]; then
    clone_repository "https://github.com/zsh-users/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    clone_repository "https://github.com/hsaunders1904/pyautoenv.git" "$HOME/.oh-my-zsh/custom/plugins/pyautoenv"
fi

log "INFO" "Make ZSH to default shell..."
log "WARNING" "I did not find a way to do this without entering the sudo password"
sudo chsh -s $(which zsh) $USER
