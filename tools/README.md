# 内容构建与本地 CDN

## 内容包构建

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/content_builder/build_content.ps1 -GodotExecutable godot
```

构建脚本使用 `ContentPack` 预设，只导出 `games/cat_board` 与 `content`。启动场景、框架服务、平台桥接和主场景留在首包，保证热更新失败时仍可离线启动。

## 本地 CDN 验证

```powershell
python tools/local_cdn/server.py --root ..\cat-mini-game-artifacts\cdn --port 8080
```

开发验证时，把 `app/config/bootstrap_config.json` 的 `remote_manifest_url` 改为 `http://127.0.0.1:8080/manifest.json`。启动场景会下载、校验 SHA-256、缓存并挂载 PCK；验证后应将该地址恢复为空。

## 发布约定

- CDN `manifest.json` 由构建脚本生成，资源包使用版本化缓存路径。
- PCK 中可覆盖 `content/manifests/resources.json` 和业务模块资源，框架首包不通过热更替换。
- 微信上线时将 Web 导出与 PCK 导出替换为对应小游戏导出器，并保持相同的内容清单格式。
