# Install mise and the global dev tools (python, go, hugo, linters)

log "INFO" "Installing mise..."

MISE_BIN="$HOME/.local/bin/mise"

if [ ! -x "$MISE_BIN" ]; then
    curl -fsSL https://mise.run | sh
else
    "$MISE_BIN" self-update -y || log "WARNING" "mise self-update failed"
fi

ensure_directories "$HOME/.config/mise"
create_symlink "$SCRIPT_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"

log "INFO" "Installing mise tools. This may take a while..."
"$MISE_BIN" install -y || log "ERROR" "mise install failed"

log "INFO" "mise done"
