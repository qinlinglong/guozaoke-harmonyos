import { router } from '@kit.ArkUI';

@Entry
@Component
struct SettingsPage {
  @State desc: boolean = false;
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('设置').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      Row() { Text('评论按时间倒序').fontSize(16).fontColor('#444444'); Blank(); Toggle({ type: ToggleType.Switch, isOn: this.desc }).onChange((v: boolean) => this.desc = v); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
      Row() { Text('图床 API Key').fontSize(16).fontColor('#444444'); Blank(); Text('未设置').fontSize(14).fontColor('#999999'); Text('›').fontSize(24).fontColor('#BBBBBB').margin({ left: 8 }); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
      Text('用于上传主题图片的图床配置').fontSize(12).fontColor('#999999').margin({ top: 10, left: 16, right: 16 })
      Blank()
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
