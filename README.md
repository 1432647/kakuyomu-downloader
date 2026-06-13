# kakuyomudl

Kakuyomu (カクヨム) 小说下载器 — 将公开小说保存为 EPUB 或青空文库格式 TXT。

[![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey)](LICENSE)

## 功能

- **交互式 CLI** — 直接运行，按提示输入，无需记忆命令行参数
- **章节选择** — 扫描小说结构后展示卷列表，可选择下载特定卷
- **EPUB 输出** — 合并为单本或按卷拆分，支持层级目录导航
- **青空文库 TXT** — 保留原版格式输出
- **中文界面** — 全中文化提示与错误信息

## 下载

在 [Releases](https://github.com/1432647/kakuyomu-downloader/releases) 或 [Actions → Artifacts](https://github.com/1432647/kakuyomu-downloader/actions) 中下载 `kakuyomudl`。

## 使用方法

双击运行 `kakuyomudl.exe`，按提示操作：

```
请输入小说作品URL: https://kakuyomu.jp/works/...

书名: ○○○
作者: ○○○
共 XX 话

卷列表:
[1] 第一章 (12话)
[2] 第二章 (15话)
[0] 全部选择
请选择要下载的卷:

选择输出格式:
[1] EPUB (推荐)
[2] TXT (青空文库)
```

输出文件保存在 `kakuyomudl.exe` 同目录下的 `{小说名}/` 文件夹中。

## 构建

使用 Lazarus (Free Pascal) 编译：

```bash
lazbuild --build-mode=Release kakuyomudl.lpi
```

或通过 GitHub Actions 自动构建（提交代码即触发）。

依赖 [TRegExpr](https://github.com/andgineer/TRegExpr)（`regexpr.pas` / `regexpr_compilers.inc` / `regexpr_unicodedata.pas`）已包含在仓库中。

## 注意事项

- 仅支持 Kakuyomu **公开免费**作品，付费作品无法下载
- 下载内容请勿用于商业用途或未经授权的再分发
- 下载的文本著作权归原作者所有

## 许可

- 原始代码 © 2021-2026 INOUE, masahiro (MIT License)
- 修改部分 © 2026 1432647 (CC BY-NC 4.0)

---
