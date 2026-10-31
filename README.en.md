# ddns-go Android Root

**Latest: 3.3.4** — [新手机部署与权限说明 / New-phone setup](NEW-PHONE-SETUP.md)

Detect Magisk, KernelSU/BakaSU and APatch BusyBox automatically. Upgrade bundled controls while preserving DNS credentials, intervals and wake-lock choices.

[中文](README.md) | **English**

**[Download the release APK](https://github.com/1Fann/ddns-go-assistant/releases/latest)** · [Changelog](CHANGELOG.md)

A lightweight **ddns-go Assistant** for rooted Android phones: inspect service status, control boot startup and a CPU wake lock, and open the upstream management UI inside the app.

**Experimental · Unofficial · Root required.** Since v3.2.0, the app can download, verify and deploy the official engine without a computer. You must still grant root and configure DDNS credentials locally. This project is not affiliated with jeessy2/ddns-go or OpenListApp.

## Features

- In-app deployment: recommended v6.17.7 by default, or the latest stable release from official GitHub. The installer currently supports ARM64 only.
- SHA-256 verification, restricted archive extraction, progress notification, configuration preservation and rollback on failed startup checks. Missing checksums stop installation.
- The backend runs independently of the app and continues after the UI closes.
- Independent watchdog and daemon peers recover exited/stalled supervision. Three consecutive failed local HTTP checks trigger engine recovery; deliberate pauses remain paused.
- Selects a non-temporary IPv6 address in `2000::/3` from `wlan0`, rejecting `temporary`, `secondary`, `deprecated`, `tentative`, `dadfailed`, and zero preferred lifetime.
- Keeps the previously selected address while it remains eligible, avoiding churn between multiple candidates.
- Update DNS immediately or set a persistent 1–1440 minute interval on the home screen (default: 5 minutes). Unchanged records are retained.
- Uses the BakaSU/KernelSU `service.d` boot hook and offers a separate screen-off CPU wake-lock switch.
- Management listens only on `127.0.0.1:9876`. The app does not call Cloudflare APIs directly.
- Native UI supports English and Chinese based on the system locale. The web UI and engine logs are provided by upstream.
- No Termux dependency or router changes.

## Scope and compatibility

The original deployment verified address selection, DNS updates and reboot startup on a **Redmi Note 10 Pro, a ported HyperOS 4 ROM, BakaSU, ARM64**. The public installer/uninstaller have not been validated across multiple phones. See [validation scope](docs/TESTING.md).

Requires root-manager BusyBox (Magisk, KernelSU/BakaSU and APatch paths are detected), root access supporting `su -M`, and a working `service.d` hook. CPU wake locking also requires `/sys/power/wake_lock` and `wake_unlock`. **Compatibility with every KernelSU version, Magisk or custom ROM is not claimed.**

Wake locking uses more battery and is off by default on a fresh installation. It reduces deep-sleep delays; it does not guarantee real-time scheduling. Network loss, kernel restrictions and service failures still affect checks.

Process liveness normally polls every second; HTTP probes, heartbeat writes and wake-lock renewal remain on a roughly 30-second cadence. Stalled supervision still requires four unchanged slow heartbeats. The first engine exit recovers quickly; repeated crashes back off from 2 to 30 seconds. Without the wake lock, CPU suspend postpones polling; ordinary shell loops cannot wake the CPU. Local HTTP readiness does not prove DNS-provider delivery. Simultaneous loss of both peers, whole-system failures and reboot gaps still require external monitoring. Lock-screen credentials and encryption remain unchanged.

## Install and use

Read the **[English installation guide](docs/INSTALL.en.md)** / [中文安装指南](docs/INSTALL.zh-CN.md).

1. Install the APK, open “Install / update backend”, and grant root and progress-notification permissions.
2. Keep the recommended version or select “Latest stable release on GitHub”, then tap “Grant root and install / update”. Fresh deployments start automatically with the screen-off wake lock disabled.
3. Open management to create a local administrator account. Existing managed installations retain their running preference.
4. Select a provider such as Cloudflare and enter your own credentials and domain locally. Set IPv6 detection to command mode with `/data/adb/ddns-go/ipv6.sh`.
5. Enable “Keep CPU awake” if required, and verify actual behavior in the logs.

“Update DNS now” restarts the current single backend to trigger an immediate upstream check; management may require signing in again. Interval changes apply immediately and keep paused backends paused. First launch of a newer app updates helpers for app-managed deployments, reusing the local engine and preserving DNS configuration. The management page controls API, network-interface or command detection; use the filtering command above when non-temporary IPv6 selection is required.

Do not put API tokens in shell commands, issues, screenshots or the repository. No working credentials or preconfigured domains are included. Disable IPv4 updates in the upstream UI if you only need IPv6.

The phone needs HTTPS access to GitHub APIs, release pages and release-asset hosts. Latest releases are verified using the official API SHA-256 digest or checksums.txt from the same release; this does not imply compatibility testing. Earlier manual installations are not silently overwritten; see the migration guide.

## Layout

```text
app/                  Native Java app, EN/ZH resources, Windows build script
runtime/              Startup, supervision, IPv6, wake-lock, install/uninstall scripts
tests/                IPv6 filtering fixtures
docs/                 Bilingual installation, validation and security documentation
prepare-runtime.ps1   Download and verify a pinned official engine
```

The recommended engine is the unmodified official **v6.17.7 Android ARM64** release; the latest stable release is optional. Engines are downloaded from upstream and are not committed here. The engine also serves its own web UI. See [upstream provenance](docs/UPSTREAM.md).

## Build

Requires Windows, PowerShell, JDK 21, Android SDK Platform 35 and Build Tools 35.0.0:

```powershell
$env:ANDROID_SDK_ROOT = 'C:\Android\Sdk'
$env:JAVA_HOME = 'C:\Java\jdk-21'
./app/build.ps1
./prepare-runtime.ps1
```

The default output is `app/out/ddns-go-assistant-debug.apk`, signed with a locally generated test key. See the installation guide for release signing with a key outside the repository. GitHub Actions builds a test APK and checks scripts. CI test keys may differ between runs and are not a stable update identity.

## Other Android options

[OpenListApp/ddnsgo-android](https://github.com/OpenListApp/ddnsgo-android) is a no-root Android integration. This project targets rooted devices needing an independent backend and specific Wi-Fi IPv6 selection rules. These are different deployment models; this project does not claim superior reliability or battery life.

## Feedback and license

Compatibility reports are welcome. Include the phone model, Android/ROM, root-manager version and a redacted error description. **Never attach `config.yaml`, tokens, passwords or unchecked full logs.**

Project code is [MIT licensed](LICENSE). ddns-go retains its own [MIT license](runtime/LICENSE.ddns-go). The original package name `com.mcyao.ddnspanel` is retained for upgrade compatibility; it does not bind the app to a domain or account.
