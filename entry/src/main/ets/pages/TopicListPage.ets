import { router } from '@kit.ArkUI';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry @Component
struct TopicListPage {
  @State topics: Array<Topic> = []; @State message: string = '加载中…';
  aboutToAppear(): void { this.load(); }
  async load(): Promise<void> { try { this.topics = await GuozaokeService.topics(); this.message = this.topics.length ? '' : '暂无内容'; } catch (_) { this.message = '加载失败'; } }
  build() { Column() { Row() { Text('‹ 返回').onClick(() => router.back()); Text('主题列表').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 }); }.width('100%').height(56).padding({ left: 16 }); if (this.message.length > 0) Text(this.message).margin({ top: 48 }); else List() { ForEach(this.topics, (topic: Topic) => ListItem() { Text(topic.title).padding(16).width('100%').backgroundColor(Color.White).onClick(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: topic.id, title: topic.title } })); }, (topic: Topic) => topic.id); }.layoutWeight(1).width('100%'); }.width('100%').height('100%').backgroundColor('#F5F5F5'); }
}
