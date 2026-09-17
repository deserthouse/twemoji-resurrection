# Twemoji Resurrection

Systemlessly replaces your Android system emoji with **Twemoji** (Twitter Emoji), currently shipping **Twemoji 17.0.3** (Emoji 17.0).

![WebUI: live self-check and emoji gallery](webui-preview.png)

## Compatibility

| Root manager | Mounting |
| --- | --- |
| KernelSU / SukiSU / APatch (bare, no mount metamodule) | Module **self-mounts** via `post-fs-data.sh` bind-mounts |
| Magisk | Native Magic Mount |
| KernelSU / SukiSU with a Magic Mount / OverlayFS metamodule | Metamodule mounts; self-mount is a verified no-op |

Both mounting paths can coexist safely: the self-mount checks whether the target font already serves the module's Twemoji file before mounting.

## Installation

1. Download `Twemoji-Resurrection-<version>-ksu.zip` from [Releases](https://github.com/deserthouse/twemoji-resurrection/releases).
2. Flash it from your root manager's module page.
3. Reboot.

A system font change is only picked up on reboot (the font cache is built at boot).

## Features

- **In-app update check** — the module ships an `updateJson`, so KernelSU, SukiSU, APatch and Magisk managers offer the new version directly from the module list.
- **Live status in the module description** — at every boot the module verifies that every emoji font slot actually serves Twemoji and rewrites its own description:
  - `✅ Twemoji active (n/n emoji fonts)` — fully working
  - `⚠️ Twemoji partial (x/n emoji fonts)` — some slots not overridden
  - `❌ Twemoji not active` — mounting failed; check your manager's mount settings
- **WebUI** — tap **Open** on the module in KernelSU / SukiSU / APatch (or Magisk with WebUIX) to browse all emoji by category. Everything is rendered by the *current system emoji font*, so it doubles as a live verification that the replacement took effect.
- **WebUI live self-check** — the WebUI re-runs the boot-time verification on demand and shows it in detail: a progress bar plus one row per emoji font slot on the system (`serving Twemoji` / `still the stock font` / `not present`), via the manager's root shell bridge. Without a bridge it falls back to the boot-time description.

## How it works

The module drops a CBDT/CBLC Twemoji build of `NotoColorEmoji.ttf` into `system/fonts` and symlinks every emoji font declared in the system font config (`fonts.xml`, or `font_fallback.xml` on Android 15+) to it, so all `und-Zsye` slots resolve to Twemoji.

## Disclaimer & AI statement

- **Disclaimer**: This module modifies the system emoji font at your own risk. The authors are not responsible for any boot loops, rendering glitches or other issues — always keep a working backup before flashing.
- **AI statement**: All work on this module — code, packaging, documentation and releases — was produced by AI.

## Credits

Project lineage:

- **Xyllon** — the original [Twemoji Magisk module](https://xdaforums.com/t/module-twemoji-twitter-emoji-12-1-2.3688251/) (2017), which started it all.
- **Gontier Julien** (Codeberg: [Snowy](https://codeberg.org/Snowy/Twemoji-Remastered), formerly [Gontier-Julien](https://github.com/Gontier-Julien/Twemoji-Remastered) on GitHub) — [Twemoji Remastered](https://codeberg.org/Snowy/Twemoji-Remastered), the direct upstream this project continues (2022–2025).
- **deserthouse** — Twemoji Resurrection (2026–present).

Also thanks to **Twitter / X and the Twemoji contributors** for the emoji artwork, and to the [twemoji-color-font](https://github.com/13rac1/twemoji-color-font) project for the CBDT/CBLC font packaging.

## License

The module scripts are licensed under the [GNU GPL v3](LICENSE).

The bundled font and the Twemoji artwork it contains are **not** covered by that license and remain under their original terms:

- Twemoji artwork: [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/) — © 2014–2021 Twitter; © 2022–present the [Twemoji](https://github.com/jdecked/twemoji) maintainers.
- Bundled `NotoColorEmoji.ttf`: built by [twemoji-color-font](https://github.com/13rac1/twemoji-color-font), whose font files are licensed CC-BY 4.0 (© 2016–2024 Brad Erickson, © 2022–present Jason Sofonia & Justine De Caires, © 2014–2021 Twitter).
