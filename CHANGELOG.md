# Changelog / 更新记录

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
