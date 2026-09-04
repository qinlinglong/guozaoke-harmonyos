import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

function htmlText(value: string): string {
  return value.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<br\s*\/?\s*>/gi, '\n').replace(/<\/(p|div|li|h[1-6])>/gi, '\n')
    .replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&#39;/g, "'").replace(/&quot;/g, '"').trim();
}

@Entry
@Component
struct TopicPage {
  @State title: string = '主题详情';
  @State topicId: string = '';
  @State body: string = '加载中…';
  @State comment: string = '';
  @State comments: Array<string> = [];
  @State shared: boolean = false;
  @State status: string = '';

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.topicId = params && params.id ? params.id : '';
      this.title = params && params.title ? params.title : '主题详情';
    } catch (_) {}
    this.loadBody();
  }

  async loadBody(): Promise<void> {
    if (this.topicId.length === 0) { this.body = '主题不存在'; return; }
    try {
      const detail = await Promise.all([
        GuozaokeService.topicDetail(this.topicId),
        GuozaokeService.topicComments(this.topicId)
      ]);
      this.body = htmlText(detail[0]);
      this.comments = detail[1];
    }
    catch (_) { this.body = '加载失败，请稍后重试'; }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back())
        Text('主题详情').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 })
        Blank()
        Text('分享').fontSize(15).fontColor('#258DF5').onClick(() => this.shared = true)
      }.width('100%').height(60).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      Scroll() {
        Column() {
          Text(this.title).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#333333').width('100%').margin({ bottom: 10 })
          Text('过早客 · 主题').fontSize(13).fontColor('#999999').width('100%').margin({ bottom: 18 })
          Text(this.body).fontSize(16).fontColor('#444444').lineHeight(25).width('100%')
          Divider().margin({ top: 24, bottom: 16 })
          Text('评论').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#444444').width('100%')
          ForEach(this.comments, (item: string, index: number) => { Text(item).fontSize(15).fontColor('#555555').width('100%').padding(12).margin({ top: 8 }).backgroundColor('#F5F5F5'); }, (_: string, index: number) => `${index}`)
        }.width('100%').alignItems(HorizontalAlign.Start).padding(16)
      }.layoutWeight(1).width('100%')
      Row() {
        TextInput({ placeholder: '参与讨论…', text: this.comment }).onChange((v: string) => this.comment = v).layoutWeight(1).height(44)
        Button('发送').height(40).margin({ left: 8 }).backgroundColor('#258DF5').onClick(async () => {
          const value = this.comment.trim(); if (value.length === 0 || this.topicId.length === 0) return;
          this.status = '发送中…';
          try { if (await GuozaokeService.comment(this.topicId, value)) { this.comments.push(value); this.comment = ''; this.status = '评论成功'; } else this.status = '评论失败'; }
          catch (_) { this.status = '评论失败'; }
        })
      }.width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor(Color.White)
      if (this.status.length > 0) { Text(this.status).fontSize(13).fontColor('#258DF5').margin({ bottom: 6 }); }
      if (this.shared) { Text('分享链接已复制').fontSize(13).fontColor('#258DF5').position({ x: 16, y: '80%' }); }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
