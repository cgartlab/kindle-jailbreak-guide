# 书库没有 KUAL

> 对应偏离状态：**S09 — 书库无 KUAL 项目**
> 对应 playbook 步骤：**15（安装 MRPI + KUAL）**
> 触发探测：MRPI 安装完、重启后，KUAL 主菜单里**没有** KUAL 项目，或 `documents\KUAL.kual` 不存在。

## 先分清：走的是哪条路

安装 KUAL 在 PW3/5.16.2.1.1 上有两条路：

| 路线 | 原理 | 在 PW3/5.16.2.1.1 上 |
|---|---|---|
| **PEKI**（`KUAL.jar` + `KUAL.sh` → `documents\`） | 靠 Kindle 客户端 jar 启动 KUAL UI | ❌ **静默失败** |
| **MRPI + KUAL Booklet coplate**（本目录主推） | 靠越狱桥接 `;log mrpi` 直接调 MR Installer，再拷 coplate `.bin` | ✅ 已实测成功 |

kindlemodding 官方 wiki 在 K5+ 上推荐 PEKI，但 **在 PW3 / 5.16.2.1.1 上 PEKI 静默失败**——拷入 `KUAL.jar` + `KUAL.sh` 到 `documents\` 后重启，书库里**没有** KUAL 项目，**也不报错**。

如果你的走的是 PEKI，直接换到 MRPI 路线。

## PEKI 静默失败的另一种可能：Windows 文件锁

即使是 MRPI 路线，也可能"拷入成功、重启无变化"。最常见的非预期原因是 **Windows 文件锁静默写失败**：

- `Copy-Item` / `cp` 返回成功（exit code 0），但目标设备上的文件**内容没变**。
- 触发场景：Kindle 没退出 KOReader 就拷贝（`documents\`、`extensions\` 被 KOReader 持有句柄）、Windows 资源管理器正在预览该文件、Defender 实时扫描锁定、上一次拷贝中断留下半文件。
- 官方文档（`qianjindelvdai/kindle-revive`）里明确提示：「**Windows 文件锁静默写失败——cp/Copy-Item 返回成功但内容没变；删了再拷 + sha256 复核**」。

### 诊断法：sha256 比对

对源文件与设备上的文件分别算 SHA256，比对是否一致：

```powershell
# 源文件
Get-FileHash .\KUAL-coplate\Update_KUALBooklet_c6ac782_install.bin -Algorithm SHA256 | Select-Object -ExpandProperty Hash
# 设备上的同一文件（例如 F 盘）
Get-FileHash F:\mrpackages\Update_KUALBooklet_c6ac782_install.bin -Algorithm SHA256 | Select-Object -ExpandProperty Hash
```

哈希**不一致** = 拷贝没到位，重拷一次；哈希**一致**但仍不生效，才是真的走错路线或设备侧问题。

## 正确路线：MRPI + KUAL Booklet coplate

### 前置

- 越狱已完成，`;log` 有输出（桥接活跃）。如 `;log` 无输出，先读 [越狱桥接挂了.md](./越狱桥接挂了.md)。
- 已解压两个包：
  - `kual-mrinstaller.tar.xz` → 里面有 `extensions\`、`mrpackages\`
  - `KUAL-coplate.tar.xz` → 里面有 `Update_KUALBooklet_c6ac782_install.bin`

**关键：MRPI 走越狱桥接，不需要 `developer.keystore`。**`3-安装包\` 里那份 keystore 是给 PEKI 或自签名 jar 路线用的，本路线用不到。

### 步骤

1. 解压 `kual-mrinstaller.tar.xz`。
2. 把解压出的 `extensions\` 和 `mrpackages\` **两个目录**整体拷到 Kindle 根目录（F:），存在同名就覆盖：
   ```powershell
   robocopy .\kual-mrinstaller-1.7.N-r19303\extensions F:\extensions\ /E /IS /IT /R:1 /W:1
   robocopy .\kual-mrinstaller-1.7.N-r19303\mrpackages  F:\mrpackages\  /E /IS /IT /R:1 /W:1
   ```
3. 解压 `KUAL-coplate.tar.xz`，把 `Update_KUALBooklet_c6ac782_install.bin` **拷到 Kindle 的 `mrpackages\` 目录**：
   ```powershell
   Copy-Item .\KUAL-coplate\Update_KUALBooklet_c6ac782_install.bin F:\mrpackages\
   ```
4. 安全退出（不要拔 USB 前未退出 Windows 侧的资源管理器锁定）。
5. Kindle 锁屏 → 顶部输入 `;log mrpi` → 回车。
   - **注意：是 `m-r-p-i` 四个字母，别打成 `mrpi` 少个 log，也别打成 `m-r-p-p-i`。**
6. 屏幕**底部**出现 **"Hush, little baby..."** —— 这是 MR Installer 在跑。
7. MR Installer 自动装完后，设备会**自动重启**并弹出 UI。
8. 进 KUAL 主菜单看到 **KUAL** 项目 = 成功。

## 排查清单

按顺序过：

- [ ] `;log` 有输出吗？没有 → 桥接挂了，读 [越狱桥接挂了.md](./越狱桥接挂了.md)
- [ ] 命令是 `;log mrpi` 吗？打错字母不会报错，只是没反应
- [ ] `extensions\` 和 `mrpackages\` 都拷进 F: 根了吗？只拷一边不行
- [ ] `.bin` 文件拷到 `F:\mrpackages\` 了吗？拷到根目录不行
- [ ] 拷完后 sha256 比对了吗？源与目标一致才继续
- [ ] 屏幕底部出现 "Hush, little baby..." 了吗？没出现 = MR Installer 没被触发

## 出处

- 官方 MRPI 路线：<https://kindlemodding.org/kuala/>
- Windows 文件锁静默写失败、补丁后门还原：<https://github.com/qianjindelvdai/kindle-revive>（README 中的经验提示）

## 参见

- [../docs/01-越狱全流程.md](../docs/01-越狱全流程.md#阶段-2--装工具mrpi--kual) — 步骤 15 原文
- [../data/playbook.yaml](../data/playbook.yaml) — 状态 S09 定义