# Settings and extensions for code-server and VS Code Remote-SSH

log "INFO" "Configuring VS Code server..."

VSCODE_CONFIG="$SCRIPT_DIR/config/vscode"

# Settings for code-server and for VS Code via Remote-SSH
for settings in \
    "$HOME/.local/share/code-server/User/settings.json" \
    "$HOME/.vscode-server/data/Machine/settings.json"; do
    ensure_directories "$(dirname "$settings")"
    if [ -f "$settings" ] && [ ! -L "$settings" ]; then
        log "WARNING" "Backing up existing $settings"
        mv "$settings" "$settings.bak"
    fi
    create_symlink "$VSCODE_CONFIG/settings.json" "$settings"
done

# Common extensions for code-server.
# Remote-SSH extensions are installed by "remote.SSH.defaultExtensions" in the local VS Code,
# because the ~/.vscode-server binary path changes with every VS Code version.
if command -v code-server &>/dev/null; then
    grep -vE '^\s*(#|$)' "$VSCODE_CONFIG/extensions-common.txt" | while read -r ext; do
        code-server --install-extension "$ext" >/dev/null &&
            log "SUCCESS" "Extension $ext installed" ||
            log "ERROR" "Failed to install extension $ext"
    done
else
    log "INFO" "code-server not found, skipping extensions"
fi

log "INFO" "VS Code server done"
