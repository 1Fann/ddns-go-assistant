# ddns-go Android Root

**中文** | [English](README.en.md)

为已 Root 的安卓手机提供轻量的 **ddns-go 助手**：查看服务状态、控制开机自启与 CPU 唤醒锁，并在 App 内打开官方管理页面。

**实验项目 · 非官方 · 需要 Root。** APK 是控制面板，必须配合本仓库的后台脚本与官方 ddns-go 引擎安装。仅安装 APK 不会启动 DDNS。本项目不隶属于 jeessy2/ddns-go 或 OpenListApp。

## 能做什么

- 后台独立于 App 运行，关闭页面后继续工作。
- 从 `wlan0` 选择 `2000::/3` 范围内的非临时 IPv6，排除 `temporary`、`secondary`、`deprecated`、`tentative`、`dadfailed` 和首选生命周期为零的地址。
- 优先保留上次选择的地址，只要它仍符合条件，避免多个地址之间来回切换。
- 每 300 秒检查地址；地址未变时，是否查询 DNS 提供商由 ddns-go 的缓存机制决定。
- 使用 BakaSU/KernelSU 的 `service.d` 开机入口，提供独立的息屏保活开关。
- 管理页面只监听 `127.0.0.1:9876`；App 不直接调用 Cloudflare API。
- App 原生界面支持中文和英文，跟随系统语言；网页和引擎日志由上游提供。
- 不依赖 Termux，不修改路由器。

## 适用范围

原始部署在 **Redmi Note 10 Pro、移植版澎湃 OS 4、BakaSU、ARM64** 上验证了取址、DNS 更新和重启自启。公开版本新增的安装/卸载流程尚未在多种手机上验证。请先阅读 [验证范围](docs/TESTING.md)。

依赖 `/data/adb/ksu/bin/busybox`、支持 `su -M` 的 Root 管理器，以及可执行的 `service.d`。CPU 保活还要求内核提供 `/sys/power/wake_lock` 与 `wake_unlock`。**不宣称兼容所有 KernelSU、Magisk 或第三方 ROM。**

唤醒锁会增加耗电，新安装默认关闭。它用于减少深度休眠带来的延迟，不是实时调度保证；断网、内核限制和服务异常仍会影响检查。

## 安装与使用

完整步骤见 **[中文安装指南](docs/INSTALL.zh-CN.md)** / [English installation guide](docs/INSTALL.en.md)。

1. 构建 App 和经过校验的 ARM64 后台包。
2. 通过 ADB 安装后台，再安装 APK、授予 Root。
3. 打开“后台运行”，进入“打开管理页面”，在手机本地设置管理账号。
4. 选择 Cloudflare 等 DNS 提供商，输入自己的凭据和域名。IPv6 来源选择“通过命令获取”，命令填 `/data/adb/ddns-go/ipv6.sh`。
5. 如需息屏持续检查，开启“息屏持续运行”，并观察实际日志。

不要将 API Token 放进命令行、Issue、截图或仓库。本仓库不包含可用凭据或预配置域名。仅需要 IPv6 时，应在官方页面关闭 IPv4 更新。

## 结构

```text
app/                  原生 Java App、中文/英文资源、Windows 构建脚本
runtime/              启动、监督、取址、唤醒锁、安装与卸载脚本
tests/                IPv6 地址过滤样例
docs/                 中英安装说明、验证范围与安全说明
prepare-runtime.ps1   下载并校验固定版本的官方引擎
```

引擎固定为官方 **v6.17.7 Android ARM64**，从上游下载，未修改；二进制不提交到源码仓库。管理网页也由该引擎提供。构建脚本及发行来源见 [上游说明](docs/UPSTREAM.md)。

## 构建

需要 Windows、PowerShell、JDK 21、Android SDK Platform 35 和 Build Tools 35.0.0：

```powershell
$env:ANDROID_SDK_ROOT = 'C:\Android\Sdk'
$env:JAVA_HOME = 'C:\Java\jdk-21'
./app/build.ps1
./prepare-runtime.ps1
```

默认 APK 为使用本地测试签名的 `app/out/ddns-go-assistant-debug.apk`。正式签名使用仓库外的密钥，方法见安装指南。GitHub Actions 会编译测试 APK 并运行脚本检查；CI 测试签名每次可能不同，不能当作稳定升级签名。

## 与其他方案的区别

[OpenListApp/ddnsgo-android](https://github.com/OpenListApp/ddnsgo-android) 是免 Root 的安卓整合项目。本项目面向已经 Root、希望使用独立后台和特定 Wi-Fi IPv6 筛选规则的设备。它们是不同部署方式，本项目不声称更稳定或更省电。

## 反馈与许可

欢迎提交兼容性反馈：请提供手机型号、Android/ROM、Root 管理器版本和已脱敏的错误描述。**不要上传 `config.yaml`、Token、密码或未经检查的完整日志。**

本项目代码使用 [MIT License](LICENSE)。ddns-go 使用其自己的 [MIT License](runtime/LICENSE.ddns-go)。原包名 `com.mcyao.ddnspanel` 保留以支持已有用户覆盖升级，不代表绑定域名或账户。
