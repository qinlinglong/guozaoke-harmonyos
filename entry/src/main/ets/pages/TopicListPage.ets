import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
@Entry @Component
struct TopicListPage { controller: webview.WebviewController = new webview.WebviewController(); build() { Column() { Row() { Text('‹').fontSize(32).fontColor('#1677C8').onClick(() => router.back()); Text('主题列表').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); }.width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White); Web({ src: 'https://www.guozaoke.com/', controller: this.controller }).javaScriptAccess(true).domStorageAccess(true).layoutWeight(1).width('100%'); }.width('100%').height('100%').backgroundColor('#F5F7FA'); } }
