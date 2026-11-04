# Install Claude Code (native installer) and link the global CLAUDE.md

log "INFO" "Installing Claude Code..."

CLAUDE_BIN="$HOME/.local/bin/claude"

if [ ! -x "$CLAUDE_BIN" ]; then
    curl -fsSL https://claude.ai/install.sh | bash || log "ERROR" "Claude Code install failed"
else
    "$CLAUDE_BIN" update || log "WARNING" "Claude Code update failed"
fi

ensure_directories "$HOME/.claude"
create_symlink "$SCRIPT_DIR/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

log "INFO" "Claude Code done"
