import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { UserProfile } from '../model/UserProfile';

@Entry
@Component
struct ProfilePage {
  @State avatar: string = '';
  @State username: string = '';
  @State number: string = '';
  @State since: string = '';
  @State self: boolean = true;

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.username = params && params.username ? params.username : '';
    } catch (_) {}
    this.load();
  }

  async load(): Promise<void> {
    const selfName = await GuozaokeService.selfUsername();
    if (this.username.length === 0) this.username = selfName;
    this.self = this.username === selfName;
    try {
      const profile: UserProfile = await GuozaokeService.userProfile(this.username);
      this.avatar = profile.avatar;
      this.username = profile.username;
      this.number = profile.number;
      this.since = profile.since;
    } catch (_) {
      if (this.self) this.avatar = await GuozaokeService.selfAvatar();
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back())
        Text('个人中心').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 })
        Blank()
        if (this.self) {
          Image($r('app.media.ic_settings_menu')).width(22).height(22).margin({ right: 18 })
            .onClick(() => router.pushUrl({ url: 'pages/SettingsPage' }))
        }
      }.width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      Scroll() {
        Column() {
          Stack() {
            Image($r('app.media.background')).width('100%').height(128).objectFit(ImageFit.Cover)
            Stack() {
              Image($r('app.media.avatar_placeholder')).width(72).height(72).borderRadius(36).objectFit(ImageFit.Cover)
              if (this.avatar.length > 0) { Image(this.avatar).width(72).height(72).borderRadius(36).objectFit(ImageFit.Cover) }
            }.position({ x: 16, y: 92 })
          }.width('100%').height(164)
          Column() {
            Text(this.username.length > 0 ? this.username : '过早客用户').fontSize(22).fontColor('#444444')
            Text(this.number.length > 0 ? `${this.number}${this.since.length > 0 ? ` · ${this.since}` : ''}` : (this.self ? '已登录 · guozaoke.com' : 'guozaoke.com'))
              .fontSize(12).fontColor('#999999').margin({ top: 4 })
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 16, top: 10, bottom: 16 })
          this.menuItem(this.self ? '我的收藏' : '收藏', 'favorites')
          this.menuItem(this.self ? '我的主题' : '主题', 'topics')
          this.menuItem(this.self ? '我的回复' : '回复', 'replies')
          if (this.self) {
            Row() { Text('退出登录').fontSize(16).fontColor('#D93025'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }
              .width('100%').height(56).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
              .onClick(() => AlertDialog.show({
                title: '退出登录',
                message: '确定要退出当前账号吗？',
                primaryButton: { value: '取消', action: () => {} },
                secondaryButton: { value: '退出', fontColor: '#D93025', action: () => {
                  GuozaokeService.clearCookies();
                  router.replaceUrl({ url: 'pages/Index' });
                } }
              }))
          }
        }.width('100%').constraintSize({ minHeight: '100%' }).justifyContent(FlexAlign.Start).backgroundColor('#F5F5F5')
      }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  menuItem(label: string, kind: string) {
    Row() {
      Text(label).fontSize(16).fontColor('#444444')
      Blank()
      Text('›').fontSize(24).fontColor('#BBBBBB')
    }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E6E6E6' })
      .onClick(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind, username: this.username } }))
  }
}
