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
  @State drawerOpen: boolean = false;
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
      const timeout = new Promise<Array<Topic>>((_, reject) => {
        setTimeout(() => reject(new Error('native request timeout')), 12000);
      });
      this.topics = await Promise.race([GuozaokeService.topics(this.tab), timeout]);
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
        Text('☰').fontSize(25).fontColor(Color.White).onClick(() => this.drawerOpen = true)
        Text('过早客').fontSize(20).fontWeight(FontWeight.Medium).fontColor(Color.White).margin({ left: 22 })
        Blank()
        Text('↻').fontSize(26).fontColor(Color.White).onClick(() => this.loadTopics())
        Text('⌕').fontSize(28).fontColor(Color.White).margin({ left: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/SearchPage' }))
        Text('♢').fontSize(24).fontColor(Color.White).margin({ left: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/NotificationsPage' }))
      }
      .width('100%').height(56).padding({ left: 18, right: 18 }).backgroundColor('#258DF5')

      if (this.loading) {
        LoadingProgress().margin({ top: 80 })
      } else if (this.webFallback) {
        Web({ src: this.tab.length > 0 ? `https://www.guozaoke.com/?tab=${this.tab}` : 'https://www.guozaoke.com/', controller: this.controller })
          .javaScriptAccess(true).domStorageAccess(true).layoutWeight(1).width('100%')
      } else if (this.message.length > 0) {
        Text(this.message).fontColor('#777777').margin({ top: 80 })
      } else {
        Row() {
          Text('首页').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === '' ? Color.White : '#B3FFFFFF').onClick(() => { this.tab = ''; this.loadTopics(); })
          Text('最新').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === 'latest' ? Color.White : '#B3FFFFFF').onClick(() => { this.tab = 'latest'; this.loadTopics(); })
          Text('精华').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === 'elite' ? Color.White : '#B3FFFFFF').onClick(() => { this.tab = 'elite'; this.loadTopics(); })
          Text('关注').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === 'follows' ? Color.White : '#B3FFFFFF').onClick(() => { this.tab = 'follows'; this.loadTopics(); })
        }.width('100%').height(40).padding({ left: 10, right: 10, bottom: 4 }).backgroundColor('#258DF5')
        List({ space: 1 }) {
          ForEach(this.topics, (topic: Topic) => {
            ListItem() {
              Column() {
                Row() {
                  Image(topic.avatar.length > 0 ? topic.avatar : $r('app.media.default_avatar'))
                    .width(20).height(20).borderRadius(10).objectFit(ImageFit.Cover)
                  Text(topic.author).fontSize(14).fontColor('#444444').margin({ left: 8 })
                  Blank()
                  Text(topic.node).fontSize(12).fontColor('#BBBBBB').maxLines(1)
                }.width('100%').height(20)
                Text(topic.title).fontSize(16).fontColor('#444444').lineHeight(20).maxLines(2)
                  .margin({ top: 12, bottom: 12 }).width('100%')
                Row() {
                  Blank()
                  Text(`${topic.replies} 回复`).fontSize(12).fontColor('#BBBBBB')
                }.width('100%')
              }
              .padding({ left: 16, right: 16, top: 12, bottom: 16 })
              .backgroundColor(Color.White)
              .onClick(() => router.pushUrl({
                url: 'pages/TopicPage', params: { id: topic.id, title: topic.title }
              }))
            }
          }, (topic: Topic) => topic.id)
        }.layoutWeight(1).width('100%')
      }

      Image($r('app.media.pixel_icon')).width(56).height(56).borderRadius(28)
        .position({ x: '80%', y: '82%' }).shadow({ radius: 8, color: '#55000000', offsetY: 3 })
        .onClick(() => router.pushUrl({ url: 'pages/NewTopicPage' }))
      if (this.drawerOpen) {
        Stack() {
          Column({ space: 14 }) {
            Image($r('app.media.default_avatar')).width(64).height(64).borderRadius(32).margin({ top: 24 })
            Text(GuozaokeService.isLoggedIn() ? '过早客用户' : '未登录').fontSize(16).fontColor(Color.White)
            Text(GuozaokeService.isLoggedIn() ? '个人中心' : '登录').fontSize(17).fontColor(Color.White).padding(14).width('100%')
              .onClick(() => router.pushUrl({ url: GuozaokeService.isLoggedIn() ? 'pages/ProfilePage' : 'pages/LoginPage' }))
            Text('我的收藏').fontSize(17).fontColor(Color.White).padding(14).width('100%').onClick(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'favorites' } }))
            Text('节点').fontSize(17).fontColor(Color.White).padding(14).width('100%').onClick(() => router.pushUrl({ url: 'pages/NodesPage' }))
            Text('设置').fontSize(17).fontColor(Color.White).padding(14).width('100%').onClick(() => router.pushUrl({ url: 'pages/SettingsPage' }))
            Blank()
          }.width('78%').height('100%').padding({ left: 20, right: 20 }).backgroundColor('#258DF5').alignItems(HorizontalAlign.Start)
          Row().width('22%').height('100%').backgroundColor('#00000055').onClick(() => this.drawerOpen = false)
        }.alignContent(Alignment.TopStart).position({ x: 0, y: 0 }).width('100%').height('100%')
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
