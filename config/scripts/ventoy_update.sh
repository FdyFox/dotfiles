#!/usr/bin/env bash
# Update the ISO images in the ISO/ folder of a Ventoy USB stick to the latest releases.
#
#   ventoy-update              find the stick by its "Ventoy" label (mounts it if needed)
#   ventoy-update /run/media/me/Ventoy
#   ventoy-update --dry-run    only show what would be done
#
# Managed images: CachyOS (desktop), Fedora Workstation, Ubuntu LTS (desktop), Tails.
# Every download is verified with SHA256 before it replaces the old version.
# Other files on the stick are never touched.

set -uo pipefail

LABEL="Ventoy"
ISO_SUBDIR="ISO" # images live in <stick>/ISO
DRY_RUN=false
MOUNT=""
MOUNTED_BY_US=false

info() { printf '\033[0;36m==> %s\033[0m\n' "$*"; }
ok() { printf '\033[0;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m==> %s\033[0m\n' "$*" >&2; }
die() {
    printf '\033[0;31m==> %s\033[0m\n' "$*" >&2
    exit 1
}

for arg in "$@"; do
    case "$arg" in
    -n | --dry-run) DRY_RUN=true ;;
    -h | --help)
        sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *) MOUNT="$arg" ;;
    esac
done

for cmd in curl jq sha256sum findmnt; do
    command -v "$cmd" &>/dev/null || die "Missing command: $cmd"
done

# --- Resolvers: print "<url> <sha256>" of the latest image -----------------

resolve_cachyos() {
    local url sum
    url=$(curl -fsSL https://cachyos.org/download/ |
        grep -oE 'https://iso\.cachyos\.org/desktop/[0-9]+/cachyos-desktop-linux-[0-9]+\.iso' |
        sort -uV | tail -n1) || return 1
    [ -n "$url" ] || return 1
    sum=$(curl -fsSL "$url.sha256" | awk '{print $1}') || return 1
    echo "$url $sum"
}

resolve_fedora() {
    curl -fsSL https://fedoraproject.org/releases.json | jq -r '
        [ .[] | select(.arch == "x86_64" and .variant == "Workstation" and (.link | endswith(".iso")))
              | select(.version | test("^[0-9]+$")) ]
        | sort_by(.version | tonumber) | last | "\(.link) \(.sha256)"'
}

resolve_ubuntu() {
    local dist base line
    dist=$(curl -fsSL https://changelogs.ubuntu.com/meta-release-lts |
        awk '/^Dist:/ {d=$2} /^Supported: 1/ {s=d} END {print s}') || return 1
    [ -n "$dist" ] || return 1
    base="https://releases.ubuntu.com/$dist"
    line=$(curl -fsSL "$base/SHA256SUMS" | grep -E '\*?ubuntu-[0-9.]+-desktop-amd64\.iso$' |
        sort -V -k2 | tail -n1) || return 1
    [ -n "$line" ] || return 1
    echo "$base/${line##*[ *]} ${line%% *}"
}

resolve_tails() {
    curl -fsSL https://tails.net/install/v2/Tails/amd64/stable/latest.json | jq -r '
        .installations[0]."installation-paths"[] | select(.type == "iso")
        | ."target-files"[0] | "\(.url) \(.sha256)"'
}

# name | resolver | glob of all versions of this image (for cleanup)
IMAGES=(
    "CachyOS|resolve_cachyos|cachyos-desktop-linux-*.iso"
    "Fedora Workstation|resolve_fedora|Fedora-Workstation-Live-*.iso"
    "Ubuntu LTS|resolve_ubuntu|ubuntu-*-desktop-amd64.iso"
    "Tails|resolve_tails|tails-amd64-*.iso"
)

# --- Find / mount the stick ---------------------------------------------------

if [ -z "$MOUNT" ]; then
    MOUNT=$(findmnt -rno TARGET -S "LABEL=$LABEL" | head -n1)
    if [ -z "$MOUNT" ]; then
        dev="/dev/disk/by-label/$LABEL"
        [ -e "$dev" ] || die "No Ventoy stick found (no partition labeled '$LABEL')"
        command -v udisksctl &>/dev/null || die "Stick is not mounted and udisksctl is missing"
        info "Mounting $dev"
        udisksctl mount -b "$dev" >/dev/null || die "Mounting $dev failed"
        MOUNT=$(findmnt -rno TARGET -S "LABEL=$LABEL" | head -n1)
        MOUNTED_BY_US=true
    fi
fi
[ -d "$MOUNT" ] && [ -w "$MOUNT" ] || die "$MOUNT is not a writable directory"
info "Ventoy stick: $MOUNT"
ISO_DIR="$MOUNT/$ISO_SUBDIR"
if ! $DRY_RUN; then
    mkdir -p "$ISO_DIR" || die "Could not create $ISO_DIR"
fi

# --- Update ------------------------------------------------------------------

free_bytes() { df --output=avail -B1 "$MOUNT" | tail -n1 | tr -d ' '; }

update_image() {
    local name="$1" resolver="$2" glob="$3"
    local resolved url sum file target part size old

    info "$name: checking latest release"
    resolved=$("$resolver") || resolved=""
    url="${resolved%% *}"
    sum="${resolved##* }"
    if [ -z "$resolved" ] || [ "$url" = "$sum" ] || ! [[ "$sum" =~ ^[0-9a-f]{64}$ ]]; then
        warn "$name: could not determine the latest release"
        return 1
    fi

    file="${url##*/}"
    target="$ISO_DIR/$file"
    part="$ISO_DIR/.$file.part"

    if [ -f "$target" ]; then
        ok "$name: $file is up to date"
        return 0
    fi

    # Current version still in the stick root (old layout): just move it
    if [ -f "$MOUNT/$file" ]; then
        if $DRY_RUN; then
            info "$name: would move $file to $ISO_SUBDIR/"
        else
            mv -- "$MOUNT/$file" "$target" && ok "$name: moved $file to $ISO_SUBDIR/"
        fi
        return
    fi

    # Older versions of this image already on the stick (ISO folder or root)
    local olds=()
    for old in "$ISO_DIR"/$glob "$MOUNT"/$glob; do
        [ -f "$old" ] && olds+=("$old")
    done

    if $DRY_RUN; then
        info "$name: would download $ISO_SUBDIR/$file${olds:+ and remove ${olds[*]#"$MOUNT"/}}"
        return 0
    fi

    size=$(curl -fsSIL "$url" | awk 'tolower($1)=="content-length:" {s=$2} END {print s+0}')
    local have=0
    [ -f "$part" ] && have=$(stat -c %s "$part")
    if [ "$size" -gt 0 ] && [ $((size - have)) -gt "$(free_bytes)" ] && [ ${#olds[@]} -gt 0 ]; then
        warn "$name: not enough space, removing old version first"
        rm -f -- "${olds[@]}"
        olds=()
    fi
    if [ "$size" -gt 0 ] && [ $((size - have)) -gt "$(free_bytes)" ]; then
        warn "$name: not enough free space on the stick ($((size / 1024 / 1024)) MiB needed)"
        return 1
    fi

    info "$name: downloading $file"
    if ! curl -fL --retry 3 --retry-delay 5 -C - --progress-bar -o "$part" "$url"; then
        warn "$name: download failed, run again to resume"
        return 1
    fi

    info "$name: verifying SHA256"
    if ! echo "$sum  $part" | sha256sum -c --status; then
        warn "$name: checksum mismatch, deleting download"
        rm -f -- "$part"
        return 1
    fi

    mv -- "$part" "$target"
    [ ${#olds[@]} -gt 0 ] && rm -f -- "${olds[@]}" && info "$name: removed ${olds[*]#"$MOUNT"/}"
    ok "$name: $ISO_SUBDIR/$file ready"
}

failed=()
for entry in "${IMAGES[@]}"; do
    IFS='|' read -r name resolver glob <<<"$entry"
    update_image "$name" "$resolver" "$glob" || failed+=("$name")
done

if ! $DRY_RUN; then
    info "Flushing writes to the stick"
    sync
fi

if $MOUNTED_BY_US; then
    udisksctl unmount -b "/dev/disk/by-label/$LABEL" >/dev/null && info "Stick unmounted"
fi

if [ ${#failed[@]} -gt 0 ]; then
    die "Failed: ${failed[*]}"
fi
if $DRY_RUN; then
    ok "Dry run finished, nothing changed"
else
    ok "All images up to date"
fi
