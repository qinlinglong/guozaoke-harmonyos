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
        Text('‹').fontSize(30).fontColor('#258DF5').width(44).textAlign(TextAlign.Center).onClick(() => router.back())
        Text('主题详情').fontSize(18).fontColor('#333333').fontWeight(FontWeight.Medium).margin({ left: 8 })
        Blank()
        Text('分享').fontSize(15).fontColor('#258DF5').padding({ left: 12, right: 12, top: 8, bottom: 8 }).onClick(() => this.shared = true)
      }.width('100%').height(56).padding({ left: 8, right: 12 }).backgroundColor(Color.White)
      Scroll() {
        Column() {
          Column() {
            Text(this.title).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#202124').lineHeight(28).width('100%')
            Text('过早客 · 主题').fontSize(13).fontColor('#8A9199').margin({ top: 8, bottom: 16 }).width('100%')
            Text(this.body).fontSize(15).fontColor('#3C4043').lineHeight(24).width('100%')
          }.width('100%').padding(18).backgroundColor(Color.White).borderRadius(10)
          Row() {
            Text(`评论 ${this.comments.length}`).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#30343B')
            Blank()
            Text('按时间排序').fontSize(12).fontColor('#9AA0A6')
          }.width('100%').padding({ top: 20, bottom: 10, left: 4, right: 4 })
          ForEach(this.comments, (item: string, index: number) => {
            Row() {
              Image($r('app.media.default_avatar')).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover)
              Column() {
                Row() { Text(`用户 ${index + 1}`).fontSize(13).fontColor('#5F6368'); Blank(); Text(`#${index + 1}`).fontSize(12).fontColor('#A0A5AB'); }.width('100%')
                Text(item).fontSize(15).fontColor('#3C4043').lineHeight(22).width('100%').margin({ top: 6 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
            }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(8).margin({ bottom: 8 })
          }, (_: string, index: number) => `${index}`)
        }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 12, right: 12, top: 12, bottom: 16 })
      }.layoutWeight(1).width('100%')
      Row() {
        TextInput({ placeholder: '参与讨论…', text: this.comment }).onChange((v: string) => this.comment = v).layoutWeight(1).height(44)
        Button('发送').height(40).margin({ left: 8 }).backgroundColor('#258DF5').onClick(async () => {
          const value = this.comment.trim(); if (value.length === 0 || this.topicId.length === 0) return;
          this.status = '发送中…';
          try { if (await GuozaokeService.comment(this.topicId, value)) { this.comments.push(value); this.comment = ''; this.status = '评论成功'; } else this.status = '评论失败'; }
          catch (_) { this.status = '评论失败'; }
        })
      }.width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor(Color.White).border({ width: { top: 1 }, color: '#E6E8EB' })
      if (this.status.length > 0) { Text(this.status).fontSize(13).fontColor('#258DF5').margin({ bottom: 6 }); }
      if (this.shared) { Text('分享链接已复制').fontSize(13).fontColor('#258DF5').position({ x: 16, y: '80%' }); }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
