# 项目状态

更新：2026-10-15（下午）。Sol 审查（R1–R6）六项已全部修复，本地测试全绿（解析器/集成 13 断言、WebUI 7 断言、打包门禁 PASS）；**设备回归与发布未执行，待用户批准**。当前版本 v17.0.3 (59)（versionCode=59）。

## 系统架构

Android systemless Twemoji 字体替换模块。槽位发现单一事实源 = `module/bin/emoji-slots.sh`（`fonts.xml` + `font_fallback.xml` + `/product/etc/fonts_customization.xml` 三源并集、全路径输出，`list`/`check` 两模式）：install.sh 消费 `list` 建逐槽 symlink（供 Magic Mount）；post-fs-data.sh 消费 `list` 自挂载并回写三态描述；WebUI 经管理器 root bridge 消费 `check`（execOut 适配原生 String / 包装器对象双返回形态）。Magisk 时序口径已修正：post-fs-data 先于 Magic Mount，自挂载先行、Magic Mount 随后叠同内容。

## 已实现功能

- Twemoji CBDT/CBLC 字体分发与三源槽位替换（含 /product OEM 覆盖）。
- 自挂载 + cmp 守卫（幂等，二次运行为 no-op，集成测试验证）；多管理器共存安全。
- 开机三态状态，分母只计实际存在的槽。
- WebUI 画廊（Intl.Segmenter 守卫 + 正则降级；画廊故障不阻断自检）、实时检查（单命令）、降级读取；实时检查成功时补版本号。
- 更新通道与包内许可（NOTICE 含 Tyler O'Neill 补署）；发布一致性门禁 `tests/build_package.py`（版本六处一致 + zipUrl 资产名 + zip=git 跟踪清单；build 58 versionCode 57/58 错位事故的防再发）。
- 字体身份已核验：字体系 jdecked/twemoji v17.0.2 经 twemoji-color-font 构建；上游 v17.0.2↔v17.0.3 零 emoji 资产差异 ⇒ 内容等价，版本宣称 v17.0.3 成立（name 表 17.0.2 是构建来源串，非内容缺口；证据链见 changelog build 59 条目）。

## TODO

1. 设备回归（待批准）：CleanA36（Magisk）走真实安装器刷 build 59 → 冷启 → 三态描述 → WebUI 画廊；toybox sed/tr 对新解析管线的实机验证；KSU 系真机验证 bridge 实时自检（历史从未真正工作过，R3/R4 修复后首验）。
2. 发布 build 59：`build_package.py --out <repo根>/Twemoji-Resurrection-17.0.3-ksu.zip` → commit → push main → 同 tag v17.0.3 替换 Release 资产 + 标题/正文改 (59)（PATCH API）→ 核对 raw update.json 与资产 URL/哈希。
3. 已知边界（README 已披露）：/data/fonts 可更新字体机制不在覆盖范围。

## 核心文件拓扑

| 路径 | 职责 |
|---|---|
| module/bin/emoji-slots.sh | 槽位发现与逐槽检查（单一事实源；EMOJI_SLOTS_READ_ROOT/EMIT_ROOT 覆写供测试与 recovery 镜像读取） |
| module/install.sh | 安装回调、解包（system/bin/post-fs-data/webroot）、逐槽 symlink（/system 与 /product）与权限 |
| module/post-fs-data.sh | 启动自挂载与模块描述回写 |
| module/webroot/index.html | 表情画廊与状态展示（bridge 双形态、Segmenter 降级、DOM 故障隔离） |
| module/system/fonts/NotoColorEmoji.ttf | 字体数据（jdecked 17.0.2 构建，内容≡17.0.3） |
| module/META-INF/com/google/android/ | legacy 安装器入口和 MAGISK 标记 |
| module/module.prop、update.json、changelog.md | 版本与更新元数据（v17.0.3 (59)） |
| module/LICENSE、NOTICE | 分发许可和署名 |
| README.md、README_EN.md | 双语说明（时序/并集解析 2026-10-15 修正） |
| tests/test_emoji_slots.sh | 解析器 + post-fs-data 集成回归（吞字体/漏字体/跨行/并集/产品源/幂等，13 断言） |
| tests/test_webui.cjs | WebUI 回归（bridge 双形态/降级/Segmenter 缺失/DOM 故障隔离，7 断言） |
| tests/build_package.py | 打包 + 发布一致性门禁 |
| tests/audit_functional.cjs、audit_package.py | 2026-10-15 审查的历史证据（复现修复前缺陷，对修复后代码预期 FAIL/失配；audit_package 读根目录旧 zip，发布 59 后恢复一致） |
| tests/fixtures/ | 解析器测试夹具（三种字体配置的排版变体） |
| tests/REVIEW-2026-10-15.md | 审查报告原文 |

设备未连接；发布未执行。本地断言通过 = 修复自测，不代表设备回归完成。
