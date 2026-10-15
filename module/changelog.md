# v17.0.3 (59)

- Fixed the versionCode mismatch: the build-58 zip installed as versionCode 57 while the update channel advertised 58, so managers kept offering the same update after installation. Release consistency is now machine-checked before every package (tests/build_package.py)
- Centralized emoji-slot discovery in `bin/emoji-slots.sh`, shared by the installer, the boot self-mount and the WebUI. The previous line-based sed range could, on non-pretty-printed `fonts.xml` layouts, swallow the font of the family following the emoji family (mounting the emoji font over a body font), keep only the last of several fonts on one line, or miss fonts whose tags span lines
- Font configs are now unioned instead of "first non-empty wins": a ROM that reads `font_fallback.xml` (Android 15+ `newFontsFallbackXml`) while a legacy `fonts.xml` also exists no longer leaves new-config slots stock, and OEM emoji declared in `/product/etc/fonts_customization.xml` is covered too
- WebUI: fixed the live self-check, which never worked over a real manager bridge — the generated shell command was syntactically invalid (`do;`/`then;` from `;`-joining), and the official KernelSU native `exec()` returns stdout as a plain string rather than an object; both the check and the module.prop fallback now adapt to either interface, and the version line is filled in on a successful live check
- WebUI: the page no longer aborts when `Intl.Segmenter` is unavailable (old WebViews fall back to a regex grapheme approximation)
- Corrected the boot-script/README ordering note: on Magisk, post-fs-data scripts run before Magic Mount applies module overlays, not after
- Font provenance verified: the bundled font was built from jdecked/twemoji v17.0.2 via twemoji-color-font; upstream v17.0.3 changed no emoji assets (tooling-only release), so the glyph content is identical to v17.0.3 — the name-table string 17.0.2 reflects the build source, not a content gap

# v17.0.3 (58)

- Bundled LICENSE (GPLv3) and NOTICE (Twemoji artwork CC-BY 4.0 attribution + font build credits) inside the module package, so the distributed zip carries its own licensing information
- Removed a stray test screenshot that had leaked into webroot/

# v17.0.3 (57)

- WebUI: live, detailed self-check — per-slot verification (serving Twemoji / stock font / absent) with a progress bar, running the same logic as the boot-time check through the manager's root shell bridge, with graceful fallback to the boot-time description

# v17.0.3 (56)

- WebUI: force emoji presentation (VS16) on legacy text-default symbols — they rendered as monochrome outlines in the gallery, which looked like a partial replacement even though the system font was correctly replaced

# v17.0.3 (55)

- Fixed the WebUI "Open" button not appearing in the manager: the installer did not extract `webroot/` into the installed module directory (build 54 shipped the file in the zip but never installed it)

# v17.0.3 (54)

- Fixed partial emoji replacement: the font-slot parser now tolerates OEM `fonts.xml` variants (multi-language `lang` attributes, fonts with extra attributes like `toneId`), so vendor emoji fonts no longer survive as partial fallbacks
- Added a WebUI ("Open" button in the manager's module list): browse all emoji by category to verify the replacement — rendered with the actual system font
- Show the build number in the module version, e.g. `v17.0.3 (54)`; the version tracks upstream Twemoji releases

# v17.0.3 (53)

- Twemoji 17.0.3 (Emoji 17.0 / Unicode 17.0)
- Added in-app update check support (`updateJson`) for KernelSU, SukiSU, APatch and Magisk
- Added live status in the module description at boot (✅ active / ⚠️ partial / ❌ not active)
- Self-mount on KernelSU/SukiSU/APatch without a mount metamodule; native Magic Mount on Magisk
