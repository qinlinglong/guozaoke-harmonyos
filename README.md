# guozaoke-harmonyos

过早客 HarmonyOS 客户端，使用 ArkTS、ArkUI 和 ArkWeb 开发。

## 当前功能

- 原生首页主题列表
- 原生主题详情
- ArkWeb 登录与 Cookie 会话同步
- 登录成功后自动返回原生页面
- 头像和主题信息加载

## 构建

需要 DevEco Studio 6.0+、HarmonyOS API 26 SDK 和 `devecocli`：

```bash
devecocli build
```

构建产物位于 `entry/build/default/outputs/default/`。未配置华为签名时生成的 HAP 仅用于开发测试，不能直接面向普通用户安装。

## 下载

可从 GitHub Releases 下载测试安装包。正式发布包需要使用华为开发者签名配置重新构建。
