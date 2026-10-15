# USB 认不到设备

> 对应偏离状态：**S10 — USB 认不到设备**
> 对应 playbook 步骤：**16+（安装 KOReader 及之后的所有拷贝步骤）**
> 触发探测：KOReader 运行时插上 USB 线，Windows 侧**不出现** Kindle 盘符。

## 现象

KOReader 起来后，插上 USB 线到电脑：

- Windows 资源管理器里**没有** Kindle 盘符出现（比如 F:）。
- Windows 声音**没响**（没识别到 U 盘）。
- 有些电脑会在事件查看器里报 USB 设备枚举错误。

这不是 USB 线坏了，不是电脑坏了。是 KOReader 的"无框架"启动模式主动关掉了 USB 存储服务。

## 原因

KOReader 在 Kindle 上默认以 **frameworkless**（无框架）模式启动——为省内存，把 Kindle 原生 UI 和**原生 USB 存储服务（USBMS）**一起杀掉了。

结果：KOReader 运行期间，Kindle 的 USB 存储挂载点**根本不响应**，所以电脑认不到。

官方 FAQ 原话：

> **"KOReader currently does not support USBMS mode"**
>
> —— <https://kindlemodding.org/jailbreak-faq.html>

## 解法：退出 KOReader 再插 USB

要拷文件，必须**回到 Kindle 原生主界面**。步骤：

1. KOReader 顶部菜单 → 右上角 **≡**（三横线） → 拉到底 → **退出（Exit）**。
2. KOReader 退出后回到**原生主界面**（Kindle 原生桌面）。
3. 现在插 USB，Windows 就能识别盘符了。

拔线 → 拷文件 → 插线，全部在这个原生状态下进行。

## 备选方案：KOReader 的"启动 USB 存储"

不想退出 KOReader 的话，KOReader **工具菜单**里有一个**"启动 USB 存储"**（Enable USB Storage）选项：

- 位置：KOReader 主菜单 → 工具 → **启动 USB 存储**。
- 作用：临时把 Kindle 挂成 U 盘。
- 限制：Kindle 会短暂回到原生状态，且这个功能在部分固件上不稳定，实测**不如退出 KOReader 可靠**。

默认推荐**退出 KOReader**这条路径。

## 常见误判

- **以为 USB 线坏了**：换根线也一样。
- **以为 Kindle 变砖了**：拔下 USB、重启一下、还是能进 KOReader，说明设备没问题。
- **以为 Windows 磁盘管理器有问题**：不是。Windows 侧根本没收到 U 盘枚举信号。

## 出处

- KOReader USBMS 不支持：<https://kindlemodding.org/jailbreak-faq.html>
- KOReader 官方 wiki：<https://koreader.org/>

## 参见

- [../docs/01-越狱全流程.md](../docs/01-越狱全流程.md#阶段-3--装-koreader--微信读书) — 步骤 16、17 原文
- [../data/playbook.yaml](../data/playbook.yaml) — 状态 S10 定义