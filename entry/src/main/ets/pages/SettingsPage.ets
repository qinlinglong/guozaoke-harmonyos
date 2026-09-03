import { router } from '@kit.ArkUI';

@Entry @Component
struct SettingsPage {
  @State desc: boolean = false;
  build() { Column({ space: 14 }) { Row() { Text('‹ 返回').onClick(() => router.back()); Text('设置').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 }); }.width('100%').height(56).padding({ left: 16 }); Row() { Text('评论按倒序显示').layoutWeight(1); Toggle({ type: ToggleType.Switch, isOn: this.desc }).onChange((v: boolean) => this.desc = v); }.width('90%').padding(16).backgroundColor(Color.White); Text('关于过早客').width('90%').padding(16).backgroundColor(Color.White); Text('建议与反馈').width('90%').padding(16).backgroundColor(Color.White); }.width('100%').height('100%').backgroundColor('#F5F5F5'); }
}
