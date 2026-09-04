import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { CommentItem } from '../model/CommentItem';

function htmlText(value: string): string {
  return value.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<br\s*\/?\s*>/gi, '\n').replace(/<\/(p|div|li|h[1-6]|blockquote|section)>/gi, '\n')
    .replace(/<li[^>]*>/gi, '• ').replace(/<img[^>]*>/gi, '[图片] ')
    .replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&#39;/g, "'").replace(/&quot;/g, '"')
    .replace(/[ \t]+/g, ' ').replace(/\n[ \t]+/g, '\n').replace(/\n{3,}/g, '\n\n')
    .replace(/(^|\n)(加入收藏|新浪微博|分享到微信|❤️?赞|\d+ 次点击|\d+ 人赞|\d+ 人收藏)(?=\n|$)/g, '$1').trim();
}

@Entry
@Component
struct TopicPage {
  @State title: string = '主题详情';
  @State topicId: string = '';
  @State body: string = '加载中…';
  @State comment: string = '';
  @State comments: Array<CommentItem> = [];
  @State shared: boolean = false;
  @State status: string = '';
  @State replyTarget: string = '';
  @State favorite: boolean = false;

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
        GuozaokeService.topicComments(this.topicId),
        GuozaokeService.topicFavoriteState(this.topicId)
      ]);
      this.body = htmlText(detail[0]);
      this.comments = detail[1];
      this.favorite = detail[2];
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
            Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#202124').lineHeight(26).width('100%')
            Row() {
              Text('过早客 · 主题').fontSize(13).fontColor('#8A9199').layoutWeight(1)
              Text(this.favorite ? '已收藏' : '收藏').fontSize(13).fontColor(this.favorite ? '#F59E0B' : '#258DF5')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 }).backgroundColor(this.favorite ? '#FFF7E6' : '#EEF6FF')
                .borderRadius(14).onClick(async () => {
                  this.status = '处理中…';
                  const ok = this.favorite ? await GuozaokeService.unfavorite(this.topicId) : await GuozaokeService.favorite(this.topicId);
                  if (ok) { this.favorite = !this.favorite; this.status = this.favorite ? '已加入收藏' : '已取消收藏'; }
                  else this.status = '操作失败，请先登录';
                })
            }.width('100%').margin({ top: 8, bottom: 16 })
            Text(this.body).fontSize(14).fontColor('#3C4043').lineHeight(22).width('100%')
          }.width('100%').padding(18).backgroundColor(Color.White).borderRadius(10)
          Row() {
            Text(`评论 ${this.comments.length}`).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#30343B')
            Blank()
            Text('按时间排序').fontSize(12).fontColor('#9AA0A6')
          }.width('100%').padding({ top: 20, bottom: 10, left: 4, right: 4 })
          ForEach(this.comments, (item: CommentItem, index: number) => {
            Row() {
              Image(item.avatar.length > 0 ? item.avatar : $r('app.media.avatar_placeholder')).width(34).height(34).borderRadius(17).objectFit(ImageFit.Cover)
              Column() {
                Row() {
                  Text(item.author.length > 0 ? item.author : `用户 ${index + 1}`).fontSize(13).fontColor('#3B82F6').fontWeight(FontWeight.Medium)
                  Text(item.time).fontSize(11).fontColor('#A0A5AB').margin({ left: 8 })
                  Blank()
                  Text(item.floor.startsWith('#') ? item.floor : `#${item.floor}`).fontSize(12).fontColor('#A0A5AB')
                }.width('100%')
                Text(htmlText(item.content)).fontSize(14).fontColor('#3C4043').lineHeight(21).width('100%').margin({ top: 6 })
                Row() {
                  Blank()
                  Text('回复').fontSize(12).fontColor('#258DF5').padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.replyTarget = item.author.length > 0 ? item.author : `用户 ${index + 1}`;
                      this.comment = `@${this.replyTarget} `;
                    })
                  Text(item.voted ? '已赞' : '赞').fontSize(12).fontColor(item.voted ? '#F59E0B' : '#7B8794')
                    .padding({ left: 10, right: 6, top: 4, bottom: 4 }).onClick(async () => {
                      if (item.voted || item.voteUrl.length === 0) return;
                      const voted = await GuozaokeService.vote(item.voteUrl);
                      if (voted) { item.voted = true; item.voteCount += 1; this.comments = this.comments.slice(); }
                      this.status = voted ? '点赞成功' : '点赞失败';
                    })
                  Text(`${item.voteCount}`).fontSize(11).fontColor('#A0A5AB').margin({ right: 2 })
                }.width('100%').margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
            }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(8).margin({ bottom: 8 })
          }, (item: CommentItem, index: number) => `${item.id}-${index}`)
        }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 12, right: 12, top: 12, bottom: 16 })
      }.layoutWeight(1).width('100%')
      Row() {
        TextInput({ placeholder: this.replyTarget.length > 0 ? `回复 ${this.replyTarget}…` : '参与讨论…', text: this.comment }).onChange((v: string) => this.comment = v).layoutWeight(1).height(44)
        Button('发送').height(40).margin({ left: 8 }).backgroundColor('#258DF5').onClick(async () => {
          const value = this.comment.trim(); if (value.length === 0 || this.topicId.length === 0) return;
          this.status = '发送中…';
          const content = this.replyTarget.length > 0 && value.indexOf(`@${this.replyTarget}`) !== 0 ? `@${this.replyTarget} ${value}` : value;
          try {
            if (await GuozaokeService.comment(this.topicId, content)) {
              const mine: CommentItem = new CommentItem(); mine.author = '我'; mine.floor = '#新'; mine.content = content;
              this.comments = this.comments.concat([mine]); this.comment = ''; this.replyTarget = ''; this.status = '评论成功';
            } else this.status = '评论失败';
          }
          catch (_) { this.status = '评论失败'; }
        })
      }.width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor(Color.White).border({ width: { top: 1 }, color: '#E6E8EB' })
      if (this.status.length > 0) { Text(this.status).fontSize(13).fontColor('#258DF5').margin({ bottom: 6 }); }
      if (this.shared) { Text('分享链接已复制').fontSize(13).fontColor('#258DF5').position({ x: 16, y: '80%' }); }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
