import { router } from '@kit.ArkUI';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct TopicListPage {
  @State kind: string = 'favorites';
  @State topics: Array<Topic> = [];
  @State loading: boolean = true;
  aboutToAppear(): void { try { const p = router.getParams() as Record<string, string>; this.kind = p && p.kind ? p.kind : 'favorites'; } catch (_) {} this.load(); }
  async load(): Promise<void> { try { this.topics = await GuozaokeService.userTopics(this.kind); } catch (_) { this.topics = []; } this.loading = false; }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text(this.kind === 'favorites' ? '我的收藏' : this.kind === 'topics' ? '我的主题' : '我的回复').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      if (this.loading) { LoadingProgress().margin({ top: 60 }); }
      else if (this.topics.length === 0) { Text('暂无内容').fontSize(16).fontColor('#999999').margin({ top: 70 }); }
      List({ space: 1 }) { ForEach(this.topics, (topic: Topic) => { ListItem() { Row() {
        Stack() { Image($r('app.media.avatar_placeholder')).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover); if (topic.avatar.length > 0) { Image(topic.avatar).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover) } }
        Text(topic.title).fontSize(16).fontColor('#444444').margin({ left: 12 }).layoutWeight(1); Text(topic.replies + ' 回复').fontSize(12).fontColor('#999999');
      }.width('100%').padding(16).backgroundColor(Color.White).onClick(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: topic.id, title: topic.title } })); } }, (topic: Topic) => topic.id) }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
