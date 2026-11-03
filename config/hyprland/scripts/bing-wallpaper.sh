#!/usr/bin/env bash
# Lädt das Bing-Bild des Tages und setzt es als Dux-Wallpaper.
# Läuft über bing-wallpaper.timer (systemd --user), manuell auch möglich.
#
# Gesetzt wird nur, wenn ein neues Bild da ist. Ein manuell gewähltes oder von
# der Dux-Rotation gesetztes Wallpaper wird also nicht stündlich überschrieben.
# Erzwingen: bing-wallpaper.sh --force
#
# Einstellungen (Umgebungsvariablen):
#   BING_MARKET      Region der Bilder                     (Default: de-DE)
#   BING_RESOLUTION  UHD | 1920x1200 | 1920x1080 | ...      (Default: UHD)
#   BING_DIR         Zielordner, Dux-Rotation kann ihn nutzen
#                                                          (Default: ~/Pictures/Wallpapers/bing)
#   BING_KEEP        Anzahl Bilder, die behalten werden, 0 = alle (Default: 30)
#   BING_MONITORS    Nur diese Monitore setzen, z.B. "DP-1 HDMI-A-2"
#                    (Default: leer = global bzw. alle Monitore)

set -euo pipefail

MARKET="${BING_MARKET:-de-DE}"
RESOLUTION="${BING_RESOLUTION:-UHD}"
DIR="${BING_DIR:-$HOME/Pictures/Wallpapers/bing}"
KEEP="${BING_KEEP:-30}"
MONITORS="${BING_MONITORS:-}"
FORCE=false
[ "${1:-}" = "--force" ] && FORCE=true

STATE="$DIR/.last_set"

mkdir -p "$DIR"

fetch() {
    curl -fsS --retry 5 --retry-delay 10 --retry-all-errors "$@"
}

# --- Bild des Tages ermitteln und laden ---------------------------------------
json=$(fetch "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${MARKET}")
urlbase=$(jq -r '.images[0].urlbase // empty' <<<"$json")
if [ -z "$urlbase" ]; then
    echo "Keine Bilddaten von Bing erhalten" >&2
    exit 1
fi

name="${urlbase##*id=}_${RESOLUTION}.jpg" # z.B. OHR.LittleFoxes_DE-DE123_UHD.jpg
file="$DIR/$name"

if [ ! -s "$file" ]; then
    fetch -o "$file.part" "https://www.bing.com${urlbase}_${RESOLUTION}.jpg"
    mv "$file.part" "$file"
    echo "Heruntergeladen: $name"
fi

# --- Als Wallpaper setzen -----------------------------------------------------
if ! $FORCE && [ "$(cat "$STATE" 2>/dev/null)" = "$name" ]; then
    exit 0 # schon gesetzt
fi

if ! command -v dms &>/dev/null; then
    echo "dms nicht gefunden, Wallpaper nicht gesetzt" >&2
    exit 0
fi

set_for_monitors() {
    local mon
    for mon in "$@"; do
        dms ipc call wallpaper setFor "$mon" "$file" >/dev/null
    done
}

if [ -n "$MONITORS" ]; then
    # shellcheck disable=SC2086
    set_for_monitors $MONITORS
else
    # Im Per-Monitor-Modus lehnt Dux das globale "set" mit einer Fehlermeldung ab
    out=$(dms ipc call wallpaper set "$file" 2>&1) || {
        echo "Dux nicht erreichbar, nächster Versuch beim nächsten Timer-Lauf" >&2
        exit 0
    }
    if grep -qiE "error|per-monitor|setFor" <<<"$out"; then
        mapfile -t mons < <(hyprctl monitors -j | jq -r '.[].name')
        set_for_monitors "${mons[@]}"
    fi
fi

echo "$name" >"$STATE"
echo "Wallpaper gesetzt: $name"

# --- Alte Bilder aufräumen ----------------------------------------------------
if [ "$KEEP" -gt 0 ]; then
    find "$DIR" -maxdepth 1 -type f -name '*.jpg' -printf '%T@ %p\n' |
        sort -rn | tail -n +"$((KEEP + 1))" | cut -d' ' -f2- |
        while read -r old; do
            [ "$old" = "$file" ] || rm -f -- "$old"
        done
fi
