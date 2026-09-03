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
  @State loading: boolean = true;

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
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#1677C8').onClick(() => router.back())
        Text('主题详情').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 })
        Blank()
        Text('分享').fontSize(14).fontColor('#1677C8')
      }.width('100%').height(60).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      Scroll() {
        Column({ space: 14 }) {
          Text(this.title).fontSize(23).fontWeight(FontWeight.Bold).fontColor('#182433').width('100%')
          Text('过早客 · 主题').fontSize(13).fontColor('#8A96A3').width('100%')
          Divider().color('#E9EEF3')
          if (this.loading) {
            LoadingProgress().margin({ top: 36 })
          } else {
            Text(this.content).fontSize(16).lineHeight(28).fontColor('#344454').width('100%')
          }
          Row({ space: 12 }) {
            Button('♡ 收藏').layoutWeight(1).backgroundColor('#EAF4FC').fontColor('#1677C8')
            Button('↗ 分享').layoutWeight(1).backgroundColor('#EAF4FC').fontColor('#1677C8')
          }.width('100%')
        }.padding(20).margin({ top: 10, left: 10, right: 10 }).backgroundColor(Color.White).borderRadius(14)
      }.layoutWeight(1).width('100%').backgroundColor('#F5F7FA')
    }.width('100%').height('100%')
      .backgroundColor('#F5F7FA')
  }
}
