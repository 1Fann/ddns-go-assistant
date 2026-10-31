# Changelog / 更新记录

## 3.3.4

- Reduced daemon/watchdog liveness polling to one second while keeping HTTP, heartbeat and wake work at thirty ticks (about thirty seconds).
- Kept first-exit recovery immediate and repeated-failure delays at 2, 4, 8, 16 and 30 seconds. Accelerated test fixtures now identify fast polling explicitly without rewriting stop-wait timing accidentally.
- 守护双方约每秒检查进程，慢检查仍约30秒；连续失败仍按2/4/8/16/30秒退避。保留暂停、配置、引擎接管和原唤醒设置。

## 3.3.3

- Split two-second process-liveness checks from thirty-second HTTP probes, heartbeat writes, wake-lock renewal and log housekeeping. A missing guardian can be restored without restarting its healthy engine.
- Retained four slow heartbeat failures before replacing stalled supervision. First engine exits recover promptly; repeated crashes use bounded 2–30 second backoff.
- Preserved deliberate pause, configuration and wake-lock settings. Faster polling does not acquire new wake locks or perform per-second HTTP/log writes.
- 进程存活改为约 2 秒检查；HTTP、心跳写入、唤醒锁续期和日志整理仍为约 30 秒。守护恢复不会重启仍健康的引擎。
- 保持四个慢周期心跳失败门槛；首次引擎退出快速恢复，连续崩溃退避，保留暂停和原设置。

## 3.3.2

- Added independent watchdog/daemon peer recovery, bounded heartbeat-stall detection, orphan-engine adoption and local HTTP health checks with consecutive-failure tolerance.
- Bounded stop, HTTP and wake-lock waits; exact component checks prevent stale PID files from signaling unrelated processes. Installation/removal now verify both supervisor locks are released.
- Preserved configuration, check intervals, deliberate pause and wake-lock preferences. No global power-policy, lock-screen or credential-storage changes.
- Added isolated Android BusyBox fault-injection tests for killed/stalled peers, unhealthy engines, stale identifiers, pause persistence and timeout recovery. Deep-sleep scheduling and DNS-provider success still require device/network validation.

- 新增独立看护与监督进程互相恢复、心跳卡死检测、孤儿引擎接管、本地 HTTP 连续失败恢复。
- 为停止、健康检查和唤醒锁等待设置上限；使用精确组件校验，防止过期 PID 误杀其他进程；安装和卸载检查两个守护锁。
- 保留原配置、检查间隔、手动暂停和唤醒锁偏好，不修改全局省电、锁屏或凭据存储。

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
