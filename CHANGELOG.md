# Changelog / 更新记录

## 3.3.0

### 中文

- 首页新增“立即更新解析”，通过重启现有单实例后台，立即执行官方引擎的地址检查和 DNS 比较；地址未变时保留记录。
- 首页新增 1–1440 分钟的检查间隔设置，默认 5 分钟，保存后立即应用并持久化；暂停状态保持不变。
- 状态显示实际配置的间隔，安装升级保留间隔设置。
- 已受本 App 管理的后台在首次打开新版时自动升级适配脚本，复用现有引擎并保留配置，无需再次下载。

### English

- Added Update DNS now: restarts the existing single backend to immediately run the upstream address check and provider comparison; unchanged records are retained.
- Added a persistent 1–1440 minute check interval, defaulting to 5 minutes. Changes apply immediately and keep paused backends paused.
- Status displays the configured interval; installation upgrades preserve it.
- Existing app-managed deployments update bundled helpers on first launch, reusing the local engine and preserving configuration without another download.

## 3.2.0

### 中文

- 新增 App 内一键下载、校验和部署；默认推荐版本，可选官方 GitHub 最新稳定版。
- 新增安装进度通知，页面关闭后任务继续运行；Root 仍为必需。
- 新安装自动启动后台；更新保留配置、暂停状态和唤醒锁偏好。
- 增加启动失败恢复、中断事务保护、受限 tar 提取和归档测试。
- 已有未标记的手动部署保持原样，避免覆盖其他程序或丢失配置。

### English

- Added in-app download, verification and deployment, with a recommended default and an optional latest stable official GitHub release.
- Added foreground progress notifications; work survives Activity changes. Root remains required.
- Fresh installs start automatically; updates preserve configuration, paused state and wake-lock preference.
- Added failed-start rollback, interrupted-transaction protection, restricted tar extraction and archive tests.
- Existing unmarked manual installations are left untouched to avoid overwriting unrelated software or configuration.
