# 验证范围 / Validation scope

## 已验证 / Verified

- v3.3.4: offline scheduler checks execute the actual shell expressions to verify one-second polling, thirty-second slow work and unchanged 0/2/4/8/16/30-second first/repeated-exit delays. Fixture substitution tests confirm marked fast polls and stop waits are transformed independently. New Android isolation/device measurements remain separate acceptance work.
- v3.3.4：离线执行实际Shell调度表达式，确认1秒轮询、30秒慢检查和原有首次/连续失败退避；验证隔离夹具不会把快轮询误改为停止等待。新的Android隔离和业务恢复时间由真机验收另测。

- v3.3.3：隔离假引擎、真实 2 秒轮询的 Android BusyBox 测试测得 daemon 恢复 1.46 秒（原引擎保持不变）、watchdog 恢复 1.60 秒、首次引擎退出恢复 2.10 秒。数值为当次样本，不是恢复时限保证。加速回归验证 HTTP/唤醒锁/心跳仍按慢周期执行、快速轮询不追加日志、连续快速巡检不会提前触发心跳误杀及连续崩溃退避。
- v3.3.3: isolated real-cadence samples measured 1.46s daemon recovery without replacing its engine, 1.60s watchdog recovery and 2.10s first engine-exit recovery. These are samples, not timing guarantees. Accelerated fault tests cover independent slow work, no fast-poll log writes, unchanged heartbeat tolerance and repeated-crash backoff.

- v3.3.2: Android BusyBox tests use a new isolated directory, fake engine and stubbed health responses; no production credentials, processes or kernel wake-lock files. Covered daemon SIGKILL with orphan adoption, killed-watchdog recovery, daemon SIGSTOP, repeated health failure, duplicate starts, stale PID/lock files, deliberate pause, wake-lock contention, and forced HTTP deadline. These tests do not establish real DNS delivery or overnight sleep reliability.
- v3.3.2：真实 Android BusyBox 隔离故障测试覆盖监督进程被杀/挂起、watchdog 被杀、假活、重复启动、过期 PID/锁、手动暂停、唤醒锁竞争与 HTTP 超时；测试使用假引擎和隔离路径，未操作生产配置、进程或内核唤醒锁。不等同于已验证真实 DNS 更新或整夜息屏。

- v3.3.0：同一 Redmi 手机由新版 App 自动升级已管理的后台适配脚本，配置逐字保留；实测立即更新重启单实例引擎、两分钟参数生效、暂停时修改间隔仍保持暂停、拒绝非法间隔和暂停时立即更新。最后恢复五分钟及原运行状态。
- v3.3.0: the updated app upgraded helpers for the managed deployment on the same Redmi phone with byte-for-byte configuration preservation. Verified manual-update engine restart, an active two-minute argument, interval changes while paused, rejection of invalid values and manual updates while paused. Restored the original five-minute interval and running state afterward.
- 间隔单元检查覆盖有效值、越界、非整数、过长数字、注入字符串、缺失文件及无效文件的五分钟回退。
- Interval fixtures cover valid inputs, bounds, non-integers, excessive digits, injection strings, missing files and the five-minute fallback for invalid files.

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
- 默认 300 秒，可在首页修改；检查间隔不是实时执行承诺。系统调度和网络状态可能导致延迟。
- The default is 300 seconds and can be changed on the home screen. Intervals are not real-time guarantees; scheduling and network conditions can cause delays.

## 本地检查 / Local checks

```sh
sh tests/test-ipv6.sh
sh tests/test-interval.sh
python3 tests/test-cadence.py
BUSYBOX=/absolute/path/to/busybox sh tests/test-reliability.sh
for f in runtime/*.sh tests/*.sh; do sh -n "$f"; done
```

Android BusyBox 可运行同一过滤测试 / Android BusyBox can run the same filtering test:

```sh
BUSYBOX=/data/adb/ksu/bin/busybox /data/adb/ksu/bin/busybox ash tests/test-ipv6.sh
```

样例使用文档专用的 `2001:db8::/32` 地址，不是真实设备地址。测试只验证过滤规则；输入已由 `ip ... dev wlan0 scope global` 限定接口。

Fixtures use documentation-only `2001:db8::/32` addresses, not real device addresses. Tests cover filtering rules; the caller restricts input with `ip ... dev wlan0 scope global`.

## 2026-10-31 Redmi / MIUI 14 device verification

Installed same-signature updates on one Redmi Note 10 Pro running Android 13, MIUI 14 and Magisk. Existing application data and monitor settings were retained. The device currently has no secure lock-screen credential; no lock-screen setting was changed.

真实息屏测试中，分别结束五项套件的检测工作进程，均自动恢复：Voice SIP 15.3 秒、Asterisk 6.8 秒、Bark 11.2 秒、短信互联 11.1 秒、DDNS 28.6 秒。这里只结束检测工作进程，没有用结束真实通话或发送短信来测试。

整机重启一次，全程没有手动解锁或打开应用；约 67 秒后，所需前台服务和重启后的新检测记录齐备。随后确认网关 SIP 注册、Shizuku 连接、音频就绪、本机短信 HTTPS、Bark ping 及 DDNS 本机健康正常。DDNS 配置和原偏好摘要保持一致。

随后强制进入深度 Doze 75 秒，Voice SIP、Asterisk、短信互联和 Bark 的检测记录均在此期间更新，电话检查状态正常。已退出强制 Doze，恢复正常电源策略。

These are service-readiness tests, not new end-to-end cellular calls, actual SMS delivery, APNs delivery, or an overnight battery-powered suspend test. No automatic real calls or messages were sent. Unattended boot on this device does not establish Direct Boot support before first credential unlock on a password-protected device. Existing wake-lock preferences were preserved; no global battery policy was disabled.

## 2026-10-31 recovery-speed follow-up

The second pass removes fixed first-failure waits, adds inexpensive cached-process checks, and keeps backoff for repeated failures. Full network checks retain their configured cadence. These measurements replace neither the original baseline above nor its stated limitations.

| Component | Checker replacement (s) | Actual local service ready after process kill (s) |
|---|---:|---:|
| voice | 0.3 | 13.16 |
| asterisk | 0.2 | 11.77 |
| sms | 1.9 | 2.69 |
| bark | 1.4 | 1.48 |
| ddns | 2.1 | 1.41 |

Phone readiness required SIP registration plus the gateway’s connected Shizuku and ready audio flags; PBX readiness required the engine and gateway registration. SMS, Bark and DDNS required successful local HTTP(S) responses, with the configured Host header retained for SMS. No real call, SMS or push notification was generated. Measurements include polling overhead and are not upper bounds for network faults or repeated failures.

In the final unattended reboot, Android reported boot completion at 36.8 seconds; all five service checks were simultaneously ready by 69.39 seconds. These timings include the operating-system restart and polling overhead; the initial 67-second baseline above used foreground-service presence and fresh monitor records, so it is not the same measurement.

The unattended reboot phase measurements and final installed artifact hashes are recorded in `D:/CodeX/HELP/reliability-20261031/speed-verification.json`. No unlock input or app-launch request was sent by that test. The device had no secure screen-lock credential before testing; no lock-screen setting was changed.

<!-- recovery-target-20261031:start -->
## 2026-10-31 恢复目标实机复测

红米 Note 10 Pro / MIUI 14，接电、息屏、ADB 连接，沿用现有唤醒设置。每次终止单个进程前均确认蜂窝与 PBX 空闲。

- 守护工作进程（DDNS）：1.31, 0.88 s（范围 0.88–1.31 s）。
- DDNS业务进程退出至本地就绪：0.89, 1.41 s（范围 0.89–1.41 s）。整机重启后该项首次观测就绪：25.59 s。

重启各时间均从同一次重启请求起算。全部六项首次齐备 61.97 s，稳定确认 66.12 s；无安全锁屏凭据，观察者未输入解锁、未主动启动界面或服务。强制深度休眠 77.66 s，4 次抽查六项服务与五个工作进程均正常，结束后已解除强制状态。

数值为本机含探测开销的首次观测，不是普适上限。守护与业务分别连续抽样确认至少 1 秒和 3 秒。电话就绪检查含网关状态及匹配的 PBX 注册记录；本次未拨打真实电话、发送短信或通知，也未验证外网送达或双向通话音频。
<!-- recovery-target-20261031:end -->
