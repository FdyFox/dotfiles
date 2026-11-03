setup_1password_repo

if $ARCH; then
    is_package_installed "1password" || install_yay 1password
else
    is_package_installed "1password" || install_package 1password
fi
