# 项目状态

更新：2026-10-15。生产基线 `97e3ada`，当前显示版本 v17.0.3 (58)，实际 module.prop versionCode 为 57，待修正。本轮只完成审查与测试记录，未修改生产模块或发布资产。

## 系统架构

Android systemless Twemoji 字体替换模块。legacy install.sh 回调负责解包及逐槽 symlink；post-fs-data.sh 解析 emoji 字体槽、按需 bind-mount 并写回描述；WebUI 用系统字体展示分类选集，通过管理器桥接请求诊断；module.prop/update.json 提供更新通道。模块 id 为 Twemoji-systemless。

## 已实现功能

- Twemoji CBDT/CBLC 字体分发与系统槽位替换。
- 无挂载 metamodule 时的自挂载路径，以及 cmp 重复挂载守卫。
- 开机三态状态，排除物理不存在的槽位。
- WebUI 画廊、实时检查和降级读取的代码路径；本轮确认实时检查存在阻断缺陷，不能标作完整可用。
- 管理器更新清单及包内许可文件。
- 审查脚本：19 项隔离行为断言；本地 ZIP、字体结构及完整校验和检查。

## TODO

1. P1：修复按行 sed 范围越界选择普通字体及跨行/同一行多字体遗漏。
2. P2：让配置发现对齐系统实际使用的字体配置，避免只覆盖旧配置却误报全成功。
3. P2：修复 WebUI CHECK_CMD 的 shell 语法。
4. P2：正确适配原生 KernelSU exec 的字符串返回值与包装器接口。
5. P2：同步 module.prop/update.json 的 versionCode，并建立发布一致性门禁。
6. P2：Intl.Segmenter 能力检测与降级；P3：实时检查成功分支补版本显示。
7. 核验 OEM product 字体、系统可更新字体、Magisk 挂载前后时序与最终诊断可见性。
8. 实际管理器完整安装入口、冷启动、SELinux 与更新流程回归。
9. 核对字体 17.0.2 内嵌版本与 17.0.3 发布声明的来源差异；元数据差异尚不能证明字形内容错误。

完整证据、触发条件、官方来源和限制见 [审查报告](tests/REVIEW-2026-10-15.md)。

## 核心文件拓扑

| 路径 | 职责 |
|---|---|
| module/install.sh | 安装回调、解包、槽位链接与权限 |
| module/post-fs-data.sh | 启动自挂载与模块描述检查 |
| module/webroot/index.html | 表情分类画廊和状态展示 |
| module/system/fonts/NotoColorEmoji.ttf | 字体数据 |
| module/META-INF/com/google/android/ | legacy 安装器入口和 MAGISK 标记 |
| module/module.prop、update.json、changelog.md | 版本与更新元数据 |
| module/LICENSE、NOTICE | 分发许可和署名 |
| README.md、README_EN.md | 双语使用与架构说明 |
| tests/audit_functional.cjs | 以 Node 标准库和 Git Bash 复现功能行为 |
| tests/audit_package.py | 以 Python 标准库读取包清单、字体结构与校验和 |
| tests/.audit-work/、tests/.venv/ | 被忽略的隔离样本与 Python 环境 |

本次未连接 Android 设备。隔离脚本的断言通过包含“成功复现缺陷”，不代表模块已通过发布验收。
