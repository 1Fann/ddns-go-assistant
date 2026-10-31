# ddns-go Assistant 3.3.4

独立 watchdog 与后台监督进程互相恢复；进程存活约每秒检查，HTTP、心跳和唤醒锁续期仍约每 30 秒执行。首次引擎异常退出快速重建，连续失败保留 2/4/8/16/30 秒退避。

保留手动暂停、域名与账号配置、更新间隔及原唤醒锁选择。改进进程身份校验、锁释放和系统查询超时，升级只更新已管理的后台组件。

Watchdog and daemon peers recover exited supervision. Lightweight process checks run about once per second; HTTP probes, heartbeats and wake-lock renewal retain their roughly thirty-second cadence. First engine exits recover promptly, with 2/4/8/16/30-second backoff for repeated failures.

Existing pause state, DNS configuration, update interval and wake-lock preferences are preserved. Process identity checks, lock release and bounded operations improve recovery during upgrades and unexpected exits.

本包使用原发布签名。离线调度、IPv6、间隔、脚本语法与归档校验通过；具体实机验证及限制见 `docs/TESTING.md`。普通轮询在 CPU 深度休眠时可能推迟，本机 HTTP 就绪不等于 DNS 服务商更新成功，不保证所有故障都在固定秒数内恢复。

This package retains the original release signing identity. Offline scheduler, IPv6, interval, shell syntax and archive checks passed; see `docs/TESTING.md` for device evidence and limits. CPU suspension can postpone polling, and local HTTP readiness does not establish DNS-provider delivery or a fixed recovery deadline. No private configuration or signing key is included.
