# kindle-jailbreak-guide

> 给 AI Agent 的 Kindle 越狱导航层 + 状态机。

## 这是什么

一份让任何 AI Agent（Claude、ChatGPT、Codex、Gemini CLI……）能**正确引导**用户在老 Kindle 上完成越狱 + 安装 KOReader + 接入微信读书的结构化知识库。

**不是最全的越狱教程**——是唯一把决策数据 / 偏离状态 / 执行者分工结构化的仓库。别人独有的深度知识（串口救砖、服务精简、WinterBreak 国内离线化）以链接 + 归属方式指过去。

## 已验证范围

仅 **1 台 Kindle Paperwhite 3（4GB，固件 5.16.2.1.1）**。其他机型核心逻辑可参考，文件版本需自行核对。

## 快速开始

**如果你是 AI Agent**：读 `AGENTS.md`，它有铁律、主循环、文件导航。然后从 `data/playbook.yaml` 的步骤 01 开始。

**如果你是人**：从 `docs/01-越狱全流程.md` 读起。卡住了看 `recovery/` 目录。

## 目录

```
AGENTS.md              ★ Agent 入口：铁律 + 主循环 + 人机分工
data/
  jailbreaks.yaml      方案决策数据（每条带出处 + 核查日期）
  playbook.yaml        19 步流程 + 11 个偏离状态的状态机
docs/
  00-已验证配置.md
  01-越狱全流程.md
  02-日常使用与维护.md
  03-更新与重装.md
  04-设备文件结构.md
  06-竞品与互补项目.md
  99-事实核查.md
recovery/              偏离状态补救手册
scripts/               Windows PowerShell（探测 / 校验 / 抢时间拷贝 / 备份 / 脱敏扫描）
THIRD-PARTY.md         第三方归属 + 许可证
LICENSE                 MIT
```

## 免责声明

- 操作针对你自己的设备，风险自负。
- 本仓库**不涉及 DRM 破解**。KOReader 不支持 AZW3/KFX，只读 EPUB/PDF 等开放格式。
- 本仓库**不分发任何第三方二进制**。所有安装包从上游获取，附 SHA256 供校验。
- 越狱工具版权归各自作者，遵循其原始许可。

## 为什么是 LanguageBreak

kindlemodding 官方现在主推 WinterBreak，把 LanguageBreak 标成 legacy。但 WinterBreak 的前置条件包括"已注册机型"——对国行设备（中国区电子书店 2023-06-30 停运），注册这条路走不通。LanguageBreak **不需要注册、不需要联网**，是国行 5.16.2.1.1 设备的可行解。

> 注意：这个判断基于实践经验和社区观察，不是官方结论。真实瓶颈可能是网络可达性 + 商店行为，不一定是注册状态本身。详见 `docs/99-事实核查.md`。
