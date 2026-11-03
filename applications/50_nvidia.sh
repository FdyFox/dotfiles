# NVIDIA settings
if $ARCH; then
    # Kernelmodul: CachyOS liefert vorgebaute Module (linux-cachyos-nvidia-open),
    # die chwd bei der Installation einrichtet. Nur wenn noch gar kein
    # NVIDIA-Modul installiert ist, nvidia-open-dkms (Turing/RTX 20xx und neuer)
    # samt Headern für alle installierten Kernel nachziehen.
    if pacman -Qq | grep -qE '^(nvidia(-open)?(-beta)?(-dkms)?|linux-.+-nvidia(-open)?)$'; then
        log "INFO" "NVIDIA kernel module already installed, skipping nvidia-open-dkms"
    else
        for pkgbase in /usr/lib/modules/*/pkgbase; do
            headers="$(cat "$pkgbase")-headers"
            is_package_installed "$headers" || install_package "$headers"
        done
        install_package nvidia-open-dkms
    fi

    packages=(
        nvidia-utils
        lib32-nvidia-utils
        nvidia-settings
        libva-nvidia-driver
    )

    for package in "${packages[@]}"; do
        if ! is_package_installed "$package"; then
            install_package "$package"
        fi
    done

    # Schreibt eine Root-Datei nur bei Änderung; Rückgabe 0 = geändert
    write_root_file() {
        local path="$1" content="$2"
        if [ -f "$path" ] && [ "$(cat "$path")" = "$content" ]; then
            return 1
        fi
        sudo mkdir -p "$(dirname "$path")"
        printf '%s\n' "$content" | sudo tee "$path" >/dev/null
        log "SUCCESS" "Wrote $path"
    }

    initramfs_changed=false

    write_root_file /etc/modprobe.d/nvidia.conf "options nvidia_drm modeset=1 fbdev=1" &&
        initramfs_changed=true

    # Early KMS: NVIDIA-Module ins Initramfs (mkinitcpio = CachyOS-Standard, dracut optional)
    if command -v mkinitcpio &>/dev/null; then
        write_root_file /etc/mkinitcpio.conf.d/nvidia.conf "MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" &&
            initramfs_changed=true
    fi
    if command -v dracut &>/dev/null; then
        write_root_file /etc/dracut.conf.d/nvidia.conf 'force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "' &&
            initramfs_changed=true
    fi

    # Initramfs neu bauen; Bootloader-Einträge (Limine/systemd-boot/GRUB) brauchen
    # keine Anpassung, da die Optionen über modprobe.d gesetzt werden.
    if $initramfs_changed; then
        if command -v mkinitcpio &>/dev/null; then
            sudo mkinitcpio -P
        elif command -v dracut-rebuild &>/dev/null; then
            sudo dracut-rebuild
        elif command -v dracut &>/dev/null; then
            sudo dracut --regenerate-all --force
        fi
        log "INFO" "NVIDIA initramfs updated, reboot required"
    fi
fi

if $FEDORA; then
    nvidia_pkg=(
        akmod-nvidia
        xorg-x11-drv-nvidia-cuda
        libva
        libva-nvidia-driver
    )

    nvidia_services=(
        nvidia-suspend.service
        nvidia-hibernate.service
        nvidia-resume.service
    )

    # Install additional Nvidia packages
    for package in "${nvidia_pkg[@]}"; do
        if ! is_package_installed "$package"; then
            install_package "$package"
            if [ $? -ne 0 ]; then
                log "ERROR" "$package Installation failed. Check the install log."
                exit 1
            fi
        fi
    done

    log "WARNING" "Adding nvidia-stuff to /etc/default/grub..."

    # Additional options to add to GRUB_CMDLINE_LINUX
    additional_options="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 nvidia_drm.fbdev=1"

    # Check if additional options are already present in GRUB_CMDLINE_LINUX
    if grep -q "GRUB_CMDLINE_LINUX.*$additional_options" /etc/default/grub; then
        echo "GRUB_CMDLINE_LINUX already contains the additional options"
    else
        # Append the additional options to GRUB_CMDLINE_LINUX
        sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$additional_options /" /etc/default/grub
        echo "Added the additional options to GRUB_CMDLINE_LINUX"
    fi

    # Update GRUB configuration
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    for service in "${nvidia_services[@]}"; do
        sudo systemctl enable "$service"
        if [ $? -ne 0 ]; then
            log "ERROR" "$service could not be activated. Check the install log."
            exit 1
        fi
    done

    log "CINFO" "Nvidia DRM modeset and additional options have been added to /etc/default/grub. Please reboot for changes to take effect."
fi
