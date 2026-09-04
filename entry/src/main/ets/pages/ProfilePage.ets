import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { GuozaokeService } from '../service/GuozaokeService';
@Entry @Component
struct ProfilePage {
  controller: webview.WebviewController = new webview.WebviewController();
  @State profileUrl: string = 'https://www.guozaoke.com/';
  aboutToAppear(): void { this.loadProfileUrl(); }
  async loadProfileUrl(): Promise<void> { this.profileUrl = await GuozaokeService.selfProfileUrl(); }
  build() { Column() { Row() { Text('‹').fontSize(32).fontColor('#1677C8').onClick(() => router.back()); Text('个人中心').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); }.width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White); Web({ src: this.profileUrl, controller: this.controller }).javaScriptAccess(true).domStorageAccess(true).layoutWeight(1).width('100%'); }.width('100%').height('100%').backgroundColor('#F5F7FA'); }
}
