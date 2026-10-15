<div align="center">

# Twemoji Resurrection

**Android 系统 Twemoji（Twitter 表情）替换模块 —— systemless，兼容 Magisk / KernelSU / APatch**

复活并延续停更的 Twemoji 系统字体替换 —— 当前 Twemoji 17.0.3（Emoji 17.0 / Unicode 17.0）

[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](#-兼容性)
[![Type](https://img.shields.io/badge/Type-Root%20Module-orange.svg)](#-安装使用)
[![Release](https://img.shields.io/github/v/release/deserthouse/twemoji-resurrection?include_prereleases&color=yellow&style=flat-square)](https://github.com/deserthouse/twemoji-resurrection/releases)

[简体中文](README.md) · [English](README_EN.md)

</div>

---

> **Twemoji Resurrection** 是一个 root 模块：以 systemless 方式把系统 emoji 字体整体替换为 **Twemoji**（Twitter 表情）——不修改系统分区，删除模块重启即还原。项目延续 Xyllon（2017）与 Twemoji Remastered（2022–2025）的谱系，并修复了上游遗留的五项缺陷（Android 15+ 失效、OEM 配置解析、部分回退、更新通道、KernelSU 系支持）。

## ✨ 功能特性

### 挂载矩阵

| Root 管理器 | 挂载方式 |
|---|---|
| Magisk | 原生 Magic Mount |
| KernelSU / APatch（无挂载 metamodule） | `post-fs-data.sh` **自挂载**（逐槽 bind-mount） |
| KernelSU + Magic Mount / OverlayFS metamodule | metamodule 挂载；自挂载经守卫验证为 no-op |

两条挂载路径可以安全共存：自挂载前会先确认目标槽当前服务的字体，已经是 Twemoji 就不再动手。

### 三态自检

每次开机，模块逐槽校验**每个 emoji 字体槽实际服务的字体文件**，并把结果写进自己的描述——你在管理器模块列表里看到的是真实状态，而不是「装了就算成功」：

- `✅ Twemoji active (n/n emoji fonts)` —— 全部槽位生效
- `⚠️ Twemoji partial (x/n emoji fonts)` —— 部分槽位仍是原厂字体
- `❌ Twemoji not active` —— 挂载失败，检查管理器挂载设置

分母只统计设备上实际存在的槽——声明了但设备没有的字体（如新版 Android 的 `NotoColorEmojiLegacy.ttf`）不计入，不会产生永久的 ⚠️ 假警报。

### 其他特性

- 🖼️ **WebUI 表情画廊** —— 在 KernelSU / APatch（或装 WebUIX 的 Magisk）里点模块的「打开」，按分类浏览全部表情；画廊用**当前系统 emoji 字体**渲染，本身就是替换是否生效的直观验证
- 🔬 **WebUI 实时自检** —— 经管理器 root shell bridge 现场重跑开机校验，逐槽展示（已服务 Twemoji / 仍为原厂 / 设备无此槽）并配进度条；无 bridge 时优雅回退到开机描述
- 🔄 **应用内更新检查** —— 内置 `updateJson`，KernelSU / APatch / Magisk 的管理器都能在模块列表直接提示新版本

## 📸 界面预览

<p float="left">
  <img src="webui-preview.png" width="270" alt="WebUI 表情画廊与实时自检"/>
  <img src="docs-a16-proof.png" width="270" alt="开机自检写入的模块描述（模拟器验证）"/>
</p>

## 🚀 安装使用

**[📥 前往 Releases 下载最新版本](https://github.com/deserthouse/twemoji-resurrection/releases)**（`Twemoji-Resurrection-<version>-ksu.zip`）

### 环境要求

- 任意 root 方案：Magisk / KernelSU / APatch

### 步骤

1. 在管理器模块页刷入 zip
2. 重启
3. 检查模块描述：`✅ Twemoji active` 即生效

字体缓存在开机时构建——**系统字体的改动必须重启才生效**。

## ❓ 常见问题

**刷入重启后表情没变？**
先看模块描述三态：`❌ not active` 说明挂载没起来，检查管理器的模块挂载设置；`✅` 但表情没变，确认你看的不是 App 内置表情（见下条）。另外确认真的重启过——不重启不生效。

**WhatsApp / Telegram / Gboard 的表情没变？**
这些 App 自带 emoji 字体、不使用系统字体，任何 systemless 模块都替换不了——属预期行为。

**`⚠️ partial` 是什么？**
部分 emoji 字体槽仍在服务原厂字体。上游遗留的 OEM `fonts.xml` 变体解析问题（多语言 `lang` 属性、`toneId` 等额外属性导致 OEM 私有 emoji 字体漏网成为回退）已在本项目修复；仍出现 partial 属个别 OEM 差异，可提 issue 附上你的字体配置。

**和 Twemoji Remastered 是什么关系？**
直接上游。谱系：Xyllon（2017，XDA）→ Tyler O'Neill（2019，槽位解析与 symlink 技巧）→ Gontier Julien / Snowy 的 Twemoji Remastered（2022–2025，真上游在 [Codeberg](https://codeberg.org/Snowy/Twemoji-Remastered)，GitHub 上的 Gontier-Julien 是停在 v15.1.0 的过时镜像）→ 本项目（2026– ）。

**会修改系统分区吗？**
不会，全部通过 systemless 挂载实现；删除模块并重启即完全还原系统原状。

**版本号 `v17.0.3 (59)` 是什么意思？**
版本号跟随上游 Twemoji（17.0.3），括号内是模块自身构建号——字体版本与模块迭代分开计数。

## 📊 兼容性

| 项目 | 支持情况 |
|---|---|
| Root 管理器 | Magisk / KernelSU / APatch（见挂载矩阵） |
| Android 版本 | 未设硬性下限；并集解析 `fonts.xml` + `font_fallback.xml`（Android 15+）+ `/product` OEM 覆盖 |
| OEM ROM | 解析器容忍 OEM `fonts.xml` 变体（多语言 `lang` 属性、额外字体属性、非标准排版） |
| 已验证 | AOSP 模拟器（API 36）端到端；KernelSU 系真机 ✅ |

## 🛠️ 工作原理

```
开机 · post-fs-data 阶段（系统字体缓存构建前）
  │
  ├─ bin/emoji-slots.sh：提取全部 und-Zsye（emoji）字体槽（三源并集）
  │     ├─ /system/etc/fonts.xml + /system/etc/font_fallback.xml
  │     │    （ROM 实际读哪份由构建期决定，并集两种都覆盖）
  │     └─ /product/etc/fonts_customization.xml（OEM 产品覆盖）
  │
  ├─ 让每个槽都服务 Twemoji 字体（CBDT/CBLC 构建的 NotoColorEmoji.ttf）
  │     ├─ KSU / APatch ─▶ overlay 已就位 → cmp -s 守卫确认为 no-op；
  │     │                  无 metamodule 时逐槽 bind-mount 自挂载
  │     └─ Magisk ─▶ post-fs-data 运行于 Magic Mount 之前：先逐槽 bind-mount，
  │                  随后 Magic Mount 把同一字体叠到相同槽位（殊途同归）
  │
  └─ 逐槽校验实际服务的文件 → 回写模块描述
        └─ ✅ active (n/n) · ⚠️ partial (x/n) · ❌ not active
```

- 安装时按当时解析到的字体槽，在模块目录里为每个槽建 symlink（供 Magic Mount 映射）；开机时再实时解析并逐槽 bind-mount（供 KSU 系自挂载与 Magisk 早期挂载）——两条路径互为冗余：所有 emoji 槽都解析到 Twemoji
- 安装、开机挂载与 WebUI 自检共用同一份 `bin/emoji-slots.sh` 做槽位发现——单一事实源，三处不会漂移
- CBDT/CBLC 位图格式与 AOSP 系统 emoji 字体同构，直接替换无需改动字体配置
- 已知边界：系统「可更新字体」机制（`/data/fonts` 下动态下发的字体更新）优先级高于系统目录，不在本模块覆盖范围内

## 🤝 致谢

项目谱系：

- **Xyllon** —— 原始 [Twemoji Magisk 模块](https://xdaforums.com/t/module-twemoji-twitter-emoji-12-1-2.3688251/)（2017），一切的起点
- **Tyler O'Neill** —— fonts.xml 槽位解析与逐槽 symlink 的安装技巧（2019），本模块挂载手法的源头
- **Gontier Julien**（Codeberg：[Snowy](https://codeberg.org/Snowy/Twemoji-Remastered)）—— [Twemoji Remastered](https://codeberg.org/Snowy/Twemoji-Remastered)（2022–2025），本项目直接延续的上游
- **deserthouse** —— Twemoji Resurrection（2026– ）

同时感谢 **Twitter / X 与 Twemoji 贡献者**的表情美术，以及 [twemoji-color-font](https://github.com/13rac1/twemoji-color-font) 项目提供的 CBDT/CBLC 字体打包。

## ⚠️ 免责声明 / Disclaimer

> 本项目为**兴趣使然的个人作品**，按「现状」提供，不含任何明示或默示的担保。
>
> - **功能不保证**：不保证任何功能在您的设备、ROM 或系统版本上正常运行；定制 ROM 的私有行为可能造成差异。
> - **无开发承诺**：不对后续的开发计划、排期或是否继续维护作任何承诺；项目可能随时放缓、暂停或归档。
> - **风险自担**：本模块替换系统 emoji 字体；使用产生的任何后果（包括但不限于渲染异常）由使用者自行承担，刷入前请保留可用备份；启用 root 本身存在风险，请自行评估。
> - **无关联声明**：本项目与 Twitter / X、Google、Android 及文中提及的任何厂商/项目无隶属关系；各商标归其各自所有者所有。
> - **用途自决**：项目用途由使用者自行决定，开发者不对任何滥用行为负责。

## 🤖 AI 使用声明 / AI Disclosure

> 本项目由 AI（大语言模型）深度参与开发——包括架构设计、代码实现、测试与文档；人类（[@deserthouse](https://github.com/deserthouse)）提出需求、进行验收并拥有最终决策权。

## ⚖️ 开源协议

模块脚本采用 [GPL-3.0](LICENSE) 协议开源。

随模块分发的字体与其中包含的 Twemoji 美术**不**在 GPL 覆盖范围内，保持原条款：

- Twemoji 美术：[CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/) —— © 2014–2021 Twitter；© 2022–至今 [Twemoji](https://github.com/jdecked/twemoji) 维护者
- 内置 `NotoColorEmoji.ttf`：由 [twemoji-color-font](https://github.com/13rac1/twemoji-color-font) 构建，字体文件以 CC-BY 4.0 授权（© 2016–2024 Brad Erickson，© 2022–至今 Jason Sofonia & Justine De Caires，© 2014–2021 Twitter）

---

<div align="center">

如果这个项目对你有帮助，欢迎 ⭐ Star 支持

</div>
