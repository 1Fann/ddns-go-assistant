# Installation, upgrades and removal

[中文](INSTALL.zh-CN.md) · [Project home](../README.en.md)

## Before installing

- Android 8.0+, ARM64; see the README for actual compatibility scope.
- Root must provide `/data/adb/ksu/bin/busybox`, `su -M`, and `service.d` support.
- Install ADB on your computer, enable USB debugging and authorize the computer. Commands assume one connected device; use `adb -s <serial>` for multiple devices.
- Grant root to the ADB Shell. Do not remove an existing DDNS installation merely to try this package.
- The installer only targets `/data/adb/ddns-go` and `/data/adb/service.d/99-ddns-go.sh`. It refuses an unrecognized existing installation.

## 1. Build and prepare the engine

Run from the repository root:

```powershell
$env:ANDROID_SDK_ROOT = 'C:\Android\Sdk'
$env:JAVA_HOME = 'C:\Java\jdk-21'
./app/build.ps1
./prepare-runtime.ps1
```

The first command builds a test-signed APK. The second downloads the pinned official v6.17.7 Android ARM64 engine, verifies SHA-256, and produces `dist/ddns-go-root-runtime/` and a ZIP. Do not continue after download or verification failures. See [UPSTREAM.md](UPSTREAM.md) for provenance.

The supervisor uses `223.5.5.5` as its bootstrap DNS resolver to avoid some Android Go builds falling back to `::1:53`. **This is separate from the DDNS provider and does not change router settings.** If that resolver is unavailable on your network, change the `-dns` argument in `runtime/daemon.sh` before preparing the bundle.

## 2. Install the backend

```powershell
adb push ./dist/ddns-go-root-runtime /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/ddns-go-root-runtime/install.sh'"
adb install ./app/out/ddns-go-assistant-debug.apk
```

A fresh install leaves background running and wake locking disabled. Open ddns-go Assistant, grant root in BakaSU, and refresh status. Turn on “Run in background” to start the engine and enable boot startup.

After successful installation, remove the staging directory:

```powershell
adb shell "su -c 'rm -rf /data/local/tmp/ddns-go-root-runtime'"
```

The backend directory is root-only. Runtime configuration is stored in `/data/adb/ddns-go/config.yaml`. The APK contains no API token.

## 3. Configure locally on the phone

1. Open management and create an administrator username and password.
2. Select Cloudflare or another upstream-supported provider. Enter your own credentials locally; never post them in chat or issues.
3. A Cloudflare token can be restricted to the target zone with DNS Edit and Zone Read. Follow the current Cloudflare permissions UI.
4. Disable IPv4 updates if only IPv6 is needed; enable IPv6 updates.
5. Choose command-based IPv6 detection and enter `/data/adb/ddns-go/ipv6.sh`.
6. Enter your own domain, such as `phone.example.com`, save, and inspect the upstream logs.

The detection command returns no output when no eligible IPv6 exists. Verify preservation of existing records with your configuration. A non-temporary address can still change when the network prefix changes; DDNS does not make an address permanent.

Management is available only on the phone at `http://127.0.0.1:9876`. The embedded management page disables screenshots and has no JavaScript-to-root bridge. A working Android WebView is required.

## 4. Controls and validation

| Control | Effect |
|---|---|
| Run in background | Starts/stops the engine and persists the boot-start preference |
| Keep CPU awake | Requests a dedicated CPU wake lock; consumes power and requires kernel support |
| Refresh status | Reads local state; does not force an immediate provider update |
| View logs | Shows recent logs, which may include domains and IPs; redact before sharing |

The polling interval is 300 seconds with `cacheTimes=1`. Unchanged addresses do not necessarily cause a provider API request every five minutes. Sleep, connectivity and kernel restrictions can delay execution.

After initial deployment, verify at least:

- Upstream logs report a successful update or unchanged records, and the provider record matches the expected address.
- The address belongs to `wlan0` and has no temporary, deprecated or conflict flags.
- Checks continue after the screen has been off for more than two intervals.
- After rebooting and unlocking if required, the service and record are correct.

“Service running” only describes local processes; it is not proof of DNS synchronization.

## 5. Upgrade

Stop the service and make a secure local backup of `config.yaml` first; it contains credentials and must not be uploaded. APKs signed with the same key can be upgraded with `adb install -r`. Different signatures cannot upgrade each other; do not casually clear app data.

Managed installations contain a `.ddns-go-android-root` marker. After preparing an updated bundle:

```powershell
adb push ./dist/ddns-go-root-runtime /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/ddns-go-root-runtime/install.sh --upgrade'"
adb install -r ./app/out/ddns-go-assistant-debug.apk
```

The upgrade preserves runtime `config.yaml` and the wake-lock preference, and restores the running preference from the start of the upgrade. If you stopped the service beforehand, re-enable it manually. Check upstream configuration compatibility before changing engine versions; do not replace the pinned version with an unverified “latest”.

**Early manual deployments:** installations without the marker are refused. Verify ownership of the directory, securely back up configuration, stop the old service and compare scripts before migrating. Do not create the marker merely to bypass the check. The earlier personal v3 APK can continue managing its original backend; publishing this repository does not modify that installation.

## 6. Release signing

Use a private signing key outside the repository:

```powershell
# Set DDNS_STORE_PASS / DDNS_KEY_PASS securely on your computer; do not put them in source or logs.
./app/build.ps1 -Keystore 'C:\Private\release.jks' -KeyAlias panel
```

Passwords are read from environment variables rather than passed as plaintext arguments. The output is `app/out/ddns-go-assistant.apk`. Keep the key offline and backed up; future APK upgrades require the same signing identity. Never commit JKS files, password files or CI test keys.

## 7. Uninstall

To pause, turn off background running. Uninstalling only the APK does not stop the independent backend.

To remove the backend and local credentials, push the reviewed bundle again and run:

```powershell
adb push ./dist/ddns-go-root-runtime /data/local/tmp/
adb shell "su -c 'sh /data/local/tmp/ddns-go-root-runtime/uninstall.sh --remove-data'"
adb uninstall com.mcyao.ddnspanel
adb shell "su -c 'rm -rf /data/local/tmp/ddns-go-root-runtime'"
```

The uninstaller only accepts the fixed, ownership-marked directory. It stops the service, releases the lock, removes boot startup and deletes the backend directory. **Local tokens and management configuration are deleted; provider DNS records remain and tokens are not revoked.** Revoke an unused token in the provider console.
