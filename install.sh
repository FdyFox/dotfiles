#!/usr/bin/env bash
# Entry point for new machines: installs git + GitHub CLI, logs in to GitHub
# via device code in the browser, clones the private dotfiles repo to
# ~/.dotfiles and starts bootstrap.sh.
#
#   curl -fsSL https://raw.githubusercontent.com/FdyFox/dotfiles/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/FdyFox/dotfiles/main/install.sh | bash -s -- --server
#
# All arguments are passed on to bootstrap.sh.

set -euo pipefail

REPO="FdyFox/dotfiles_bash"
TARGET="$HOME/.dotfiles"

info() { printf '\033[0;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m==> %s\033[0m\n' "$*"; }
die() {
    printf '\033[0;31m==> %s\033[0m\n' "$*" >&2
    exit 1
}

install_tools() {
    if command -v git &>/dev/null && command -v gh &>/dev/null; then
        return
    fi

    # shellcheck disable=SC1091
    source /etc/os-release
    local ids=" ${ID:-} ${ID_LIKE:-} "

    info "Installing git and GitHub CLI"
    case "$ids" in
    *" arch "*)
        sudo pacman -Sy --needed --noconfirm git github-cli
        ;;
    *" fedora "* | *" rhel "*)
        sudo dnf install -y git gh
        ;;
    *" debian "* | *" ubuntu "*)
        sudo apt-get update -qq
        sudo apt-get install -y -qq git curl
        # Official GitHub repo, distro packages are often very old
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
            sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
            sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq gh
        ;;
    *)
        die "Unsupported distribution: ${ID:-?}"
        ;;
    esac
}

github_login() {
    if gh auth status -h github.com &>/dev/null; then
        info "Already logged in to GitHub"
    else
        info "GitHub login: enter the code at https://github.com/login/device (works on your phone too)"
        # With curl | bash stdin is the script itself, so read input from the terminal
        gh auth login -h github.com --web --git-protocol https --skip-ssh-key </dev/tty
    fi
    # git pull/push over https with the gh token (for the auto-update in bootstrap.sh)
    gh auth setup-git -h github.com
}

clone_repo() {
    if [ -d "$TARGET/.git" ]; then
        info "$TARGET already exists, skipping clone"
    elif [ -e "$TARGET" ]; then
        die "$TARGET exists but is not a git repo. Back it up or remove it first."
    else
        info "Cloning $REPO to $TARGET"
        gh repo clone "$REPO" "$TARGET"
    fi
}

main() {
    [ "$(id -u)" -ne 0 ] || die "Please run as a regular user, not as root"

    install_tools
    github_login
    clone_repo

    warn "Note: Without a keyring (e.g. on minimal systems) the GitHub token is stored"
    warn "in plain text in ~/.config/gh/hosts.yml. bootstrap.sh switches the remote to SSH"
    warn "at the end; once your SSH key works with GitHub you can run 'gh auth logout'."
    warn "With --work/--server the remote stays on https, keep the token there."

    info "Starting bootstrap.sh $*"
    cd "$TARGET"
    exec ./bootstrap.sh "$@" </dev/tty
}

# Everything lives in main() so an interrupted download doesn't run half a script
main "$@"
