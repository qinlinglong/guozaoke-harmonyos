import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct NewTopicPage {
  @State title: string = '';
  @State content: string = '';
  @State submitted: boolean = false;
  @State status: string = '';
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('发表主题').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); Blank(); Text('发布').fontSize(16).fontColor('#258DF5').onClick(async () => { if (this.title.trim().length === 0 || this.content.trim().length === 0) { this.status = '请填写标题和内容'; return; } this.status = '发布中…'; try { this.status = await GuozaokeService.newTopic(this.title.trim(), this.content.trim()) ? '发布成功' : '发布失败'; } catch (_) { this.status = '发布失败'; } }); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      TextInput({ placeholder: '请输入标题', text: this.title }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.title = v).fontSize(20).fontWeight(FontWeight.Bold)
        .width('92%').height(52).margin({ top: 16 })
      TextInput({ placeholder: '请输入内容', text: this.content }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.content = v)
        .width('92%').layoutWeight(1).margin({ top: 16 }).fontSize(16)
      if (this.status.length > 0) { Text(this.status).fontSize(13).fontColor('#999999').margin({ bottom: 12 }); }
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
