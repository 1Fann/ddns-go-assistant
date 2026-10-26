# 安全与隐私 / Security and privacy

## 中文

- 这是可执行 Root 操作的工具，只在自己信任的设备上安装。
- Root 命令限定为状态、启动、停止、唤醒锁开关；网页没有调用 Root 的 JavaScript 桥接。
- 网页仅允许手机本机 HTTP `127.0.0.1:9876` / `localhost:9876`，关闭文件和内容 URL 访问，并禁止截图。原生状态页日志仍可能包含域名和 IP。
- Loopback 不是应用间安全边界，其他本机应用可能访问端口。请设置强管理密码。
- 后台配置由 Root 持有，采用受限目录与 `umask 077`。Root 应用仍可能读取它；这不是对其他 Root 进程的隔离保证。
- 不上传 `config.yaml`、API Token、登录密码、签名私钥、真实运行日志和未脱敏截图。
- 报告普通问题时，只提供最小脱敏信息。漏洞优先使用仓库可用的私密安全报告渠道；不要在公开 Issue 中附凭据或可直接攻击真实设备的信息。

## English

- This tool can perform root operations. Install it only on devices you trust.
- Root commands are restricted to status, start, stop and wake-lock controls. The web UI has no JavaScript-to-root bridge.
- Embedded browsing is limited to local HTTP at `127.0.0.1:9876` / `localhost:9876`, with file/content URL access disabled and screenshots blocked. Native status logs may still contain domains and IPs.
- Loopback is not an app-isolation boundary; other local apps may reach the port. Set a strong management password.
- Backend configuration is root-owned under restricted directory permissions and `umask 077`. Other root processes may still read it.
- Never upload `config.yaml`, API tokens, passwords, signing keys, real runtime logs or unredacted screenshots.
- Share only minimal redacted diagnostics for normal issues. Prefer a private security-reporting channel if available; do not attach credentials or exploitable details of real devices to public issues.
