import { router } from '@kit.ArkUI';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct HotTopicsPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State topics: Array<Topic> = [];
  @State loading: boolean = true;
  @State message: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    this.message = '';
    try {
      this.topics = await GuozaokeService.hotTopics();
      if (this.topics.length === 0) this.message = '今日暂时没有热议内容';
    } catch (_) {
      this.topics = [];
      this.message = '加载失败，点击重试';
    }
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor(this.themeColor).width(44).textAlign(TextAlign.Center)
          .onClick(() => setTimeout(() => router.back(), 80))
        Image($r('app.media.ic_hot')).width(22).height(22).margin({ left: 8, right: 10 })
        Text('今日热议').fontSize(20).fontColor('#30343B').fontWeight(FontWeight.Bold)
        Blank()
        Text('刷新').fontSize(13).fontColor(this.themeColor).padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .onClick(() => this.load())
      }.width('100%').height(60).flexShrink(0).padding({ left: 8, right: 12 }).backgroundColor(Color.White)

      if (this.loading) {
        Column() {
          LoadingProgress().width(26).height(26).color(this.themeColor)
          Text('正在加载今日热议…').fontSize(13).fontColor('#7B8794').margin({ top: 12 })
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (this.topics.length === 0) {
        Text(this.message).fontSize(15).fontColor('#7B8794').margin({ top: 72 })
          .onClick(() => this.load())
      } else {
        List({ space: 1 }) {
          ForEach(this.topics, (topic: Topic, index: number) => {
            ListItem() {
              Row() {
                Text(`${index + 1}`).fontSize(13).fontColor(this.themeColor).width(28).textAlign(TextAlign.Center)
                Column() {
                  Text(topic.title).fontSize(16).fontColor('#30343B').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text('今日热议').fontSize(11).fontColor('#9AA0A6').margin({ top: 5 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
                Text('›').fontSize(24).fontColor('#B1B7BD').margin({ left: 8 })
              }.width('100%').padding({ left: 14, right: 14, top: 14, bottom: 14 }).backgroundColor(Color.White)
                .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: topic.id, title: topic.title } }), 80))
            }
          }, (topic: Topic) => topic.id)
        }.layoutWeight(1).width('100%')
      }
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
