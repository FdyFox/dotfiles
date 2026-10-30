is_package_installed "git" || install_package "git"

ensure_directories "$HOME/.config/git/"

create_symlink "$SCRIPT_DIR/config/git/gitconfig${WORK:+.work}" "$HOME/.gitconfig"
create_symlink "$SCRIPT_DIR/config/git/hooks" "$HOME/.config/git/hooks"

ensure_directories "$HOME/src/"

if $DEBIAN && [ "$SERVER" != true ]; then
  if [ ! -f "/usr/local/bin/git-credential-manager" ]; then
    LATEST_VERSION=$(get_latest_version "git-ecosystem" "git-credential-manager")
    wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v${LATEST_VERSION}/gcm-linux_amd64.${LATEST_VERSION}.deb -O /tmp/gcm.deb
    sudo dpkg -i /tmp/gcm.deb
    sudo apt-get install -f -y -qq
    rm /tmp/gcm.deb
  fi
fi
