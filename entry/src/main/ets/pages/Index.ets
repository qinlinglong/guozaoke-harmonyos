import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct Index {
  @State topics: Array<Topic> = [];
  @State loading: boolean = true;
  @State message: string = '';
  @State tab: string = '';
  @State webFallback: boolean = false;
  controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.tab = params && params.tab ? params.tab : '';
    } catch (_) { this.tab = ''; }
    this.loadTopics();
  }

  async loadTopics(): Promise<void> {
    this.loading = true;
    this.message = '';
    try {
      this.topics = await GuozaokeService.topics(this.tab);
      if (this.topics.length === 0) {
        this.message = '正在加载社区内容…';
        this.webFallback = true;
      }
    } catch (_) {
      this.message = '原生接口暂时不可用，正在打开社区页面…';
      this.webFallback = true;
    }
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text('过早客').fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White)
          Text('分享 · 交流 · 发现').fontSize(11).fontColor('#D9EEFF')
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Text('↻').fontSize(26).fontColor(Color.White).onClick(() => this.loadTopics())
        Text('⌕').fontSize(28).fontColor(Color.White).margin({ left: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/SearchPage' }))
        Text('♢').fontSize(24).fontColor(Color.White).margin({ left: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/NotificationsPage' }))
      }
      .width('100%').height(76).padding({ left: 20, right: 20 }).backgroundColor('#1677C8')

      if (this.loading) {
        LoadingProgress().margin({ top: 80 })
      } else if (this.webFallback) {
        Web({ src: this.tab.length > 0 ? `https://www.guozaoke.com/?tab=${this.tab}` : 'https://www.guozaoke.com/', controller: this.controller })
          .javaScriptAccess(true).domStorageAccess(true).layoutWeight(1).width('100%')
      } else if (this.message.length > 0) {
        Text(this.message).fontColor('#777777').margin({ top: 80 })
      } else {
        Row({ space: 22 }) {
          Text('最新').fontColor(this.tab === 'latest' ? '#2389E8' : '#777777').onClick(() => { this.tab = 'latest'; this.loadTopics(); })
          Text('精华').fontColor(this.tab === 'elite' ? '#2389E8' : '#777777').onClick(() => { this.tab = 'elite'; this.loadTopics(); })
          Text('关注').fontColor(this.tab === 'follows' ? '#2389E8' : '#777777').onClick(() => { this.tab = 'follows'; this.loadTopics(); })
          Text('全部').fontColor(this.tab === '' ? '#2389E8' : '#777777').onClick(() => { this.tab = ''; this.loadTopics(); })
        }.width('100%').padding({ left: 20, top: 14, bottom: 12 }).backgroundColor(Color.White)
        List({ space: 1 }) {
          ForEach(this.topics, (topic: Topic) => {
            ListItem() {
              Row({ space: 14 }) {
                Image(topic.avatar.length > 0 ? topic.avatar : $r('app.media.pixel_icon'))
                  .width(46).height(46).borderRadius(23).objectFit(ImageFit.Cover)
                Column({ space: 6 }) {
                  Text(topic.title).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#182433').maxLines(2)
                  Row({ space: 8 }) {
                    Text(topic.node).fontSize(12).fontColor('#1677C8')
                    Text(topic.author).fontSize(12).fontColor('#8A96A3')
                    Blank()
                    Text(`${topic.replies} 回复`).fontSize(12).fontColor('#8A96A3')
                  }.width('100%')
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              }
              .padding({ left: 18, right: 18, top: 16, bottom: 16 }).margin({ left: 10, right: 10, top: 6 })
              .borderRadius(12).backgroundColor(Color.White)
              .onClick(() => router.pushUrl({
                url: 'pages/TopicPage', params: { id: topic.id, title: topic.title }
              }))
            }
          }, (topic: Topic) => topic.id)
        }.layoutWeight(1).width('100%')
      }

      Row() {
        Column({ space: 3 }) { Text('⌂').fontSize(22).fontColor('#1677C8'); Text('首页').fontSize(12).fontColor('#1677C8'); }
          .layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column({ space: 3 }) { Text('◇').fontSize(22).fontColor('#647383'); Text('节点').fontSize(12).fontColor('#647383'); }
          .layoutWeight(1).alignItems(HorizontalAlign.Center)
          .onClick(() => router.pushUrl({ url: 'pages/NodesPage' }))
        Column({ space: 3 }) { Text('●').fontSize(22).fontColor('#647383'); Text(GuozaokeService.isLoggedIn() ? '我的' : '登录').fontSize(12).fontColor('#647383'); }
          .layoutWeight(1).alignItems(HorizontalAlign.Center)
          .onClick(() => router.pushUrl({ url: GuozaokeService.isLoggedIn() ? 'pages/ProfilePage' : 'pages/LoginPage' }))
      }
      .width('100%').height(64).backgroundColor(Color.White).padding({ top: 6, bottom: 6 })
      .border({ width: { top: 1 }, color: '#EEEEEE' })
      Button('+ 发表主题').position({ x: '70%', y: '78%' }).height(44).borderRadius(22)
        .backgroundColor('#1677C8').onClick(() => router.pushUrl({ url: 'pages/NewTopicPage' }))
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
