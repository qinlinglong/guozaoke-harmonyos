import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { NotificationItem } from '../model/NotificationItem';

@Entry
@Component
struct NotificationsPage {
  @State items: Array<NotificationItem> = [];
  @State loading: boolean = true;
  aboutToAppear(): void { this.load(); }
  async load(): Promise<void> {
    this.loading = true;
    try { this.items = await GuozaokeService.notifications(); } catch (_) { this.items = []; }
    this.loading = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('通知').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      if (this.loading) { LoadingProgress().margin({ top: 70 }); }
      else if (this.items.length === 0) { Text('暂无通知').fontSize(16).fontColor('#999999').margin({ top: 80 }); }
      List({ space: 1 }) { ForEach(this.items, (item: NotificationItem, index: number) => { ListItem() {
        Row() {
          Stack() { Image($r('app.media.avatar_placeholder')).width(38).height(38).borderRadius(19).objectFit(ImageFit.Cover); if (item.avatar.length > 0) { Image(item.avatar).width(38).height(38).borderRadius(19).objectFit(ImageFit.Cover) } }
            .onClick(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } }))
          Column() {
            Row() { Text(item.author).fontSize(14).fontColor('#258DF5'); Text(item.type).fontSize(12).fontColor('#8A9199').margin({ left: 8 }); }.width('100%')
            .onClick(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } }))
            Text(item.topicTitle).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#30343B').maxLines(2).width('100%').margin({ top: 8 })
              .onClick(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: item.topicId, title: item.topicTitle } }))
            if (item.content.length > 0) { Text(item.content).fontSize(13).fontColor('#6B7280').maxLines(3).width('100%').margin({ top: 6 }); }
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
        }.width('100%').padding(16).backgroundColor(Color.White)
      } }, (_: NotificationItem, index: number) => `${index}`) }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
