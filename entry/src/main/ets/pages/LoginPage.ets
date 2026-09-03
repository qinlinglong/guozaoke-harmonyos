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
        Text('‹ 返回').onClick(() => router.back())
        Text('登录').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 })
      }.width('100%').height(52).padding({ left: 16 })
      Web({ src: LOGIN_URL, controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onPageEnd(() => this.checkLogin())
        .layoutWeight(1).width('100%')
    }.width('100%').height('100%')
  }
}
