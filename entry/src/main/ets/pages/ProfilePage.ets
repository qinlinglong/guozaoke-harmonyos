import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct ProfilePage {
  @State avatar: string = '';

  aboutToAppear(): void {
    GuozaokeService.selfAvatar().then((value: string) => this.avatar = value);
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back())
        Text('个人中心').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 })
      }.width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      Scroll() {
        Column() {
          Stack() {
            Image($r('app.media.background')).width('100%').height(160).objectFit(ImageFit.Cover)
            Image(this.avatar.length > 0 ? this.avatar : $r('app.media.default_avatar')).width(72).height(72).borderRadius(36).objectFit(ImageFit.Cover).position({ x: 16, y: 124 })
          }.width('100%').height(160)
          Column() {
            Text('过早客用户').fontSize(22).fontColor('#444444')
            Text('已登录 · guozaoke.com').fontSize(12).fontColor('#999999').margin({ top: 4 })
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 16, top: 48, bottom: 16 })
          this.menuItem('我的收藏', 'favorites')
          this.menuItem('我的主题', 'topics')
          this.menuItem('我的回复', 'replies')
        }.width('100%').backgroundColor('#F5F5F5')
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
      .onClick(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind } }))
  }
}
