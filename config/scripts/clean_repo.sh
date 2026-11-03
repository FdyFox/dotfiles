#!/usr/bin/env bash

echo "Removing files and folders"
rm -rf config/git/gitconfig.work
rm -rf config/scripts/backup_script.conf
rm -rf config/scripts/k8s_config.sh
rm -rf config/ssh/*
rm -rf config/zsh/alias
rm -rf config/zsh/alias.work
rm -rf config/zsh/alias.general
rm -rf config/zsh/zshrc.work
rm -rf config/hosts/*
rm -rf config/olm/*
rm -rf config/kde/*

echo "Add keep and dummy files"
touch config/git/gitconfig.work
touch config/ssh/config
touch config/ssh/config.work
touch config/zsh/alias
touch config/zsh/zshrc.work
touch config/hosts/.gitkeep
touch config/kde/.gitkeep

cat <<EOT >config/zsh/alias
#!/usr/bin/env bash

# Alias settings for all systems

# Get OS infos
source /etc/os-release

# Replace ls with exa
if which eza >/dev/null; then
	alias ls="eza --icons -a --group-directories-first"
fi

if [[ \$ID == fedora ]]; then
	alias apt="dnf"
else
	if which nala >/dev/null; then
		alias apt="nala"
	fi
fi

# General linux
if [[ \$OSTYPE == linux* ]]; then

	# cat to batcat
	if which bat >/dev/null; then
		alias cat="bat"
	fi

	# WSL
	if uname -r | grep -q "microsoft"; then
		alias src="cd /mnt/c/src/"
	else
		alias src="cd \$HOME/src"
	fi

	# Update dotfiles
	alias dotfiles="cd \$HOME/.dotfiles/; ./bootstrap.sh --run-all; cd -"

	# Do not use nano
	alias nano="vim"
	alias nani="/usr/bin/nano"

	# Backup script
	alias backup="\$HOME/.local/bin/backup_home"

fi

# macOS aliasses
if [[ \$OSTYPE == darwin* ]]; then

	# cat to batcat
	if which bat >/dev/null; then
		alias cat="bat"
	fi

	# Tailing test with batcat
	alias btail="tail -f \$@ | bat --paging=never -l log"

	# Update dotfiles
	alias dotfiles="export org=\$PWD; cd \$HOME/.dotfiles/; ./install; cd \$org"
fi

# For all Systems

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
EOT

cat <<EOT >config/scripts/backup_script.conf
# SMB credentials
SMB_USERNAME="mylocaluser"            # Your SMB username
SMB_PASSWORD="superawsomepassword"    # Your SMB password
SMB_SHARE="//192.000.000.001/Backup/" # SMB share path

# Backup destination mount point
BACKUP_DEST="/mnt/backup"               # Mount point for the SMB share

# Directories to back up (space-separated list)
BACKUP_DIRECTORIES="/home/\$(whoami)/.thunderbird /home/\$(whoami)/.config /home/\$(whoami)/.var/app/com.core447.StreamController"  # Add more directories as needed

# Archive format (e.g., \$(hostname\$(date +%A).tgz))
ARCHIVE_FORMAT="\$(hostname)-\$(date +%Y-%m-%d).tgz"  # Format for the backup archive filename

# Optional notification URL
NOTIFY_URL="http://example.com/notify"  # URL for the REST service to send notifications

# Set to true to enable notifications
NOTIFY=false

# Optional: Number of backups to keep (not used directly in the script, but for reference)
KEEP_BACKUPS=5
EOT

cat <<EOT >config/olm/olm.service
[Unit]
Description=Olm
After=network.target

[Service]
ExecStart=/usr/local/bin/olm --id <OLM_ID> --secret <OLM_SECRET> --endpoint https://pangolin.example.com
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOT
