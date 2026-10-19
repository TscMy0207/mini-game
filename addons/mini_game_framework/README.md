# Mini Game Framework

可复用的 Godot 小游戏运行时基础层。

## 启动与场景职责

- `app/bootstrap/boot.tscn` 是唯一启动场景，动态显示不依赖 UIService 的 `LoadingUI`。
- `FrameworkRoot` 在启动阶段创建并挂到 `SceneTree.root`，服务可跨主场景存活。
- `app/main/main.tscn` 仅保留 `MainRoot`；它动态创建 `GameRoot`、`UIRoot`，先加载 `MainMenuUI`，点击开始后才实例化猫咪棋盘玩法。
- `app/main/presentation/main_menu_ui.tscn` 是主界面资源，通过 `UIService` 动态加载。

运行流程：

```text
BootScene -> LoadingUI -> FrameworkRoot -> MainScene
                                          -> MainMenuUI
                                          -> 点击开始
                                          -> CatBoardGame + CatBoardUI
```

## 运行时服务

- `ServiceRegistry`、`FrameworkLogger`、`EventBus`
- `PlatformService`、`PlatformBridge`、`InputRouter`
- `StorageService`、`ConfigService`、`LocalizationService`
- `ResourceService`、`UpdateService`、`SceneFlow`
- `AudioService`、`ObjectPool`、`UIService`、`ModuleLoader`

业务层只依赖服务 ID。场景、UI、预制节点与 JSON 内容均以逻辑资源 ID 定义在 `content/manifests/resources.json`。

## 资源加载边界

`ResourceService` 负责资源 ID 到路径的解析、缓存、JSON 加载以及 PCK 挂载后的清单刷新。 `ModuleLoader` 和 `UIService` 只向资源服务请求场景并负责实例化和生命周期管理。

```text
业务模块 / UIService / ModuleLoader
              -> ResourceService.load_resource(resource_id)
              -> 资源清单、缓存、已挂载 PCK
              -> PackedScene / JSON
```

## PCK 更新流程

1. BootScene 创建 LoadingUI 与 FrameworkRoot。
2. UpdateService 读取本地或远端版本清单。
3. 新 PCK 下载到 `user://mini_game/content`，完成 SHA-256 校验后原子落盘。
4. 启动流程挂载 PCK，刷新资源清单和配置表。
5. 预加载主场景，再进入动态装配的主场景。
6. 主场景先动态加载主界面，用户点击开始后再加载猫咪棋盘玩法。

启动层和框架服务属于首包；业务模块、表现资源与配置属于内容包。这样 PCK 失败时仍可走离线内容启动。
