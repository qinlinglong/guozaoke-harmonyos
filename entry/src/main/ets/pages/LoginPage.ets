import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { LOGIN_URL, GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct LoginPage {
  controller: webview.WebviewController = new webview.WebviewController();
  @State completed: boolean = false;
  private timer: number = -1;

  aboutToAppear(): void {
    this.timer = setInterval(() => this.checkLogin(), 500);
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) {
      clearInterval(this.timer);
    }
  }

  checkLogin(): void {
    if (!this.completed && GuozaokeService.isLoggedIn()) {
      this.completed = true;
      router.back();
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#1677C8').onClick(() => router.back())
        Text('登录过早客').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 })
      }.width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      Text('登录后即可查看个人资料、收藏和参与讨论').fontSize(13).fontColor('#7B8794').margin({ top: 12, bottom: 8 })
      Web({ src: LOGIN_URL, controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onPageEnd(() => this.checkLogin())
        .layoutWeight(1).width('100%')
    }.width('100%').height('100%')
  }
}
