import { router } from '@kit.ArkUI';
import { Topic } from '../model/Topic';
import { TopicListResult } from '../model/TopicListResult';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct TopicListPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State kind: string = 'favorites';
  @State code: string = '';
  @State username: string = '';
  @State pageTitle: string = '';
  @State topics: Array<Topic> = [];
  @State loading: boolean = true;
  @State loadingMore: boolean = false;
  @State currentPage: number = 1;
  @State hasMore: boolean = false;
  @State message: string = '';
  aboutToAppear(): void {
    try {
      const p = router.getParams() as Record<string, string>;
      this.kind = p && p.kind ? p.kind : 'favorites';
      this.code = p && p.code ? p.code : '';
      this.username = p && p.username ? p.username : '';
      this.pageTitle = p && p.title ? p.title : '';
    } catch (_) {}
    this.load(false);
  }
  async load(loadMore: boolean = false): Promise<void> {
    if (loadMore && (this.loadingMore || !this.hasMore)) return;
    const requestedPage: number = loadMore ? this.currentPage + 1 : 1;
    if (loadMore) this.loadingMore = true;
    else this.loading = true;
    this.message = '';
    try {
      let result: TopicListResult;
      if (this.kind === 'node') result = await GuozaokeService.nodeTopicPage(this.code, requestedPage);
      else if (this.username.length > 0) result = await GuozaokeService.userTopicPageFor(this.username, this.kind, requestedPage);
      else result = await GuozaokeService.userTopicPage(this.kind, requestedPage);
      if (loadMore) {
        const knownIds: Set<string> = new Set(this.topics.map((topic: Topic) => topic.id));
        this.topics = this.topics.concat(result.topics.filter((topic: Topic) => !knownIds.has(topic.id)));
      } else {
        this.topics = result.topics;
      }
      this.currentPage = requestedPage;
      this.hasMore = result.hasMore && result.topics.length > 0;
    } catch (_) {
      if (!loadMore) this.topics = [];
      this.message = loadMore ? '下一页加载失败，上滑重试' : '加载失败，点击重试';
    }
    this.loading = false;
    this.loadingMore = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => setTimeout(() => router.back(), 80)); Text(this.pageTitle.length > 0 ? this.pageTitle : this.kind === 'favorites' ? '我的收藏' : this.kind === 'topics' ? '我的主题' : '我的回复').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      if (this.loading) { LoadingProgress().color(this.themeColor).margin({ top: 60 }); }
      else if (this.topics.length === 0) {
        Text(this.message.length > 0 ? this.message : '暂无内容').fontSize(16).fontColor('#999999').margin({ top: 70 })
          .onClick(() => { if (this.message.length > 0) this.load(false); })
      }
      List({ space: 1 }) { ForEach(this.topics, (topic: Topic) => { ListItem() { Row() {
        Stack() { Image($r('app.media.avatar_placeholder')).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover); if (topic.avatar.length > 0) { Image(topic.avatar).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover) } }
        Text(topic.title).fontSize(16).fontColor('#444444').margin({ left: 12 }).layoutWeight(1); Text(topic.replies + ' 回复').fontSize(12).fontColor('#999999');
      }.width('100%').padding(16).backgroundColor(Color.White).onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: topic.id, title: topic.title } }), 80)); } }, (topic: Topic) => topic.id)
        if (this.loadingMore || this.hasMore || this.message.length > 0) {
          ListItem() { Row() {
            if (this.loadingMore) { LoadingProgress().width(18).height(18).color(this.themeColor) }
            Text(this.loadingMore ? '正在加载下一页…' : this.message.length > 0 ? this.message : '继续上滑加载更多')
              .fontSize(12).fontColor('#7B8794').margin({ left: this.loadingMore ? 8 : 0 })
          }.width('100%').height(48).justifyContent(FlexAlign.Center).onClick(() => { if (this.message.length > 0) this.load(true); }) }
        }
      }.layoutWeight(1).width('100%').onReachEnd(() => this.load(true))
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
