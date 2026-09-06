import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct BilibiliLoginPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State status: string = '请在页面内登录 Bilibili';
  @State completed: boolean = false;
  private controller: webview.WebviewController = new webview.WebviewController();
  private timer: number = -1;

  aboutToAppear(): void { this.timer = setInterval(() => this.checkCookie(), 700); }
  aboutToDisappear(): void { if (this.timer >= 0) clearInterval(this.timer); }
  async checkCookie(): Promise<void> {
    if (this.completed || !GuozaokeService.biliLoggedIn()) return;
    this.completed = true;
    this.status = 'Bilibili 登录成功';
    if (this.timer >= 0) { clearInterval(this.timer); this.timer = -1; }
    try { await webview.WebCookieManager.saveCookieAsync(); } catch (_) {}
    setTimeout(() => router.back(), 500);
  }
  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => router.back());
        Text('Bilibili 图床登录').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 });
      }.width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      Text(this.status).fontSize(13).fontColor(this.themeColor).margin({ top: 8, bottom: 8 });
      // Use the lightweight official passport page instead of the full home
      // feed; the latter loads a large amount of media and can terminate an
      // ArkWeb surface on low-memory devices.
      Web({ src: 'https://passport.bilibili.com/login', controller: this.controller })
        .javaScriptAccess(true).domStorageAccess(true).layoutWeight(1).width('100%')
        .onPageEnd(() => this.checkCookie())
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
  }
}
