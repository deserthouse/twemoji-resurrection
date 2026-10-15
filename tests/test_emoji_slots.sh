#!/usr/bin/env bash
# Regression tests for module/bin/emoji-slots.sh (slot discovery + check).
# Runs the script against fixtures with EMOJI_SLOTS_READ_ROOT/EMIT_ROOT
# overrides — no device, no production paths, no root.
# Note: exercised with the host (GNU) sed/tr on the dev machine; toybox
# equivalents are verified on a real device before release.
set -u
cd "$(dirname "$0")"
ROOT=$(cd .. && pwd)
WORK=.test-work
rm -rf "$WORK"
FX="$WORK/root"
mkdir -p "$FX/system/etc" "$FX/system/fonts" "$FX/product/etc" "$FX/product/fonts"
cp fixtures/system/etc/fonts.xml "$FX/system/etc/"
cp fixtures/system/etc/font_fallback.xml "$FX/system/etc/"
cp fixtures/product/etc/fonts_customization.xml "$FX/product/etc/"
# fake stock fonts (content differs from the module font -> FAIL before "mount")
for f in NotoColorEmoji.ttf CompactEmoji.ttf DualOne.ttf DualTwo.ttf SpanEmoji.ttf \
         MultiLangEmoji.ttf BodyFont.ttf Other.ttf VendorNewEmoji.ttf; do
  printf 'stock-%s' "$f" > "$FX/system/fonts/$f"
done
printf 'stock-ProductEmoji.ttf' > "$FX/product/fonts/ProductEmoji.ttf"
printf 'stock-ProductSans.ttf' > "$FX/product/fonts/ProductSans.ttf"
# module layout next to a copy of the script (SRC resolves relative to it)
mkdir -p "$WORK/module/bin" "$WORK/module/system/fonts"
cp "$ROOT/module/bin/emoji-slots.sh" "$WORK/module/bin/"
printf 'twemoji-fixture' > "$WORK/module/system/fonts/NotoColorEmoji.ttf"

run() { EMOJI_SLOTS_READ_ROOT="$FX" EMOJI_SLOTS_EMIT_ROOT="$FX" sh "$WORK/module/bin/emoji-slots.sh" "$@"; }

fails=0
assert_eq() { # label expected actual
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else
    echo "FAIL: $1"; echo "  expected: [$2]"; echo "  actual:   [$3]"; fails=$((fails+1)); fi
}

# --- list: exact union of all three configs, no swallow / no misses -------
EXPECTED=$(printf '%s\n' \
  "$FX/product/fonts/ProductEmoji.ttf" \
  "$FX/system/fonts/CompactEmoji.ttf" \
  "$FX/system/fonts/DualOne.ttf" \
  "$FX/system/fonts/DualTwo.ttf" \
  "$FX/system/fonts/MultiLangEmoji.ttf" \
  "$FX/system/fonts/NotoColorEmoji.ttf" \
  "$FX/system/fonts/SpanEmoji.ttf" \
  "$FX/system/fonts/VendorNewEmoji.ttf" | sort)
assert_eq "list: union of fonts.xml + font_fallback.xml + customization, body fonts not swallowed" \
  "$EXPECTED" "$(run list | sort)"

# --- emit-root empty: real device paths regardless of read root -----------
REALPATHS=$(EMOJI_SLOTS_READ_ROOT="$FX" EMOJI_SLOTS_EMIT_ROOT= sh "$WORK/module/bin/emoji-slots.sh" list | sort)
case "$REALPATHS" in
  *"$FX"*) echo "FAIL: emit-root= still contains read root"; fails=$((fails+1));;
  *) echo "PASS: emit-root= emits real device paths";;
esac
assert_eq "emit-root=: path count preserved" "8" "$(printf '%s\n' "$REALPATHS" | grep -c .)"
case "$REALPATHS" in
  *"/system/fonts/NotoColorEmoji.ttf"*|*"/product/fonts/ProductEmoji.ttf"*) echo "PASS: emit-root=: expected paths present";;
  *) echo "FAIL: emit-root=: expected paths missing"; fails=$((fails+1));;
esac

# --- check: FAIL for stock, ABSENT for declared-but-missing ---------------
rm "$FX/system/fonts/CompactEmoji.ttf"
assert_eq "check: stock slots FAIL, missing slot ABSENT, none OK" \
"$(printf '%s\n' \
  "$FX/product/fonts/ProductEmoji.ttf	FAIL" \
  "$FX/system/fonts/DualOne.ttf	FAIL" \
  "$FX/system/fonts/DualTwo.ttf	FAIL" \
  "$FX/system/fonts/MultiLangEmoji.ttf	FAIL" \
  "$FX/system/fonts/NotoColorEmoji.ttf	FAIL" \
  "$FX/system/fonts/CompactEmoji.ttf	ABSENT" \
  "$FX/system/fonts/SpanEmoji.ttf	FAIL" \
  "$FX/system/fonts/VendorNewEmoji.ttf	FAIL" | sort)" \
  "$(run check | sort)"

# --- check: mounted slots (content == module font) report OK --------------
for f in NotoColorEmoji.ttf SpanEmoji.ttf; do
  printf 'twemoji-fixture' > "$FX/system/fonts/$f"
done
printf 'twemoji-fixture' > "$FX/product/fonts/ProductEmoji.ttf"
assert_eq "check: slots serving the module font report OK" \
"$(printf '%s\n' \
  "$FX/product/fonts/ProductEmoji.ttf	OK" \
  "$FX/system/fonts/DualOne.ttf	FAIL" \
  "$FX/system/fonts/DualTwo.ttf	FAIL" \
  "$FX/system/fonts/MultiLangEmoji.ttf	FAIL" \
  "$FX/system/fonts/NotoColorEmoji.ttf	OK" \
  "$FX/system/fonts/CompactEmoji.ttf	ABSENT" \
  "$FX/system/fonts/SpanEmoji.ttf	OK" \
  "$FX/system/fonts/VendorNewEmoji.ttf	FAIL" | sort)" \
  "$(run check | sort)"

# --- post-fs-data.sh end-to-end on the host (mock mount, env overrides) ----
# $WORK/module doubles as the module dir: bin/emoji-slots.sh, the font and a
# module.prop are in place; run.sh (a mount-mock preamble + the real
# post-fs-data.sh) sits at its root so MODDIR resolves to $WORK/module.
# CompactEmoji stays removed (absent slot).
printf 'description=initial\n' > "$WORK/module/module.prop"
printf 'mount() { echo "$3" >> "%s/mount.calls"; cp "$2" "$3"; }\n' "$WORK" > "$WORK/module/run.sh"
cat "$ROOT/module/post-fs-data.sh" >> "$WORK/module/run.sh"
export EMOJI_SLOTS_READ_ROOT="$FX" EMOJI_SLOTS_EMIT_ROOT="$FX"
rm -f "$WORK/mount.calls"
FIRST=$(bash "$WORK/module/run.sh"; grep '^description=' "$WORK/module/module.prop")
assert_eq "post-fs-data: mounts every existing slot, reports active (7/7)" \
  "✅ Twemoji active (7/7 emoji fonts). Systemless Twemoji on KernelSU/SukiSU/APatch; Magic Mount on Magisk." \
  "${FIRST#description=}"
assert_eq "post-fs-data: mounted slots now serve the module font" "7" \
  "$(for f in "$FX/system/fonts/NotoColorEmoji.ttf" "$FX/system/fonts/DualOne.ttf" \
              "$FX/system/fonts/DualTwo.ttf" "$FX/system/fonts/SpanEmoji.ttf" \
              "$FX/system/fonts/MultiLangEmoji.ttf" "$FX/system/fonts/VendorNewEmoji.ttf" \
              "$FX/product/fonts/ProductEmoji.ttf"; do
       cmp -s "$WORK/module/system/fonts/NotoColorEmoji.ttf" "$f" && echo ok
     done | grep -c ok)"
MOUNTS_AFTER_FIRST=$(grep -c . "$WORK/mount.calls")
bash "$WORK/module/run.sh" >/dev/null
assert_eq "post-fs-data: second run is a no-op (cmp guard)" "$MOUNTS_AFTER_FIRST" "$(grep -c . "$WORK/mount.calls")"
unset EMOJI_SLOTS_READ_ROOT EMOJI_SLOTS_EMIT_ROOT

# --- shell syntax of every shipped script ---------------------------------
for f in module/bin/emoji-slots.sh module/post-fs-data.sh module/install.sh \
         module/META-INF/com/google/android/update-binary; do
  if bash -n "$ROOT/$f" 2>/dev/null; then echo "PASS: syntax $f"; else
    echo "FAIL: syntax $f"; fails=$((fails+1)); fi
done

rm -rf "$WORK"
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILURE(S)"; exit 1; fi
