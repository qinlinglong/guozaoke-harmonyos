import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { NotificationItem } from '../model/NotificationItem';
import { NotificationListResult } from '../model/NotificationListResult';

@Entry
@Component
struct NotificationsPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State items: Array<NotificationItem> = [];
  @State loading: boolean = true;
  @State loadingMore: boolean = false;
  @State currentPage: number = 1;
  @State hasMore: boolean = false;
  @State message: string = '';
  aboutToAppear(): void { this.load(false); }
  async load(loadMore: boolean = false): Promise<void> {
    if (loadMore && (this.loadingMore || !this.hasMore)) return;
    const requestedPage: number = loadMore ? this.currentPage + 1 : 1;
    if (loadMore) this.loadingMore = true;
    else this.loading = true;
    this.message = '';
    try {
      const result: NotificationListResult = await GuozaokeService.notificationPage(requestedPage);
      if (loadMore) this.items = this.items.concat(result.items);
      else this.items = result.items;
      this.currentPage = requestedPage;
      this.hasMore = result.hasMore && result.items.length > 0;
    } catch (_) {
      if (!loadMore) this.items = [];
      this.message = loadMore ? '下一页加载失败，点击重试' : '通知加载失败，点击重试';
    }
    this.loading = false;
    this.loadingMore = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => setTimeout(() => router.back(), 80)); Text('通知').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      if (this.loading) { LoadingProgress().color(this.themeColor).margin({ top: 70 }); }
      else if (this.items.length === 0) {
        Text(this.message.length > 0 ? this.message : '暂无通知').fontSize(16).fontColor('#999999').margin({ top: 80 })
          .onClick(() => { if (this.message.length > 0) this.load(false); })
      }
      List({ space: 1 }) { ForEach(this.items, (item: NotificationItem, index: number) => { ListItem() {
        Row() {
          Stack() { Image($r('app.media.avatar_placeholder')).width(38).height(38).borderRadius(19).objectFit(ImageFit.Cover); if (item.avatar.length > 0) { Image(item.avatar).width(38).height(38).borderRadius(19).objectFit(ImageFit.Cover) } }
            .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } }), 80))
          Column() {
            Row() { Text(item.author).fontSize(14).fontColor(this.themeColor); Text(item.type).fontSize(12).fontColor('#8A9199').margin({ left: 8 }); }.width('100%')
            .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } }), 80))
            Text(item.topicTitle).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#30343B').maxLines(2).width('100%').margin({ top: 8 })
              .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: item.topicId, title: item.topicTitle } }), 80))
            if (item.content.length > 0) { Text(item.content).fontSize(13).fontColor('#6B7280').maxLines(3).width('100%').margin({ top: 6 }); }
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
        }.width('100%').padding(16).backgroundColor(Color.White)
      } }, (_: NotificationItem, index: number) => `${index}`)
        if (this.loadingMore || this.hasMore || (this.message.length > 0 && this.items.length > 0)) {
          ListItem() { Row() {
            if (this.loadingMore) { LoadingProgress().width(18).height(18).color(this.themeColor) }
            Text(this.loadingMore ? '正在加载下一页…' : this.message.length > 0 ? this.message : '继续上滑加载更多')
              .fontSize(12).fontColor('#7B8794').margin({ left: this.loadingMore ? 8 : 0 })
          }.width('100%').height(48).justifyContent(FlexAlign.Center)
            .onClick(() => { if (this.message.length > 0) this.load(true); }) }
        }
      }.layoutWeight(1).width('100%').onReachEnd(() => this.load(true))
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
