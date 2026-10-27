# Release packages / 正式发行包

Prepared, signed APKs in version directories are published to GitHub Releases only after the source checks and Android build pass on `main`. `SHA256SUMS` verifies each prepared APK. Existing releases are not overwritten.

版本目录中的 APK 使用稳定正式签名，只有 `main` 分支的源码检查和 Android 编译通过后，才会自动发布到 GitHub Releases。`SHA256SUMS` 用于校验 APK，已有 Release 不会被覆盖。

The signing private key and passwords stay outside the repository and GitHub Actions. The APK includes only app code and generic helper assets; it contains no deployed configuration, account, token or downloaded engine.

签名私钥和密码保留在仓库及 Actions 之外。APK 只包含应用代码及通用适配脚本，不包含手机配置、账号、Token 或下载的引擎。
