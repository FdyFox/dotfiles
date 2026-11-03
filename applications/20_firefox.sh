if $DEBIAN; then
    if ! is_package_installed "firefox"; then
        # Offizielles Mozilla-Repo (Ubuntu liefert sonst nur das Snap)
        sudo install -d -m 0755 /etc/apt/keyrings
        wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
        echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
        printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
        update_cache
        install_package firefox
    fi
fi

if $ARCH || $FEDORA; then
    is_package_installed "firefox" || install_package firefox
fi

# Als Standardbrowser setzen
if command -v xdg-settings &>/dev/null; then
    xdg-settings set default-web-browser firefox.desktop &&
        log "SUCCESS" "Firefox set as default browser" ||
        log "WARNING" "Could not set Firefox as default browser"
fi
