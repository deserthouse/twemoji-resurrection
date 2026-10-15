# 项目状态

更新：2026-10-15（晚）。Sol 审查六项（R1–R6）全部修复 **且设备回归通过、build 59 已发布**。当前线上：Release v17.0.3 (59)（资产 sha256 `82c02a1dae4…`，与设备实测包逐字节一致）、update.json versionCode=59。剩余唯一开放项：SukiSU 真机 WebUI bridge 实测（需用户协调，见 TODO）。

## 验证记录（2026-10-15，Twemoji_A16_root）

- 实例：现做 `Twemoji_A16_root`（pixel_7 / android-36 google_apis；共享镜像自带 Magisk 30.6 补丁，无需 rootAVD；Magisk App 官方 30.6 配对 + additional setup 转正）。部署法已回填 AVD 手册第三节。
- 真安装器：Magisk App 同源 `module_installer.sh`（assets 内，调 `install_module`）刷入 build 59 zip → banner 正确、bin/webroot/post-fs-data 解包齐全、跨槽 symlink 建立（NotoColorEmojiFlags/Legacy → NotoColorEmoji.ttf）。
- 开机：modules_update 激活、post-fs-data 回写 `✅ Twemoji active (2/2)`（Legacy 槽 post-fs-data 阶段尚不存在被正确排除，Magic Mount 阶段经 symlink 生效）；挂载表呈自挂载 rw + Magic Mount ro 共存；toybox 下 `emoji-slots.sh list/check` 三槽全 OK。
- 稳定：3 轮 `adb reboot` 各 ~35s，crash buffer 零命中，每轮描述活回写。
- 视觉：Magisk 管理器模块页显示 `Twemoji Resurrection v17.0.3 (59)` + ✅ 描述 + **Update 灰（无更新可提，R5 死循环终结的设备端实证）**；WebUI 画廊（Chrome 无 bridge 降级文案正确）全程 Twemoji 美术，红鸟标记实锤。

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

1. SukiSU 真机（需用户协调朋友设备）：WebUI bridge 实时自检的首次真机验证（R3/R4 修复后从未在真 bridge 上跑过；装 build 59 后点开 WebUI 应见 "✅ active — all n/n" + 版本号 + 逐槽清单）。可选同批：Magisk+WebUIX bridge 路径。
2. 文档小尾巴：README 双语兼容表仍写"Magisk 管理器链路待 rooted 实例验证"——2026-10-15 已在 Twemoji_A16_root 实证通过，属保守方向的过时陈述，下次提交顺手更新（zh+en 各一行）。
3. 可选：A15 及以下降级兼容加验（union 解析理论覆盖，未实测；用户未表态）。
4. 上游 Twemoji 出新版本时随更（版本锁 v17.x.y，build 递增；流程=改字体+四处版本+`tests/build_package.py` 门禁+同 tag 换资产）。
5. 已知边界（README 已披露，不计划处理）：/data/fonts 可更新字体机制；App 内置 emoji。

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

2026-10-15：Magisk 链路设备回归完成、build 59 已发布并全链核验（资产/通道/Release 三对齐）。KSU 系真机 bridge 验证待用户协调。本地断言（20 项）+ 设备回归（安装器/开机/挂载/toybox/视觉）双绿。
