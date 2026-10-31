# Ad Hoc 打包发布

在项目根目录运行（需要 Python 3、curl、Xcode、MonkeyDev，以及已登录的 Apple 开发者账号和可用的 Ad Hoc 分发签名）：

```bash
./scripts/package-adhoc.sh
./scripts/package-adhoc.sh --description "修复问题，更新内测版本"
```

MonkeyDev 禁止直接执行 `archive`。脚本先以 `bluedXHook` Scheme 的 Release 配置正常 `build`，保留 MonkeyDev 注入、branding 和签名流程，再把最终 App 与 dSYM 组装为 `.xcarchive`，交给 Xcode 使用 `release-testing`（Xcode 16+ 对 Ad Hoc 的命名）重新分发签名导出。Team ID 默认为项目现有的 `UDPNB3LZ37`，可用 `--team` 覆盖。测试设备需要已加入分发描述文件。构建日志为 `build.log`，导出日志为 `export.log`。

蒲公英默认读取 `/Users/bear/Desktop/ziyun/buildScript/projects/projectZiyun/.env` 中的 `PGYER_API_KEY`，支持 `--config /path/to/.env`，进程环境变量优先。飞书固定使用 `package_adhoc.py` 中配置的唯一机器人，不读取原配置中的开发／测试／正式群地址。该机器人启用签名校验时，可通过进程环境变量 `FEISHU_SECRET` 设置它的签名密钥。

每次运行使用 `build/adhoc/<时间>/`，可用 `--output` 更换父目录。流程结束时自动删除本次的 `DerivedData` 编译缓存和 `.xcarchive` 归档；蒲公英发布成功后还会删除 `export` 目录（包含 IPA），即使后续飞书通知失败也会清理。仅保留构建日志、导出配置和发布记录。未确认发布成功时保留导出包用于重试，需要时手动删除；通过 `--ipa` 指定的文件始终保留。强制终止进程、断电等情况可能来不及清理。此前运行留下的目录不会自动删除。

上传按[蒲公英官方快速上传流程](https://www.pgyer.com/doc/view/api_upload)执行，等待发布成功后才发送飞书成功通知；构建或上传失败会尝试发送失败通知。

上传失败时，可以跳过构建上传已有包：

```bash
./scripts/package-adhoc.sh --ipa "/absolute/path/bluedXHook.ipa"
```

如果蒲公英已发布、只有飞书通知失败，脚本会保留并输出下载地址，以非零状态退出，无需重新上传。`--ipa` 不转换签名，请传入已有 Ad Hoc 包。

构建及导出时每 15 秒输出耗时和当前阶段；导出时还会显示 Xcode 分发日志目录，并摘要提示证书检查、描述文件创建、重签名等阶段。上传时显示 curl 进度条，蒲公英后台发布时逐次显示轮询状态。Release 构建最多等待 30 分钟，Ad Hoc 导出默认最多等待 15 分钟，可用 `--export-timeout 1200` 调整。超时后停止相关子进程，再发送失败通知并清理。飞书成功通知在蒲公英发布完成后发送；构建、导出或上传仍在进行时不会发送成功通知。脚本修改只对下次运行生效。
