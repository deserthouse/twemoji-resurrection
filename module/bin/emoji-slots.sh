#!/system/bin/sh
# Shared emoji-slot discovery and live check — the single source of truth for
# slot parsing. Consumers:
#   install.sh      — per-slot symlinks for Magic Mount (list)
#   post-fs-data.sh — boot self-mount + status description (list)
#   webroot WebUI   — per-slot structured output via the manager root bridge
#
# Config sources are UNIONED rather than prioritized: which config a ROM
# actually reads is decided at build time by the newFontsFallbackXml flag
# (AOSP SystemFonts.java — font_fallback.xml when enabled, fonts.xml is the
# legacy name; both typically exist on the same device). Mounting an extra
# slot is harmless, missing one is not. OEM product overlays are covered too:
#   /system/etc/fonts.xml, /system/etc/font_fallback.xml -> /system/fonts
#   /product/etc/fonts_customization.xml                 -> /product/fonts
# (updatable fonts under /data/fonts are not covered — see README limits)
#
# The XML is normalized to one tag per line before any line-based matching,
# which makes the family extraction immune to single-line families, several
# families or fonts sharing a line, and tags spanning lines — the failure
# modes of a raw sed range over the pretty-printed assumption. lang lives on
# the <family> tag in all three schemas (AOSP FontListParser / FontCustom-
# izationParser read it there; named families reject lang on <font>).
#
# Overrides for isolated tests and for installs running from recovery, where
# /system is only reachable through the Magisk mirror:
#   EMOJI_SLOTS_READ_ROOT — prefix to READ configs and slot files from
#   EMOJI_SLOTS_EMIT_ROOT — prefix printed in emitted paths ("" = real paths)

READ_ROOT=${EMOJI_SLOTS_READ_ROOT:-}
EMIT_ROOT=${EMOJI_SLOTS_EMIT_ROOT:-}
# Module root — this script lives in <module>/bin/, one level below it
MODDIR=$(dirname "$(dirname "$(readlink -f "$0")")")
SRC="$MODDIR/system/fonts/NotoColorEmoji.ttf"

family_fonts() { # $1 = config file; prints the bare font filenames it declares
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | tr '\n' ' ' \
    | sed 's|<family\([^>]*\)/>|<family\1></family>|g' \
    | tr '>' '\n' \
    | sed -ne '/^[[:space:]]*<family [^>]*lang="[^"]*und-Zsye/,/^[[:space:]]*<\/family/p' \
    | sed -ne 's/^[[:space:]]*\([^[:space:]<][^<]*\)<\/font[[:space:]]*$/\1/p'
}

slots() { # prints one absolute font path per declared slot, deduped
  {
    family_fonts "$READ_ROOT/system/etc/fonts.xml" \
      | sed "s|^|$EMIT_ROOT/system/fonts/|"
    family_fonts "$READ_ROOT/system/etc/font_fallback.xml" \
      | sed "s|^|$EMIT_ROOT/system/fonts/|"
    family_fonts "$READ_ROOT/product/etc/fonts_customization.xml" \
      | sed "s|^|$EMIT_ROOT/product/fonts/|"
  } | grep -v '/$' | sort -u
}

case "$1" in
  list)
    slots
    ;;
  check)
    # Per slot: "path<TAB>OK|FAIL|ABSENT" (tab-literal printf — portable
    # across mksh/bash echo variants that disagree on backslash escapes).
    # With EMIT_ROOT empty the paths are real device paths, which on a
    # recovery install are only reachable through READ_ROOT (the mirror);
    # with EMIT_ROOT set the emitted paths are already concrete.
    for p in $(slots); do
      f="$p"
      [ -z "$EMIT_ROOT" ] && f="$READ_ROOT$p"
      if [ ! -e "$f" ]; then
        printf '%s\tABSENT\n' "$p"
      elif cmp -s "$SRC" "$f"; then
        printf '%s\tOK\n' "$p"
      else
        printf '%s\tFAIL\n' "$p"
      fi
    done
    ;;
  *)
    echo "usage: $0 list|check" >&2
    exit 1
    ;;
esac
