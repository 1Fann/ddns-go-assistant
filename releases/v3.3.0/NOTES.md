## 中文

- 首页新增“立即更新解析”，立即执行一次官方引擎的地址检查与 DNS 比较；地址未变时无需修改记录。
- 首页新增“检查间隔”，可设置 1–1440 分钟，默认 5 分钟，重启后保留。
- 已由 App 部署的后台自动升级适配脚本，保留现有引擎、域名、凭据、暂停及唤醒锁设置。

下载下方 **ddns-go-assistant.apk**。此 APK 使用稳定正式签名，可覆盖升级此前本项目的本地正式版；Actions 中随机测试签名的 APK 不能保证直接覆盖。

需要 Root、ARM64、受支持的 BakaSU / KernelSU 环境。首次安装后通过 App 下载引擎，在手机本地填写 DNS 配置。立即更新和修改间隔会重启后台，管理页面可能需要重新登录。息屏后能否准时检查仍受系统调度与网络状态影响。

## English

- Added **Update DNS now** to immediately run the upstream address check and provider comparison. Unchanged records are retained.
- Added **Check interval**, configurable from 1–1440 minutes (default: 5), persistent across reboot.
- App-managed deployments automatically update bundled helpers while preserving the engine, domains, credentials, paused state and wake-lock preference.

Download **ddns-go-assistant.apk** below. It uses the stable release signing key and can upgrade earlier local release builds from this project. Actions artifacts use test keys and may not be directly upgrade-compatible.

Requires root, ARM64 and a supported BakaSU / KernelSU environment. Download the engine in the app, then configure DNS credentials locally. Manual updates and interval changes restart the backend, so management may require signing in again. Scheduling and network conditions can still delay checks.
