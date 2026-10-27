# ddns-go Android Root

**中文** | [English](README.en.md)

**[下载正式 APK](https://github.com/1Fann/ddns-go-android-root/releases/latest)** · [更新记录](CHANGELOG.md)

为已 Root 的安卓手机提供轻量的 **ddns-go 助手**：查看服务状态、控制开机自启与 CPU 唤醒锁，并在 App 内打开官方管理页面。

**实验项目 · 非官方 · 需要 Root。** 从 v3.2.0 起，安装 APK 后可在 App 内一键下载、校验并部署官方引擎，无需电脑。仍需授予 Root 并在本机填写 DDNS 凭据。本项目不隶属于 jeessy2/ddns-go 或 OpenListApp。

## 能做什么

- App 内一键部署，默认推荐 v6.17.7，也可读取官方 GitHub 最新稳定版；当前安装器仅支持 ARM64。
- SHA-256 校验、受限归档提取、安装进度通知、配置保留和启动失败回退。没有可信校验值时拒绝安装。
- 后台独立于 App 运行，关闭页面后继续工作。
- 从 `wlan0` 选择 `2000::/3` 范围内的非临时 IPv6，排除 `temporary`、`secondary`、`deprecated`、`tentative`、`dadfailed` 和首选生命周期为零的地址。
- 优先保留上次选择的地址，只要它仍符合条件，避免多个地址之间来回切换。
- 首页可立即更新解析，或设置 1–1440 分钟的检查间隔（默认 5 分钟，重启后保留）。地址未变时保留记录。
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

1. 安装 APK，打开“安装 / 更新后台”，授予 Root 和安装进度通知权限。
2. 默认选择推荐版本，或选择“GitHub 最新稳定版”，点击“授权 Root 并安装 / 更新”。首次安装完成后后台自动启动，息屏唤醒锁默认关闭。
3. 进入“打开管理页面”，在手机本地设置管理账号。已安装的后台会保留原来的运行偏好。
4. 选择 Cloudflare 等 DNS 提供商，输入自己的凭据和域名。IPv6 来源选择“通过命令获取”，命令填 `/data/adb/ddns-go/ipv6.sh`。
5. 如需息屏持续检查，开启“息屏持续运行”，并观察实际日志。

首页“立即更新解析”会重启当前单实例后台，触发官方引擎立即检查；管理页面可能需要重新登录。“检查间隔”保存后立即应用，已暂停的后台继续暂停。新版首次打开会自动更新已由 App 管理的后台脚本，复用现有引擎并保留 DNS 配置。接口、网卡和命令取址均由管理页配置；若要求排除临时 IPv6，请使用上述筛选命令。

不要将 API Token 放进命令行、Issue、截图或仓库。本仓库不包含可用凭据或预配置域名。仅需要 IPv6 时，应在官方页面关闭 IPv4 更新。

手机需要能通过 HTTPS 访问 GitHub API、发行页和发行文件下载域名。最新版通过官方 API 的 SHA-256 digest 或同一发行版的 checksums.txt 校验，不代表它经过本项目兼容测试。旧手动部署不会被静默覆盖；处理方法见安装指南。

## 结构

```text
app/                  原生 Java App、中文/英文资源、Windows 构建脚本
runtime/              启动、监督、取址、唤醒锁、安装与卸载脚本
tests/                IPv6 地址过滤样例
docs/                 中英安装说明、验证范围与安全说明
prepare-runtime.ps1   下载并校验固定版本的官方引擎
```

推荐引擎为官方 **v6.17.7 Android ARM64**，可另选最新稳定版。从上游下载的引擎未经修改，二进制不提交到源码仓库。管理网页也由该引擎提供。构建脚本及发行来源见 [上游说明](docs/UPSTREAM.md)。

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
