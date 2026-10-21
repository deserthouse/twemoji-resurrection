# 项目状态

更新：2026-10-19。build 59 的原 20 项回归与本地打包检查通过，原 R3/R5/R6 及 R4 返回形态问题已修复；复审新增 **1 项 P1、3 项 P2 功能问题**，不能再按“全部关闭”验收。当前本地包 versionCode=59，12 个文件与 module 工作区一致；2026-10-15 的发布/设备回归记录保留如下，本轮未重新核验在线资产或设备。新意见见 [2026-10-19 复审报告](tests/REVIEW-2026-10-19.md)。

> 2026-10-19 归档备注：本会话仅做归档，无代码变更。会话结束时宿主 Bash 工具损坏（`spawn C:\Program Files\Git\bin\bash.exe ENOENT`，主会话与子代理均无法起 shell，疑似 Git for Windows 被移动/卸载或本会话 cwd 所在的旧 `Twemoji-Revived` 目录已删除），所有清理与设备操作（杀模拟器、删临时文件、清理 8123 端口进程）**均未执行**。恢复方法：在 `Twemoji-Resurrection` 目录重开 ZCode；若仍报错则重装 Git for Windows。

## 验证记录（2026-10-15，Twemoji_A16_root）

- 实例：现做 `Twemoji_A16_root`（pixel_7 / android-36 google_apis；共享镜像自带 Magisk 30.6 补丁，无需 rootAVD；Magisk App 官方 30.6 配对 + additional setup 转正）。部署法已回填 AVD 手册第三节。
- 真安装器：Magisk App 同源 `module_installer.sh`（assets 内，调 `install_module`）刷入 build 59 zip → banner 正确、bin/webroot/post-fs-data 解包齐全、跨槽 symlink 建立（NotoColorEmojiFlags/Legacy → NotoColorEmoji.ttf）。
- 开机：modules_update 激活、post-fs-data 回写 `✅ Twemoji active (2/2)`（Legacy 槽 post-fs-data 阶段尚不存在被正确排除，Magic Mount 阶段经 symlink 生效）；挂载表呈自挂载 rw + Magic Mount ro 共存；toybox 下 `emoji-slots.sh list/check` 三槽全 OK。
- 稳定：3 轮 `adb reboot` 各 ~35s，crash buffer 零命中，每轮描述活回写。
- 视觉：Magisk 管理器模块页显示 `Twemoji Resurrection v17.0.3 (59)` + ✅ 描述 + **Update 灰（无更新可提，R5 死循环终结的设备端实证）**；WebUI 画廊（Chrome 无 bridge 降级文案正确）全程 Twemoji 美术，红鸟标记实锤。

## 系统架构

Android systemless Twemoji 字体替换模块。槽位发现单一事实源 = `module/bin/emoji-slots.sh`（`fonts.xml` + `font_fallback.xml` + `/product/etc/fonts_customization.xml` 三源并集、全路径输出，`list`/`check` 两模式）：install.sh 消费 `list` 建逐槽 symlink（供 Magic Mount）；post-fs-data.sh 消费 `list` 自挂载并回写三态描述；WebUI 经管理器 root bridge 消费 `check`（execOut 适配原生 String / 包装器对象双返回形态）。Magisk 时序口径已修正：post-fs-data 先于 Magic Mount，自挂载先行、Magic Mount 随后叠同内容。

## 已实现功能

- Twemoji CBDT/CBLC 字体分发与三源槽位发现；XML 边界仍有 C1/C2，product 原生 overlay 映射仍有 C3。
- 自挂载 + cmp 守卫（幂等，二次运行为 no-op，集成测试验证）；历史 A16 回归记录了与 Magic Mount 共存。
- 开机三态状态，分母只计已发现且实际存在的槽；清单误选/漏选会影响状态可信度，待 C1/C2 修复。
- WebUI 画廊（Intl.Segmenter 守卫 + 正则降级；画廊故障不阻断自检）、实时检查（单命令）、降级读取与版本显示；错误返回处理待 C4。
- 更新通道与包内许可（NOTICE 含 Tyler O'Neill 补署）；发布一致性门禁 `tests/build_package.py`（版本六处一致 + zipUrl 资产名 + zip=git 跟踪清单；build 58 versionCode 57/58 错位事故的防再发）。
- 2026-10-15 字体来源核验记录：jdecked/twemoji v17.0.2 构建，上游 v17.0.2↔v17.0.3 零 emoji 资产差异（见 changelog build 59）；2026-10-19 只复核本地字体结构与哈希一致，未重验上游资产。

## TODO

1. **C1 / P1**：排除 XML 注释中的 family/font。已用原始启动脚本隔离复现：普通 Body.ttf 被替换，自检仍显示 active (2/2)。
2. **C2 / P2**：补齐合法 XML 的 TAB、单引号、属性等号空白与嵌套 axis；这些样本当前漏槽且返回成功。
3. **C3 / P2**：安装器把 /product 槽映射到 module/system/product，避免在 module/product 建实体目录，补真实 product 设备的原生挂载验证。
4. **C4 / P2**：WebUI 校验包装器 errno，并识别不完整检查结果；errno=1 且 stdout 含 OK 行当前仍呈现全部生效。
5. **C5 / P3**：打包门禁保护完整更新 URL/tag 契约；错误 tag、相同附件 basename 的突变当前仍 PASS。
6. **C6 / P3**：README 双语兼容表已于 2026-10-21 同步（见文末审计整改记录）；剩余：补充真实 product schema 夹具，去除原测试中的自行物理删除步骤。
7. SukiSU 真机（需用户协调朋友设备）：WebUI bridge 首次实测；可选同批 Magisk+WebUIX。待功能修复后再做完整安装与冷启动回归。
8. 可选：A15 及以下兼容加验；上游出新版本时随更，遵守既有版本和资产 URL 契约。
9. 已知边界（README 已披露）：/data/fonts 可更新字体机制；App 内置 emoji。

2026-10-19 复审验证：原 shell 13 项 + WebUI 7 项 PASS；新增 XML 独立语义对照、启动脚本误挂载、安装 product 路径、bridge 错误返回与 URL 突变实验。仅使用隔离文件和模拟 mount，未连接设备、未修生产代码。通过复现实验不表示缺陷已修复。

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
| tests/REVIEW-2026-10-19.md | build 59 复审意见、剩余问题与修复效果 |
| tests/review_followup.py | 无删除的复审入口；原回归及独立 XML/安装/bridge/门禁探针 |

历史记录（2026-10-15）：主力 agent 报告 Magisk 链路设备回归及 build 59 发布核验完成。本轮本地重跑 20 项断言通过，但独立探针发现上述剩余缺陷；设备与远端状态尚未重验。

## 2026-10-21 审计整改记录（GitHub 维护审计轮）

- TWEMOJI-RESURRECTION-02（= TODO C6 的 README 部分）：README.md / README_EN.md 兼容表"已验证"行与本文 2026-10-15 Magisk 验收记录同步（新增 Magisk 30.6 rooted API 36 模拟器条目；SukiSU 真机 WebUI bridge 标待首验）。仅同步既有记录，本轮未重跑设备。
- TWEMOJI-RESURRECTION-04：module/changelog.md 重构为单一一级标题 + 逐 build 日期 + 分类结构；条目事实不变，日期取自 git 提交历史（53-57=2026-09-12、58=2026-09-24、59=2026-10-15）。
- 10-19 会话遗留的归档备注（未提交）已代为提交保全。
- 未关闭（待执行）：①TWEMOJI-RESURRECTION-01（P1）· **迁移已批准（2026-10-21 用户拍板）**：build≥60 起启用不可变发布身份——tag `twemoji-17.0.3-build.N`、附件名 `Twemoji-Resurrection-17.0.3-build.N-ksu.zip`、update.json 指向本 build 专属 tag URL；**门禁地基已落地**（tests/build_package.py：build≥60 的资产名/URL 断言 + changelog 新结构锚点修复；build<60 保持旧契约不破坏存量更新）；旧 v17.0.3 tag/zipUrl/模块 id 全部不动。实际发版随下一次构建执行（建议在 C1-C6 功能修复后）。②Release 正文历史哈希清理随新构建一并处理（旧哈希已标注为不可下载的历史记录）。
- 全轮工作记录：`C:\Users\deser\Projects\github-audit-2026-10-21\remediation-worklog-2026-10-21.md`。
