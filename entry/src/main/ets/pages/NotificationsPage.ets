import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
@Entry @Component
struct NotificationsPage { controller: webview.WebviewController = new webview.WebviewController(); build() { Column() { Row() { Text('‹').fontSize(32).fontColor('#1677C8').onClick(() => router.back()); Text('通知').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); }.width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White); Web({ src: 'https://www.guozaoke.com/notifications', controller: this.controller }).javaScriptAccess(true).domStorageAccess(true).layoutWeight(1).width('100%'); }.width('100%').height('100%').backgroundColor('#F5F7FA'); } }
