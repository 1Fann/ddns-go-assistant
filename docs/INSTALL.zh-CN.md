# 安装、升级与卸载

[English](INSTALL.en.md) · [返回首页](../README.md)

## 安装前

- Android 8.0+、ARM64；实际兼容范围见首页。
- Root 管理器提供 `/data/adb/ksu/bin/busybox`、`su -M` 和 `service.d`。
- 电脑安装 ADB，手机开启 USB 调试并确认电脑授权。以下命令假设只连接一台设备；多台时用 `adb -s <序列号>`。
- 为 ADB Shell 授予 Root。不要卸载或清理已有 DDNS 服务来试错。
- 安装器只操作 `/data/adb/ddns-go` 和 `/data/adb/service.d/99-ddns-go.sh`。若这些路径已有其他部署，它会停止，避免覆盖。

## 1. 构建与准备引擎

从仓库根目录运行：

```powershell
$env:ANDROID_SDK_ROOT = 'C:\Android\Sdk'
$env:JAVA_HOME = 'C:\Java\jdk-21'
./app/build.ps1
./prepare-runtime.ps1
```

前者生成测试签名 APK；后者下载固定的官方 v6.17.7 Android ARM64 引擎，验证 SHA-256，再生成 `dist/ddns-go-root-runtime/` 和 ZIP。下载失败或校验不一致时不要继续。上游发行包校验值记录于 [UPSTREAM.md](UPSTREAM.md)。

脚本使用 `223.5.5.5` 作为引擎的启动域名解析服务器，以避开部分安卓 Go 构建尝试访问 `::1:53` 的问题。**这不是 DNS 托管商设置，也不修改路由器。** 如该服务器在你的网络不可用，请先在 `runtime/daemon.sh` 的 `-dns` 参数中换成适合你的 DNS，再准备后台包。

## 2. 安装后台

```powershell
adb push ./dist/ddns-go-root-runtime /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/ddns-go-root-runtime/install.sh'"
adb install ./app/out/ddns-go-assistant-debug.apk
```

新安装默认暂停后台、关闭唤醒锁。打开“ddns-go 助手”，在 BakaSU 中授权 Root，回到 App 点击“刷新状态”。打开“后台运行”即可启动服务并启用开机自启。

安装成功后可以删除部署临时目录：

```powershell
adb shell "su -c 'rm -rf /data/local/tmp/ddns-go-root-runtime'"
```

后台目录仅 Root 可访问；运行时配置在 `/data/adb/ddns-go/config.yaml`。APK 本身不携带 Token。

## 3. 在手机本地配置 DDNS

1. 点击“打开管理页面”，设置用户名与管理密码。
2. 选择 Cloudflare（或其他上游支持的提供商），在手机本地输入自己的凭据，不要发到聊天或 Issue。
3. Cloudflare Token 可限制为目标 Zone，并授予 DNS Edit 和 Zone Read；按 Cloudflare 当前权限界面配置。
4. 只使用 IPv6 时关闭 IPv4 更新，开启 IPv6 更新。
5. IPv6 来源选择“通过命令获取”，输入 `/data/adb/ddns-go/ipv6.sh`。
6. 填写自己的域名，例如 `phone.example.com`，保存并检查官方日志。

没有可用 IPv6 时取址命令输出为空；请在你的配置上验证引擎保留原记录的行为。非临时地址仍可能随网络前缀改变，DDNS 不会使地址永久固定。

管理页面仅在手机本地 `http://127.0.0.1:9876` 可用。App 中的网页禁止截图，没有网页 JavaScript 到 Root 的桥接。Android WebView 需正常可用。

## 4. 日常操作与验证

| 操作 | 作用 |
|---|---|
| 后台运行 | 启停引擎并保存开机自启偏好 |
| 息屏持续运行 | 请求专用 CPU 唤醒锁；增加耗电，内核不支持时无法生效 |
| 刷新状态 | 重新读取服务状态，不等同于立即向提供商更新 DNS |
| 查看日志 | 显示最近日志，可能包含域名和 IP，分享前脱敏 |

检查周期为 300 秒，`cacheTimes=1`。地址不变时不保证每 5 分钟请求一次提供商 API。系统休眠、断网、内核限制可能延迟执行。

首次部署后，至少测试：

- 官方日志出现更新成功或记录未变化，提供商记录与期望地址一致。
- 地址来自 `wlan0`，不带临时、废弃或冲突标记。
- 息屏超过两个周期，观察是否继续检查。
- 重启后，按需要解锁手机，再确认后台和记录状态。

不要仅凭 App 的“服务运行中”判断域名已同步，该状态只代表本地进程。

## 5. 升级

先停止后台，再将 `config.yaml` 做安全的本地备份（它包含凭据，不要上传）。同一签名的 APK 可以 `adb install -r`；不同签名无法覆盖安装，不要为了升级随意清除应用数据。

本安装器管理的后台带 `.ddns-go-android-root` 标记。准备新包后：

```powershell
adb push ./dist/ddns-go-root-runtime /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/ddns-go-root-runtime/install.sh --upgrade'"
adb install -r ./app/out/ddns-go-assistant-debug.apk
```

升级保留运行时 `config.yaml` 和唤醒锁偏好，并恢复升级开始前的运行偏好。若你事先关闭了后台，升级后手动重新开启。引擎升级应检查上游配置兼容性；不要直接把固定版本号替换成“latest”。

**早期手动部署迁移：** 没有上述标记的已有部署会被拒绝。先确认路径确属此项目，安全备份配置，停止旧服务，并逐项比较脚本；不要只为了绕过检查而创建标记。原来为个人手机制作的 v3 APK 可继续控制原后台；这个开源仓库的发布不会自动改动它。

## 6. 签名

正式版本使用仓库外的私钥：

```powershell
# 在本机安全地设置 DDNS_STORE_PASS / DDNS_KEY_PASS，不要写入源码或日志。
./app/build.ps1 -Keystore 'C:\Private\release.jks' -KeyAlias panel
```

脚本从环境变量读取密码，不在参数中传递明文密码。正式产物为 `app/out/ddns-go-assistant.apk`。密钥决定后续 APK 能否覆盖升级，应离线保存。不要提交 JKS、密码文件或 CI 测试签名。

## 7. 卸载

只想暂停：关闭 App 的“后台运行”。仅卸载 APK 不会停止独立后台。

彻底删除后台及本地凭据，先重新推送已审核的后台包，然后执行：

```powershell
adb push ./dist/ddns-go-root-runtime /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/ddns-go-root-runtime/uninstall.sh --remove-data'"
adb uninstall com.mcyao.ddnspanel
adb shell "su -c 'rm -rf /data/local/tmp/ddns-go-root-runtime'"
```

卸载脚本只接受有本项目标记的固定目录；会停止后台、释放锁、删除自启入口及整个后台目录。**这会删除本地 Token 和管理配置，但不会删除 DNS 提供商上的记录，也不会撤销 Token。** 若不再使用 Token，请在提供商控制台撤销。
