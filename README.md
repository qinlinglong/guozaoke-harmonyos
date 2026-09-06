# 过早客 HarmonyOS

过早客社区的 HarmonyOS 客户端，使用 ArkTS、ArkUI 和 ArkWeb 开发。除登录流程外，主要阅读、互动和账号功能使用原生页面。

当前稳定版本：**过早客 HarmonyOS v1.0.4**。

## 功能

- 原生首页、最新、精华、关注和节点主题列表
- 原生主题详情、图片、评论、回复、收藏和分享
- 主题点赞、评论点赞、编辑回复及点赞状态持久化
- ArkWeb 登录、Cookie 会话保存，登录成功后返回原生首页
- 个人中心、我的收藏、我的帖子、我的回复和屏蔽用户
- 搜索、通知、发布主题、评论排序和应用设置
- 头像 CDN 加载与本地占位图降级
- Markdown/GFM 内容、链接跳转、长按复制和图片预览
- sm.ms 默认图床与 Bilibili 图床上传
- 可切换主题色；启动加载图标中的碗跟随主题色，面条为黄色
- 沉浸式状态栏和 HarmonyOS 应用图标

## 系统要求

- HarmonyOS 6.1.1(24) 或更高版本
- 安装包需使用有效的 HarmonyOS 开发者证书签名

## 下载

请在 [过早客 HarmonyOS v1.0.4 Release](https://github.com/qinlinglong/guozaoke-harmonyos/releases/tag/v1.0.4) 下载最新的已签名 HAP 安装包。

安装时请确认设备系统满足 HarmonyOS 6.1.1(24) 或更高版本；如果系统提示 SDK 版本过低，请升级设备系统后再安装。

## 开发与调试

需要 DevEco Studio 6.0+、HarmonyOS API 24+ SDK 以及 `devecocli`。命令行构建不要求启动 DevEco Studio。

```bash
# 查看当前设备
devecocli device list

# 构建 Debug 安装包
devecocli build --modules entry@default --product default --build-mode debug

# 构建并在真机上启动
devecocli run --module entry@default --product default --build-mode debug --device '<device serial>'

# 构建 Release 安装包
devecocli build --modules entry@default --product default --build-mode release
```

仓库提供了不依赖 DevEco Studio 窗口的真机脚本。脚本默认连接 `192.168.0.107:34973`，无线设备请按实际地址覆盖 `DEVICE_SERIAL`：

```bash
# 检查连接
DEVICE_SERIAL='<device serial>' scripts/device-debug.sh connect

# 构建、安装并启动 Debug 包
DEVICE_SERIAL='<device serial>' scripts/device-debug.sh launch

# 查看当前 UI 布局或抓取截图
DEVICE_SERIAL='<device serial>' scripts/device-debug.sh layout
DEVICE_SERIAL='<device serial>' scripts/device-debug.sh screenshot
```

调试时可通过 DevEco Studio 的“保持屏幕常亮”选项，或设备调试命令临时延长屏幕超时。该设置只用于调试，不会让正式 Release 包强制常亮。

构建产物位于 `entry/build/default/outputs/default/`。个人签名配置不应提交到公开仓库；Release 构建需要使用自己的 HarmonyOS 开发者证书签名。

## 项目结构

```text
AppScope/                         应用级配置和图标
entry/src/main/ets/pages/         原生页面
entry/src/main/ets/service/       网络请求、会话与页面解析
entry/src/main/ets/model/         页面数据模型
entry/src/main/resources/         字符串、图标和占位图
```

## Image hosting

“设置 → 图床 API Key”用于保存用户自己的图片服务凭据。API Key 只保存在当前设备，请勿将它写入代码、Issue 或日志。

## Privacy

- 社区内容和账号服务由 [guozaoke.com](https://www.guozaoke.com/) 提供。
- 登录 Cookie 和应用设置保存在用户设备上，用于维持会话和提供原生功能。
- 应用会访问过早客网站及其图片 CDN，不额外收集或销售用户数据。

## 反馈

功能建议和问题反馈请提交到 [GitHub Issues](https://github.com/qinlinglong/guozaoke-harmonyos/issues)。

## 声明

本项目为非官方客户端，与过早客网站共享同一账号会话。使用前请确认并遵守相关社区规则。
