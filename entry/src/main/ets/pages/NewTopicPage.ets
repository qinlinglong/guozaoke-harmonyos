import { router } from '@kit.ArkUI';

@Entry
@Component
struct NewTopicPage {
  @State title: string = '';
  @State content: string = '';
  @State submitted: boolean = false;
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('发表主题').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); Blank(); Text('发布').fontSize(16).fontColor('#258DF5').onClick(() => { this.submitted = true; }); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      TextInput({ placeholder: '请输入标题', text: this.title }).onChange((v: string) => this.title = v).fontSize(20).fontWeight(FontWeight.Bold)
        .width('92%').height(52).margin({ top: 16 })
      TextInput({ placeholder: '请输入内容', text: this.content }).onChange((v: string) => this.content = v)
        .width('92%').layoutWeight(1).margin({ top: 16 }).fontSize(16)
      if (this.submitted) { Text(this.title.trim().length > 0 && this.content.trim().length > 0 ? '已提交，正在处理…' : '请填写标题和内容').fontSize(13).fontColor('#999999').margin({ bottom: 12 }); }
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
