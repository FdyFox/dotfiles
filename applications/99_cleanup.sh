
cd $HOME/.dotfiles

# Work machines and servers usually have no GitHub SSH key -> use https
if [ "$WORK" = true ] || [ "$SERVER" = true ]; then
    git remote set-url origin https://github.com/FdyFox/dotfiles_bash.git
else
    git remote set-url origin git@github.com:FdyFox/dotfiles_bash.git
fi

log "SUCCESS" "Cleanup done!"
