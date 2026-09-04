import { router } from '@kit.ArkUI';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct SearchPage {
  @State query: string = '';
  @State topics: Array<Topic> = [];
  @State loading: boolean = false;
  async search(): Promise<void> {
    if (this.query.trim().length === 0) return;
    this.loading = true;
    try { this.topics = await GuozaokeService.search(this.query.trim()); } catch (_) { this.topics = []; }
    this.loading = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('搜索').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      TextInput({ placeholder: '请输入关键词', text: this.query }).onChange((v: string) => this.query = v)
        .width('92%').height(48).margin({ top: 16 })
      Button('搜索').width('92%').height(44).margin({ top: 12 }).backgroundColor('#258DF5').onClick(() => this.search())
      if (this.loading) { LoadingProgress().margin({ top: 40 }); }
      List({ space: 1 }) { ForEach(this.topics, (topic: Topic) => { ListItem() { Row() { Image(topic.avatar || $r('app.media.default_avatar')).width(32).height(32).borderRadius(16); Text(topic.title).fontSize(16).fontColor('#444444').margin({ left: 12 }).layoutWeight(1); Text(topic.replies + ' 回复').fontSize(12).fontColor('#999999'); }.width('100%').padding(16).backgroundColor(Color.White).onClick(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: topic.id, title: topic.title } })); } }, (topic: Topic) => topic.id) }.layoutWeight(1).width('100%').margin({ top: 16 })
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
