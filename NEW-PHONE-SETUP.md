# 新手机部署 / New phone setup

这些修复随 APK 发布，不再依赖迁移时的 ADB 补丁。官方 Shizuku 保持原版，不修改授权数据库。仍需 ARM64、兼容的 Root/ROM、首次打开 App 完成系统授权与本机账号配置；无法通过安装 APK 静默授予 Root、Shizuku 或真实电话信息权限。

1. 安装 Asterisk 助手，一键部署；授予 Root 与通知，添加或迁移自己的 SIP 账号。号码分段库内置，默认启用，不需要电脑安装。
2. 安装 Voice SIP 助手，一键部署整合网关与官方 Shizuku。完成下载、签名核对及依赖准备后自动打开网关。首次部署保持网关关闭，授权与账号设置完成后启用。
3. 网关首次打开主动说明并申请电话、电话信息、麦克风、通知权限。小米/澎湃 OS 选择“允许”真实信息，不要选择返回空白信息。点 Grant Shizuku 授权；若网关尚未启用，页面提供直接启用入口，不再让用户猜测灰色按钮的原因。
4. SIP 账号在手机本地配置一次。打开网关开关，确认电话权限、SIM 账户、Shizuku、音频与 SIP 均就绪，再进行真实双向通话验证。
5. 如需公网域名，ddns-go 助手内一键部署，在本地填写 DNS 凭据，并在 Asterisk 配置公网 IPv6。Groundwire 的 IPv6 推送设置仍在 iPhone 完成。

## 修复与边界

- 三个助手自动查找 Magisk、KernelSU/BakaSU、APatch 的受控 BusyBox 路径，不建立假的 KSU 目录或依赖手工软链接。没有可用工具时明确失败；未实测的 Root/ROM 不保证兼容。
- Shizuku 每次绑定最多等待 15 秒，自动重试一次；仍失败时报告明确状态，并向同签名助手请求兼容恢复。只有已授权、启用且无通话时执行恢复。系统阻止后台启动时通知用户打开助手；不自动点击任何授权弹窗。
- 电话权限不仅检查授权标记，还检查活动 SIM 与拨号账户是否可用。信息为空时提示插卡/权限/空白通行证，不假装就绪；缺少本机手机号本身不会被认定为权限失败。不需要通话记录权限。
- Asterisk 内置号码格式化、AGI 空姓名兼容及身份模块准备；保留真实联系人姓名、隐藏号码和原始回拨号码。通话中延后更新。
- Asterisk 在公网 IPv6 运行期间持有 Wi-Fi 接收锁；Android 11–13 默认启用已在 Android 13 验证的息屏兼容，可在助手内关闭。停止服务器后释放，可能增加耗电。
- APK 更新会刷新受保护的运行组件及代码校验值；若 ROM 拦截更新广播，首次打开助手会再次检查。不覆盖 SIP/DDNS 账号，不强制启用手动停用的网关。

## English

The fixes ship inside the APKs, not in an external ADB migration patch. Install and open the assistants, grant Root/notifications, deploy Asterisk and the integrated Voice SIP Gateway, then complete the gateway permission guide and configure your own SIP accounts locally. Shizuku remains the unmodified upstream application. Sensitive permissions cannot be granted silently by installing an APK.

The assistants discover trusted Magisk, KernelSU/BakaSU or APatch BusyBox paths. Gateway service binding has a 15-second timeout with one automatic retry and a signature-protected recovery request to the assistant. Recovery respects permission denial, manual OFF and active calls; if Android blocks background service launch, a notification directs the user to open the assistant.

Phone readiness checks actual subscriptions and callable SIM accounts, including the case where permission flags say granted but the ROM supplies empty data. It never relies on a carrier-provided own phone number. The user must disable MIUI's blank-information option themselves. SIP credentials, DNS tokens and Android Keystore keys are not embedded in the APK or repository.

Asterisk bundles caller-number formatting, the AGI missing-name fix and required caller identity setup. It preserves real contact names and privacy restrictions. Public IPv6 service holds Wi-Fi receive locks; the optional root compatibility worker defaults on for Android 11–13 and releases its owned setting when the server stops. Runtime updates preserve existing accounts and defer formatting changes during calls.

Validated on the connected Redmi running Android 13 and Magisk. Unit and device checks are documented per release; this is not a guarantee of cellular audio or vendor permission behavior on every Android model.

## iPhone VPN / 代理排查

若能拨出但无声音，或账号突然无法连接，先关闭 iPhone VPN/代理再测试 600 回声。本次实测中 VPN 让客户端报告了虚拟地址 `198.18.0.1`，关闭后全部通话恢复。需要同时使用 VPN 时，应在该 VPN 内正确放行 SIP 与语音流量；仅放行域名不一定覆盖语音流量。Android 助手不能代替用户修改 iPhone 的 VPN 设置。

If registration or audio fails, first disable the iPhone VPN/proxy and retest the echo extension. In this device test the VPN advertised `198.18.0.1` and no media reached the server; disabling it restored all call functions. If a VPN is required, its routing must correctly allow both SIP and RTP; a hostname-only exception may not cover media. Android assistants cannot configure the iPhone VPN.
