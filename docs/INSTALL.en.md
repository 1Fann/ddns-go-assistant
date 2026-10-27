# Installation, upgrades and removal

[中文](INSTALL.zh-CN.md) · [Project home](../README.en.md)

## Before installing

- Android 8.0+, ARM64; see the README for actual compatibility scope.
- Root must provide `/data/adb/ksu/bin/busybox`, `su -M`, and `service.d` support.
- Only the manual ADB route requires a computer, USB debugging and root for the ADB Shell. In-app deployment does not. ADB commands assume one connected device; use `adb -s <serial>` for multiple devices.
- Do not remove an existing DDNS installation merely to try this package.
- The installer only targets `/data/adb/ddns-go` and `/data/adb/service.d/99-ddns-go.sh`. It refuses an unrecognized existing installation.

## In-app deployment (recommended; no ADB needed)

The ADB sections below are a manual alternative. Since v3.2.0, install the APK and open “Install / update backend”:

1. Grant root in BakaSU and allow installation progress notifications.
2. Choose the recommended version or the latest stable GitHub release, then tap the install button.
3. Wait for compatibility checks, download, SHA-256 verification, deployment and startup checks. Work continues when switching pages; do not force-stop the app or reboot during installation.
4. A fresh deployment enables background running and boot startup, with the long-term wake lock off. Open management and configure your account, token, domain and IPv6 detection command.

Existing managed installations retain configuration and running preferences. A previously paused service remains paused; enable it on the home screen before opening management. Earlier manual installations without an ownership marker are not overwritten; the home screen can continue managing them.

Recommended downloads use a built-in SHA-256. Latest downloads resolve the official Release API, accept stable semantic version tags and the Android ARM64 asset, and use its API digest or release checksums.txt. Rate limits, network failures, missing checksums and unsupported architectures stop installation rather than bypass verification. The foreground notification and temporary CPU wake lock are only for deployment; they do not enable long-term screen-off wake locking.

## Interrupted installation and recovery

Updates stop the old service, retain its directory at `/data/adb/ddns-go.rollback`, switch to the new directory and check the local management port. Normal failures attempt to restore old files and the running preference. Successful updates delete the temporary rollback copy to avoid duplicate credentials.

Power loss or force-killing a process can prevent rollback. If `.pending` or `.rollback` remains, the installer reports `RECOVERY_REQUIRED` and refuses further overwrites. **These directories may contain credentials; never upload them.** Inspect the service and both directories with root: securely back up configuration and stop any remaining processes first. If `.rollback` is complete, restore it to the original directory and restore its `.previous-boot` file as the boot entry. If integrity is unclear, preserve the files and ask a maintainer for help instead of deleting recovery data or bypassing ownership checks.

Automatic rollback is an attempt to restore files, not a substitute for secure configuration backups. Paused installations receive only a version execution check; they are not activated merely to test DNS updates.

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
