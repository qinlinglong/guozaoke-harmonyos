import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

interface TopicParams {
  id: string;
  title: string;
}

@Entry
@Component
struct TopicPage {
  @State title: string = '主题详情';
  @State content: string = '加载中…';

  aboutToAppear(): void {
    const params: TopicParams = router.getParams() as TopicParams;
    this.title = params.title;
    this.load(params.id);
  }

  async load(id: string): Promise<void> {
    try {
      this.content = await GuozaokeService.topicDetail(id);
    } catch (_) {
      this.content = '加载失败，请返回重试';
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹ 返回').onClick(() => router.back())
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).maxLines(1)
          .layoutWeight(1).margin({ left: 20 })
      }.width('100%').height(56).padding({ left: 16, right: 16 })
      Scroll() {
        Text(this.content).fontSize(16).lineHeight(26).padding(20).width('100%')
      }.layoutWeight(1).width('100%')
    }.width('100%').height('100%')
  }
}
