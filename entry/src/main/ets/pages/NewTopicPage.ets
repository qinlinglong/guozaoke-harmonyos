import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct NewTopicPage {
  @State title: string = '';
  @State content: string = '';
  @State submitted: boolean = false;
  @State status: string = '';
  @State nodeCode: string = '';
  @State nodeTitle: string = '';
  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.nodeCode = params && params.nodeCode ? params.nodeCode : '';
      this.nodeTitle = params && params.nodeTitle ? params.nodeTitle : '';
    } catch (_) {}
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('发表主题').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); Blank(); Text('发布').fontSize(16).fontColor('#258DF5').onClick(async () => { if (this.nodeCode.length === 0) { this.status = '请先选择节点'; return; } if (this.title.trim().length < 3 || this.content.trim().length < 3) { this.status = '标题和内容至少需要 3 个字符'; return; } this.status = '发布中…'; try { this.status = await GuozaokeService.newTopic(this.nodeCode, this.title.trim(), this.content.trim()) ? '发布成功' : '发布失败'; } catch (_) { this.status = '发布失败'; } }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      Row() { Text('发布到').fontSize(14).fontColor('#7B8794'); Text(this.nodeTitle.length > 0 ? this.nodeTitle : '未选择节点').fontSize(15).fontColor('#258DF5').margin({ left: 10 }); Blank(); Text('更换 ›').fontSize(14).fontColor('#258DF5'); }
        .width('92%').height(48).onClick(() => router.pushUrl({ url: 'pages/NodesPage', params: { select: '1' } }))
      TextInput({ placeholder: '请输入标题', text: this.title }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.title = v).fontSize(20).fontWeight(FontWeight.Bold)
        .width('92%').height(52).margin({ top: 16 })
      TextInput({ placeholder: '请输入内容', text: this.content }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.content = v)
        .width('92%').layoutWeight(1).margin({ top: 16 }).fontSize(16)
      if (this.status.length > 0) { Text(this.status).fontSize(13).fontColor('#999999').margin({ bottom: 12 }); }
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
