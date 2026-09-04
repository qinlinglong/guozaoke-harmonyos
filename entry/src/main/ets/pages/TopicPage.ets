import { router } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { GuozaokeService } from '../service/GuozaokeService';
import { CommentItem } from '../model/CommentItem';
import { TopicDetailData } from '../model/TopicDetailData';

function htmlText(value: string, showImagePlaceholder: boolean = true): string {
  return value.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<br\s*\/?\s*>/gi, '\n').replace(/<\/(p|div|li|h[1-6]|blockquote|section)>/gi, '\n')
    .replace(/<li[^>]*>/gi, '• ').replace(/<img[^>]*>/gi, showImagePlaceholder ? '[图片] ' : '')
    .replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&#39;|&#x27;/gi, "'").replace(/&quot;/g, '"')
    .replace(/&#(\d+);/g, (_: string, code: string) => String.fromCharCode(Number(code)))
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
  @State composerOpen: boolean = false;
  @State loading: boolean = true;
  @State author: string = '';
  @State avatar: string = '';
  @State nodeTitle: string = '';
  @State nodeCode: string = '';
  @State createdTime: string = '';
  @State sending: boolean = false;
  @State favoriteBusy: boolean = false;
  @State images: Array<string> = [];
  @State imageHeights: Array<number> = [];
  @StorageLink('commentsOrderDesc') commentsOrderDesc: boolean = false;

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.topicId = params && params.id ? params.id : '';
      this.title = params && params.title ? params.title : '主题详情';
    } catch (_) {}
    this.loadBody();
  }

  pageTransition() {
    // The device default transition briefly scales/slides the detail card from
    // the centre. A zero-duration page transition keeps the layout stationary.
    PageTransitionEnter({ type: RouteType.None, duration: 0 })
    PageTransitionExit({ type: RouteType.None, duration: 0 })
  }

  async loadBody(): Promise<void> {
    if (this.topicId.length === 0) { this.body = '主题不存在'; this.loading = false; return; }
    this.loading = true;
    this.status = '';
    try {
      const detail = await Promise.all([
        GuozaokeService.topicDetail(this.topicId),
        GuozaokeService.topicComments(this.topicId),
        GuozaokeService.topicFavoriteState(this.topicId)
      ]);
      const topic: TopicDetailData = detail[0];
      this.body = htmlText(topic.content, false);
      this.author = topic.author;
      this.avatar = topic.avatar;
      this.nodeTitle = topic.nodeTitle;
      this.nodeCode = topic.nodeCode;
      this.createdTime = topic.createdTime;
      this.images = topic.images;
      this.imageHeights = topic.images.map(() => 220);
      this.comments = this.commentsOrderDesc ? detail[1].slice().reverse() : detail[1];
      this.favorite = detail[2];
    }
    catch (_) { this.body = '加载失败，请稍后重试'; }
    this.loading = false;
  }

  private notify(message: string): void {
    this.status = message;
    setTimeout(() => {
      if (this.status === message) this.status = '';
    }, 2200);
  }

  private async toggleFavorite(): Promise<void> {
    if (this.favoriteBusy) return;
    if (!GuozaokeService.isLoggedIn()) {
      this.notify('请先登录');
      return;
    }
    this.favoriteBusy = true;
    const ok = this.favorite ? await GuozaokeService.unfavorite(this.topicId) : await GuozaokeService.favorite(this.topicId);
    if (ok) {
      this.favorite = !this.favorite;
      this.notify(this.favorite ? '已加入收藏' : '已取消收藏');
    } else {
      this.notify('操作失败，请稍后重试');
    }
    this.favoriteBusy = false;
  }

  private async sendComment(): Promise<void> {
    const value = this.comment.trim();
    if (this.sending || value.length === 0 || this.topicId.length === 0) return;
    if (!GuozaokeService.isLoggedIn()) {
      this.notify('请先登录');
      return;
    }
    this.sending = true;
    this.status = '发送中…';
    const content = this.replyTarget.length > 0 && value.indexOf(`@${this.replyTarget}`) !== 0 ? `@${this.replyTarget} ${value}` : value;
    try {
      if (await GuozaokeService.comment(this.topicId, content)) {
        this.dismissComposer(true);
        this.comments = await GuozaokeService.topicComments(this.topicId);
        if (this.commentsOrderDesc) this.comments = this.comments.slice().reverse();
        this.notify('评论成功');
      } else {
        this.notify('评论失败，请稍后重试');
      }
    } catch (_) {
      this.notify('评论失败，请稍后重试');
    }
    this.sending = false;
  }

  async copyShareLink(): Promise<void> {
    if (this.topicId.length === 0) return;
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, `https://www.guozaoke.com/t/${this.topicId}`);
      await pasteboard.getSystemPasteboard().setData(data);
      this.shared = true;
      setTimeout(() => this.shared = false, 1800);
    } catch (_) { this.status = '复制分享链接失败'; }
  }

  private openComposer(target: string = ''): void {
    this.replyTarget = target;
    if (target.length > 0) this.comment = `@${target} `;
    this.composerOpen = true;
    setTimeout(() => {
      try { this.getUIContext().getFocusController().requestFocus('commentInput'); } catch (_) {}
    }, 120);
  }

  private dismissComposer(clearDraft: boolean = false): void {
    try { this.getUIContext().getFocusController().clearFocus(); } catch (_) {}
    this.composerOpen = false;
    if (clearDraft) {
      this.replyTarget = '';
      this.comment = '';
    }
  }

  private toggleCommentOrder(): void {
    this.commentsOrderDesc = !this.commentsOrderDesc;
    this.comments = this.comments.slice().reverse();
  }

  onBackPress(): boolean {
    if (this.composerOpen) {
      this.dismissComposer();
      return true;
    }
    return false;
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(30).fontColor('#258DF5').width(44).textAlign(TextAlign.Center).onClick(() => {
          if (this.composerOpen) this.dismissComposer();
          else router.back();
        })
        Text('主题详情').fontSize(18).fontColor('#333333').fontWeight(FontWeight.Medium).margin({ left: 8 })
        Blank()
        Text('分享').fontSize(15).fontColor('#258DF5').padding({ left: 12, right: 12, top: 8, bottom: 8 }).onClick(() => this.copyShareLink())
      }.width('100%').height(56).flexShrink(0).padding({ left: 8, right: 12 }).backgroundColor(Color.White)
      Stack() {
        Scroll() {
          Column() {
          Column() {
            Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#202124').lineHeight(26).width('100%')
            Row() {
              Stack() {
                Image($r('app.media.avatar_placeholder')).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover)
                if (this.avatar.length > 0) { Image(this.avatar).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover) }
              }.onClick(() => {
                if (this.author.length > 0) router.pushUrl({ url: 'pages/ProfilePage', params: { username: this.author } });
              })
              Column() {
                Text(this.author.length > 0 ? this.author : '过早客用户').fontSize(13).fontColor('#3B82F6').fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    if (this.author.length > 0) router.pushUrl({ url: 'pages/ProfilePage', params: { username: this.author } });
                  })
                Row() {
                  if (this.createdTime.length > 0) { Text(this.createdTime).fontSize(11).fontColor('#8A9199'); }
                  if (this.nodeTitle.length > 0) {
                    Text(this.nodeTitle).fontSize(11).fontColor('#258DF5').margin({ left: this.createdTime.length > 0 ? 8 : 0 })
                      .onClick(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'node', code: this.nodeCode, title: this.nodeTitle } }));
                  }
                }.margin({ top: 3 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
            }.width('100%').margin({ top: 12, bottom: 16 }).alignItems(VerticalAlign.Center)
            if (this.loading) {
              Row() { LoadingProgress().width(22).height(22); Text('正在加载详情…').fontSize(13).fontColor('#8A9199').margin({ left: 10 }); }
                .width('100%').height(64).justifyContent(FlexAlign.Center)
            } else {
              Text(this.body).fontSize(15).fontColor('#3C4043').lineHeight(24).width('100%')
                .onClick(() => { if (this.composerOpen) this.dismissComposer(); })
              ForEach(this.images, (url: string, index: number) => {
                Image(url).width('100%').height(this.imageHeights[index]).objectFit(ImageFit.Contain)
                  .margin({ top: 12 }).borderRadius(6).backgroundColor('#F7F8FA')
                  .onComplete((event) => {
                    if (event && event.width > 0 && event.height > 0) {
                      const next = this.imageHeights.slice();
                      next[index] = Math.max(120, Math.min(420, 344 * event.height / event.width));
                      this.imageHeights = next;
                    }
                  })
              }, (url: string) => url)
            }
          }.width('100%').padding(18).backgroundColor(Color.White).borderRadius(10)
          Row() {
            Text(`评论 ${this.comments.length}`).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#30343B')
            Blank()
            Text(this.commentsOrderDesc ? '倒序排列' : '正序排列').fontSize(12).fontColor('#258DF5')
              .padding({ left: 10, right: 2, top: 6, bottom: 6 }).onClick(() => this.toggleCommentOrder())
          }.width('100%').padding({ top: 20, bottom: 10, left: 4, right: 4 })
          ForEach(this.comments, (item: CommentItem, index: number) => {
            Row() {
              Image(item.avatar.length > 0 ? item.avatar : $r('app.media.avatar_placeholder')).width(34).height(34).borderRadius(17).objectFit(ImageFit.Cover)
                .onClick(() => {
                  if (item.author.length > 0) router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } });
                })
              Column() {
                Row() {
                  Text(item.author.length > 0 ? item.author : `用户 ${index + 1}`).fontSize(13).fontColor('#3B82F6').fontWeight(FontWeight.Medium)
                    .onClick(() => {
                      if (item.author.length > 0) router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } });
                    })
                  Text(item.time).fontSize(11).fontColor('#A0A5AB').margin({ left: 8 })
                  Blank()
                  Text(item.floor.startsWith('#') ? item.floor : `#${item.floor}`).fontSize(12).fontColor('#A0A5AB')
                }.width('100%')
                Text(htmlText(item.content)).fontSize(14).fontColor('#3C4043').lineHeight(21).width('100%').margin({ top: 6 })
                Row() {
                  Blank()
                  Text('回复').fontSize(12).fontColor('#258DF5').padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.openComposer(item.author.length > 0 ? item.author : `用户 ${index + 1}`);
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
          }.width('100%').constraintSize({ minHeight: '100%' }).justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start).padding({ left: 12, right: 12, top: 12, bottom: 16 })
        }.width('100%').height('100%')
        if (this.composerOpen) {
          Column().width('100%').height('100%').backgroundColor('#01000000')
            .hitTestBehavior(HitTestMode.Block).onClick(() => this.dismissComposer())
        }
      }.layoutWeight(1).width('100%')
      if (!this.composerOpen) {
        Row() {
          Text('回复').fontSize(16).fontColor('#258DF5').padding({ left: 12, right: 12, top: 10, bottom: 10 }).onClick(() => this.openComposer())
          Blank()
          Text(this.favoriteBusy ? '处理中…' : (this.favorite ? '已收藏' : '收藏')).fontSize(14).fontColor('#7B8794').margin({ right: 18 })
            .onClick(() => this.toggleFavorite())
          Text('分享').fontSize(14).fontColor('#258DF5').margin({ right: 14 }).onClick(() => this.copyShareLink())
        }.width('100%').height(56).flexShrink(0).padding({ left: 8 }).backgroundColor(Color.White).border({ width: { top: 1 }, color: '#E6E8EB' })
      } else {
        Row() {
          Text('×').fontSize(23).fontColor('#7B8794').width(40).height(48).textAlign(TextAlign.Center)
            .onClick(() => this.dismissComposer(true))
          TextArea({ placeholder: this.replyTarget.length > 0 ? `回复 ${this.replyTarget}…` : '请输入评论内容', text: this.comment })
            .id('commentInput')
            .focusOnTouch(true)
            .fontSize(15)
            .fontColor('#30343B')
            .placeholderColor('#9AA0A6')
            .caretColor('#258DF5')
            .textAlign(TextAlign.Start)
            .lineHeight(21)
            .maxLines(3)
            .layoutWeight(1)
            .height(56)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#F5F6F8')
            .borderRadius(8)
            .onChange((v: string) => this.comment = v)
            .onKeyPreIme((event: KeyEvent) => {
              if (event.keyCode !== 2) return false;
              // Consume both phases. Removing the editor on key-down would let
              // the matching key-up reach the page and navigate away.
              if (event.type === KeyType.Up) this.dismissComposer();
              return true;
            })
          Button(this.sending ? '发送中…' : '评论').fontSize(14).height(40).width(60).margin({ left: 8, right: 8 })
            .padding(0).borderRadius(20).backgroundColor('#258DF5')
            .enabled(!this.sending && this.comment.trim().length > 0).onClick(() => this.sendComment())
        }.width('100%').height(72).flexShrink(0).alignItems(VerticalAlign.Center).backgroundColor(Color.White)
          .border({ width: { top: 1 }, color: '#E6E8EB' })
      }
      if (this.status.length > 0) { Text(this.status).fontSize(13).fontColor('#258DF5').margin({ bottom: 6 }); }
      if (this.shared) { Text('分享链接已复制').fontSize(13).fontColor('#258DF5').position({ x: 16, y: '80%' }); }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
