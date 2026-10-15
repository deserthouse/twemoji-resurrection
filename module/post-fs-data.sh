#!/system/bin/sh
# Self-mount for root managers whose module mounting is missing or disabled:
# KernelSU / SukiSU / APatch without a mount metamodule.
#
# Ordering: on KernelSU-family managers the module overlay is already in
# place before post-fs-data scripts run, so the content check below makes
# each bind-mount a no-op. On Magisk, post-fs-data scripts run BEFORE Magic
# Mount applies module overlays (official boot-stage docs) — here the script
# bind-mounts over the stock files itself and Magic Mount later layers the
# same module font over the same slots; both orders converge on identical
# content. The mounts must happen in this stage, before the system font
# cache is built.

MODDIR=$(dirname "$(readlink -f "$0")")
SRC="$MODDIR/system/fonts/NotoColorEmoji.ttf"
[ -f "$SRC" ] || exit 0

# Slot discovery is centralized in bin/emoji-slots.sh — every emoji slot
# declared by fonts.xml, font_fallback.xml or the product customization is
# handled (union, no priority between configs; see that script for why).
SLOTS=$(sh "$MODDIR/bin/emoji-slots.sh" list)

# Report live status in the manager's module list (Zygisk Next style):
# the module is "active" when every emoji font slot currently serves our
# Twemoji file — true after a successful bind-mount and when the manager's
# own mount already put our file in place.
ok=0
total=0
for p in $SLOTS; do
  # A slot whose system file does not exist has nothing to override and
  # does not affect rendering (e.g. NotoColorEmojiLegacy.ttf on recent
  # Android) — don't count it against status.
  [ -e "$p" ] || continue
  total=$((total+1))
  if cmp -s "$SRC" "$p"; then
    ok=$((ok+1))
    continue
  fi
  mount --bind "$SRC" "$p" 2>/dev/null || mount -o bind "$SRC" "$p" 2>/dev/null
  cmp -s "$SRC" "$p" && ok=$((ok+1))
done
if [ "$total" -gt 0 ] && [ "$ok" -eq "$total" ]; then
  STATUS="✅ Twemoji active ($ok/$total emoji fonts)"
elif [ "$ok" -gt 0 ]; then
  STATUS="⚠️ Twemoji partial ($ok/$total emoji fonts)"
else
  STATUS="❌ Twemoji not active"
fi
sed -i "s|^description=.*|description=${STATUS}. Systemless Twemoji on KernelSU/SukiSU/APatch; Magic Mount on Magisk.|" "$MODDIR/module.prop" 2>/dev/null
