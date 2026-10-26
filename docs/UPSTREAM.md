# 上游来源 / Upstream provenance

- Engine / 引擎：[jeessy2/ddns-go](https://github.com/jeessy2/ddns-go)
- Pinned release / 固定版本：[v6.17.7](https://github.com/jeessy2/ddns-go/releases/tag/v6.17.7)
- Asset / 发行文件：`ddns-go_6.17.7_android_arm64.tar.gz`
- Download / 下载：[official archive](https://github.com/jeessy2/ddns-go/releases/download/v6.17.7/ddns-go_6.17.7_android_arm64.tar.gz)
- SHA-256: `1e9dd881e81e5043820f145a82d0df71bfe9b66f4a4d8813bdea5a7f131925fd`
- License / 许可证：[MIT, copyright 2020 jeessy](../runtime/LICENSE.ddns-go)

本项目不修改官方引擎或网页，不包含 OpenListApp 项目的代码。引擎二进制只在本机准备后台包时下载，不提交到源码仓库。重分发引擎时保留其许可证及适用的第三方声明。版本固定用于复现，不代表它永远是最新版。

This project does not modify the upstream engine or web UI and includes no OpenListApp code. The engine is downloaded when preparing a local backend bundle and is not committed to this source repository. Retain its license and applicable third-party notices when redistributing it. Pinning supports reproducibility; it is not a claim that this version will always be current.

Root 启动、地址筛选、唤醒锁和 Android 原生界面由本项目提供。没有 Root 时可另行评估 [OpenListApp/ddnsgo-android](https://github.com/OpenListApp/ddnsgo-android)。

Root startup, address filtering, wake locking and the native Android interface are provided by this project. For a no-root alternative, evaluate [OpenListApp/ddnsgo-android](https://github.com/OpenListApp/ddnsgo-android).
