<div align="center">

# Twemoji Resurrection

**Systemless Twemoji (Twitter emoji) replacement for Android — Magisk / KernelSU / APatch**

Resurrecting and maintaining the abandoned Twemoji system font replacement — currently Twemoji 17.0.3 (Emoji 17.0 / Unicode 17.0)

[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](#-compatibility)
[![Type](https://img.shields.io/badge/Type-Root%20Module-orange.svg)](#-installation)
[![Release](https://img.shields.io/github/v/release/deserthouse/twemoji-resurrection?include_prereleases&color=yellow&style=flat-square)](https://github.com/deserthouse/twemoji-resurrection/releases)

[简体中文](README.md) · [English](README_EN.md)

</div>

---

> **Twemoji Resurrection** is a root module that replaces your system emoji font with **Twemoji** (Twitter emoji), systemlessly — no system partition is modified, and removing the module restores everything after a reboot. It continues the lineage of Xyllon (2017) and Twemoji Remastered (2022–2025), fixing five inherited defects (Android 15+ breakage, OEM font-config parsing, partial fallback, no update channel, no KernelSU-family support).

## ✨ Features

### Mounting matrix

| Root manager | Mounting |
|---|---|
| Magisk | Native Magic Mount |
| KernelSU / APatch (bare, no mount metamodule) | `post-fs-data.sh` **self-mounts** via per-slot bind-mounts |
| KernelSU with a Magic Mount / OverlayFS metamodule | Metamodule mounts; the self-mount is a verified no-op |

Both mounting paths can coexist safely: before mounting, the self-mount checks whether the target slot already serves Twemoji and leaves it alone if so.

### Three-state self-check

At every boot the module verifies **which font file each emoji font slot actually serves**, and rewrites its own description — what you see in the manager's module list is the real status, not "installed counts as working":

- `✅ Twemoji active (n/n emoji fonts)` — fully working
- `⚠️ Twemoji partial (x/n emoji fonts)` — some slots still serve the stock font
- `❌ Twemoji not active` — mounting failed; check your manager's mount settings

The denominator only counts slots that exist on the device — declared-but-absent fonts (e.g. `NotoColorEmojiLegacy.ttf` on recent Android) are excluded, so there is no permanent ⚠️ false alarm.

### More

- 🖼️ **WebUI emoji gallery** — tap **Open** on the module in KernelSU / APatch (or Magisk with WebUIX) to browse all emoji by category; the gallery is rendered by the *current system emoji font*, so it doubles as a live verification that the replacement took effect
- 🔬 **WebUI live self-check** — re-runs the boot-time verification on demand through the manager's root shell bridge, showing one row per slot (serving Twemoji / still the stock font / not present) with a progress bar; falls back gracefully to the boot-time description without a bridge
- 🔄 **In-app update check** — ships an `updateJson`, so KernelSU, APatch and Magisk managers offer new versions directly from the module list

## 📸 Screenshots

<p float="left">
  <img src="webui-preview.png" width="270" alt="WebUI emoji gallery and live self-check"/>
  <img src="docs-a16-proof.png" width="270" alt="Boot-time status written into the module description (emulator)"/>
</p>

## 🚀 Installation

**[📥 Get the latest release from Releases](https://github.com/deserthouse/twemoji-resurrection/releases)** (`Twemoji-Resurrection-<version>-ksu.zip`)

### Requirements

- Any root solution: Magisk / KernelSU / APatch

### Steps

1. Flash the zip from your root manager's module page
2. Reboot
3. Check the module description: `✅ Twemoji active` means it's working

The font cache is built at boot — **a system font change only takes effect after a reboot**.

## ❓ FAQ

**Flashed and rebooted, but the emoji didn't change?**
Check the module's three-state description first: `❌ not active` means mounting failed — check your manager's module mount settings. If it shows `✅` but emoji look unchanged, make sure you're not looking at an app that bundles its own emoji (see next question). And confirm you actually rebooted — nothing applies without one.

**WhatsApp / Telegram / Gboard emoji didn't change?**
Those apps bundle their own emoji fonts and don't use the system font — no systemless module can replace them. This is expected behavior.

**What does `⚠️ partial` mean?**
Some emoji font slots still serve the stock font. The upstream OEM `fonts.xml` parsing issue (multi-language `lang` attributes and extra attributes like `toneId` letting vendor emoji fonts survive as fallbacks) is already fixed here; a remaining partial state is a device-specific OEM difference — feel free to open an issue with your font config attached.

**How does this relate to Twemoji Remastered?**
It's the direct upstream. Lineage: Xyllon (2017, XDA) → Gontier Julien / Snowy's Twemoji Remastered (2022–2025; the true upstream lives on [Codeberg](https://codeberg.org/Snowy/Twemoji-Remastered) — the GitHub Gontier-Julien repo is an outdated mirror stuck at v15.1.0) → this project (2026– ).

**Does it modify the system partition?**
No. Everything happens through systemless mounts; removing the module and rebooting restores the system to its original state.

**What does the version `v17.0.3 (57)` mean?**
The version tracks upstream Twemoji (17.0.3); the number in parentheses is the module's own build number — font updates and module iterations are counted separately.

## 📊 Compatibility

| Item | Status |
|---|---|
| Root managers | Magisk / KernelSU / APatch (see the mounting matrix) |
| Android versions | No hard minimum; Android 15+ automatically parses `font_fallback.xml` instead |
| OEM ROMs | The parser tolerates OEM `fonts.xml` variants (multi-language `lang` attributes, extra font attributes) |
| Verified | End-to-end on an AOSP emulator (API 36); ✅ on a KernelSU-family real device |

## 🛠️ How it works

```
Boot · post-fs-data stage
  │
  ├─ Parse the system font config (fonts.xml; font_fallback.xml on Android 15+)
  │     └─ Collect every und-Zsye (emoji) font slot — tolerant of OEM variants,
  │        so vendor emoji fonts don't slip through
  │
  ├─ Make every slot serve the Twemoji font (CBDT/CBLC build of NotoColorEmoji.ttf)
  │     ├─ Magisk ──────────────▶ Magic Mount overlay already in place (per-slot symlinks created at install)
  │     └─ KSU / APatch ─▶ post-fs-data.sh self-mounts each slot via bind-mount
  │                                   └─ cmp -s guard: no-op if the slot already serves Twemoji (safe coexistence)
  │
  └─ Verify what each slot actually serves → rewrite the module description
        └─ ✅ active (n/n) · ⚠️ partial (x/n) · ❌ not active
```

- At install time, a symlink is created in the module directory for every font slot parsed back then (for Magic Mount to map); at boot, the config is parsed again and each slot is bind-mounted (the KSU-family self-mount) — two paths, same outcome: every emoji slot resolves to Twemoji
- The CBDT/CBLC bitmap format matches the AOSP system emoji font, so it drops in without touching the font config

## 🤝 Credits

Project lineage:

- **Xyllon** — the original [Twemoji Magisk module](https://xdaforums.com/t/module-twemoji-twitter-emoji-12-1-2.3688251/) (2017), which started it all
- **Gontier Julien** (Codeberg: [Snowy](https://codeberg.org/Snowy/Twemoji-Remastered)) — [Twemoji Remastered](https://codeberg.org/Snowy/Twemoji-Remastered) (2022–2025), the direct upstream this project continues
- **deserthouse** — Twemoji Resurrection (2026– )

Also thanks to **Twitter / X and the Twemoji contributors** for the emoji artwork, and to the [twemoji-color-font](https://github.com/13rac1/twemoji-color-font) project for the CBDT/CBLC font packaging.

## ⚠️ Disclaimer

> This is a **hobby project by an individual**, provided "as is", without warranty of any kind.
>
> - **No functional guarantee**: nothing is guaranteed to work on your device, ROM or system version; vendor-specific behavior on custom ROMs may cause differences.
> - **No development commitment**: no commitment is made regarding future plans, schedules, or continued maintenance; the project may slow down, pause or be archived at any time.
> - **Use at your own risk**: this module replaces the system emoji font; any consequences (including but not limited to rendering glitches) are borne by the user — keep a working backup before flashing. Rooting itself carries risk; evaluate it yourself.
> - **No affiliation**: this project is not affiliated with Twitter / X, Google, Android, or any vendor/project mentioned here; all trademarks belong to their respective owners.
> - **Use is your own decision**: how the project is used is up to the user; the developer is not responsible for any misuse.

## 🤖 AI Disclosure

> This project was developed with deep AI (LLM) involvement — including architecture design, code implementation, testing and documentation; the human ([@deserthouse](https://github.com/deserthouse)) set the requirements, performed acceptance, and holds final decision-making authority.

## ⚖️ License

The module scripts are licensed under [GPL-3.0](LICENSE).

The bundled font and the Twemoji artwork it contains are **not** covered by that license and remain under their original terms:

- Twemoji artwork: [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/) — © 2014–2021 Twitter; © 2022–present the [Twemoji](https://github.com/jdecked/twemoji) maintainers
- Bundled `NotoColorEmoji.ttf`: built by [twemoji-color-font](https://github.com/13rac1/twemoji-color-font), whose font files are licensed CC-BY 4.0 (© 2016–2024 Brad Erickson, © 2022–present Jason Sofonia & Justine De Caires, © 2014–2021 Twitter)

---

<div align="center">

If this project helps you, a ⭐ Star is appreciated

</div>
