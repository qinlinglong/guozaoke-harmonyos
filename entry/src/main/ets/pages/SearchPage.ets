import { router } from '@kit.ArkUI';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry @Component
struct SearchPage {
  @State query: string = ''; @State results: Array<Topic> = []; @State message: string = '';
  async search(): Promise<void> { if (!this.query.trim()) return; this.message = '搜索中…'; try { this.results = await GuozaokeService.search(this.query.trim()); this.message = this.results.length ? '' : '没有结果'; } catch (_) { this.message = '搜索失败'; } }
  build() {
    Column() {
      Row() { Text('‹ 返回').onClick(() => router.back()); Text('搜索').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 }); }.width('100%').height(56).padding({ left: 16 });
      Row() { TextInput({ placeholder: '搜索主题或用户', text: this.query }).layoutWeight(1).onChange((v: string) => this.query = v); Button('搜索').onClick(() => this.search()); }.width('94%');
      if (this.message.length > 0) Text(this.message).margin({ top: 30 });
      List() { ForEach(this.results, (topic: Topic) => ListItem() { Text(topic.title).padding(16).width('100%').onClick(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: topic.id, title: topic.title } })); }, (topic: Topic) => topic.id); }.layoutWeight(1).width('100%');
    }.width('100%').height('100%');
  }
}
