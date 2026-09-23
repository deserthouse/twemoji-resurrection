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
