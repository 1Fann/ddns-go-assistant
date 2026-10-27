# 验证范围 / Validation scope

## 已验证 / Verified

- 原始个人部署：Redmi Note 10 Pro、移植版澎湃 OS 4、BakaSU、ARM64；取址、Cloudflare AAAA 更新、重启自启、CPU 唤醒锁状态、原生控制界面。
- Original personal deployment: IPv6 selection, Cloudflare AAAA updates, reboot startup, CPU wake-lock state and native controls on Redmi Note 10 Pro / ported HyperOS 4 / BakaSU / ARM64.
- 公开版：英文/中文资源与 Java 编译、APK 签名校验、Shell 语法检查、IPv6 过滤样例。查看 Actions 获取每次提交的实际检查结果。
- Public source: EN/ZH resources and Java compilation, APK signature verification, shell syntax checks and IPv6 filtering fixtures. Check Actions for results on each commit.
- v3.2.0：在同一 Redmi 手机的独立测试目录和端口验证了 App 内推荐版下载部署；更新后配置逐字一致；故意破坏新后台启动后成功恢复旧后台；暂停偏好保留；残留事务目录阻止覆盖。测试未替换手机原有生产后台。
- v3.2.0: tested in-app recommended deployment in an isolated directory and port on the same Redmi phone; byte-for-byte configuration preservation; rollback after deliberately failing the replacement daemon; paused-state preservation; refusal to overwrite interrupted transactions. Tests did not replace the existing production backend.
- 归档单元测试覆盖正确 ELF、SHA-256 不匹配、路径穿越成员、符号链接、重复引擎成员、错误架构和错误 tar 头。
- Archive tests cover valid ELF, checksum mismatch, traversal members, symlinks, duplicate engine entries, wrong architecture and corrupt tar headers.
- 最新版选项：实测官方 Release 元数据解析、官方资产 API 下载、SHA-256 校验、引擎替换和管理端可用。测试时最新稳定版与推荐版均为 v6.17.7。普通发行页下载链接曾在手机网络上超时，最新版改用官方资产 API 后完成。
- Latest option: verified official Release metadata resolution, asset API download, SHA-256 verification, engine replacement and management availability. Both latest and recommended were v6.17.7 during testing. Browser release-download URLs timed out on the phone network; the official asset API completed the latest-release flow.

## 未验证与限制 / Not yet validated and limitations

- 不同设备上的完整安装、升级和卸载流程；所有 ROM / KernelSU / Magisk 组合；长时间无人值守运行与耗电。断电或强制杀进程后的人工恢复尚未实机验证。
- End-to-end installation/upgrade/uninstall across devices; every ROM / KernelSU / Magisk combination; extended unattended operation and battery usage. Manual recovery after power loss or forced process termination has not been device-tested.
- Android 最低版本声明为 8.0 不代表已经在 Android 8.0 实机验证。
- A minimum SDK of Android 8.0 is not a claim of physical-device testing on Android 8.0.
- 没有可用地址、网络切换、多个有效地址、唤醒锁内核接口缺失等情况，需要按设备继续验证。
- No-address scenarios, network changes, multiple eligible addresses and kernels without wake-lock interfaces require further device-specific validation.
- 300 秒为配置的检查间隔，不是实时执行承诺。系统调度和网络状态可能导致延迟。
- 300 seconds is the configured polling interval, not a real-time execution guarantee.

## 本地检查 / Local checks

```sh
sh tests/test-ipv6.sh
for f in runtime/*.sh tests/*.sh; do sh -n "$f"; done
```

Android BusyBox 可运行同一过滤测试 / Android BusyBox can run the same filtering test:

```sh
BUSYBOX=/data/adb/ksu/bin/busybox /data/adb/ksu/bin/busybox ash tests/test-ipv6.sh
```

样例使用文档专用的 `2001:db8::/32` 地址，不是真实设备地址。测试只验证过滤规则；输入已由 `ip ... dev wlan0 scope global` 限定接口。

Fixtures use documentation-only `2001:db8::/32` addresses, not real device addresses. Tests cover filtering rules; the caller restricts input with `ip ... dev wlan0 scope global`.
