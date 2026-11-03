# 1Password CLI (op) über das offizielle Paket, damit es mit dem System aktualisiert wird

setup_1password_repo

if $ARCH; then
    is_package_installed "1password-cli" || install_yay 1password-cli
else
    is_package_installed "1password-cli" || install_package 1password-cli
fi

# Alte manuelle Installation entfernen (würde /usr/bin/op im PATH verdecken)
if [ -f /usr/local/bin/op ] && is_package_installed "1password-cli"; then
    log "INFO" "Removing old manual install /usr/local/bin/op"
    sudo rm -f /usr/local/bin/op
fi
