import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry @Component
struct ProfilePage {
  @State loggedIn: boolean = false;
  aboutToAppear(): void { this.loggedIn = GuozaokeService.isLoggedIn(); }
  build() {
    Column({ space: 18 }) {
      Row() { Text('‹ 返回').onClick(() => router.back()); Text('个人中心').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 }); }
        .width('100%').height(56).padding({ left: 16 });
      if (!this.loggedIn) {
        Text('登录状态已失效').margin({ top: 48 });
        Button('登录').onClick(() => router.pushUrl({ url: 'pages/LoginPage' }));
      } else {
        Text('已登录').fontSize(22).fontWeight(FontWeight.Bold);
        Text('我的主题').width('90%').padding(16).backgroundColor(Color.White)
          .onClick(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'topics' } }));
        Text('我的收藏').width('90%').padding(16).backgroundColor(Color.White)
          .onClick(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'favorites' } }));
        Text('我的回复').width('90%').padding(16).backgroundColor(Color.White)
          .onClick(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'replies' } }));
        Button('退出登录').onClick(() => { GuozaokeService.clearCookies(); this.loggedIn = false; });
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5');
  }
}
