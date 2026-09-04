import { router } from '@kit.ArkUI';
import { UserProfile } from '../model/UserProfile';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct BlockedUsersPage {
  @State users: Array<UserProfile> = [];
  @State loading: boolean = true;
  @State failed: boolean = false;

  aboutToAppear(): void { this.load(); }

  async load(): Promise<void> {
    this.loading = true;
    this.failed = false;
    try { this.users = await GuozaokeService.blockedUsers(); }
    catch (_) { this.users = []; this.failed = true; }
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#258DF5').width(44).textAlign(TextAlign.Center).onClick(() => router.back())
        Text('已屏蔽用户').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 8 })
      }.width('100%').height(60).flexShrink(0).padding({ left: 8 }).backgroundColor(Color.White)
      if (this.loading) {
        LoadingProgress().margin({ top: 70 })
      } else if (this.failed) {
        Text('加载失败，点击重试').fontSize(15).fontColor('#7B8794').margin({ top: 70 }).onClick(() => this.load())
      } else if (this.users.length === 0) {
        Text('暂无已屏蔽用户').fontSize(15).fontColor('#999999').margin({ top: 70 })
      }
      List({ space: 1 }) {
        ForEach(this.users, (user: UserProfile) => {
          ListItem() {
            Row() {
              Stack() {
                Image($r('app.media.avatar_placeholder')).width(40).height(40).borderRadius(20).objectFit(ImageFit.Cover)
                if (user.avatar.length > 0) { Image(user.avatar).width(40).height(40).borderRadius(20).objectFit(ImageFit.Cover) }
              }
              Text(user.username).fontSize(16).fontColor('#3C4043').margin({ left: 14 }).layoutWeight(1)
              Text('›').fontSize(24).fontColor('#A0A5AB')
            }.width('100%').height(64).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
              .onClick(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: user.username } }))
          }
        }, (user: UserProfile) => user.username)
      }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
