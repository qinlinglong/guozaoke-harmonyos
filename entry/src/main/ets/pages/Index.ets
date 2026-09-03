import { router } from '@kit.ArkUI';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct Index {
  @State topics: Array<Topic> = [];
  @State loading: boolean = true;
  @State message: string = '';
  @State tab: string = '';

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
        this.message = '暂无内容，点击右上角刷新';
      }
    } catch (_) {
      this.message = '加载失败，请检查网络后重试';
    }
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Text('过早客').fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White)
        Blank()
        Text('刷新').fontColor(Color.White).onClick(() => this.loadTopics())
        Text('搜索').fontColor(Color.White).margin({ left: 16 })
          .onClick(() => router.pushUrl({ url: 'pages/SearchPage' }))
        Text('通知').fontColor(Color.White).margin({ left: 16 })
          .onClick(() => router.pushUrl({ url: 'pages/NotificationsPage' }))
      }
      .width('100%').height(56).padding({ left: 18, right: 18 }).backgroundColor('#2389E8')

      if (this.loading) {
        LoadingProgress().margin({ top: 80 })
      } else if (this.message.length > 0) {
        Text(this.message).fontColor('#777777').margin({ top: 80 })
      } else {
        Row({ space: 18 }) {
          Text('最新').fontColor(this.tab === 'latest' ? '#2389E8' : '#777777').onClick(() => { this.tab = 'latest'; this.loadTopics(); })
          Text('精华').fontColor(this.tab === 'elite' ? '#2389E8' : '#777777').onClick(() => { this.tab = 'elite'; this.loadTopics(); })
          Text('关注').fontColor(this.tab === 'follows' ? '#2389E8' : '#777777').onClick(() => { this.tab = 'follows'; this.loadTopics(); })
          Text('全部').fontColor(this.tab === '' ? '#2389E8' : '#777777').onClick(() => { this.tab = ''; this.loadTopics(); })
        }.padding({ left: 16, top: 10, bottom: 10 })
        List({ space: 1 }) {
          ForEach(this.topics, (topic: Topic) => {
            ListItem() {
              Row({ space: 12 }) {
                Image(topic.avatar).width(44).height(44).borderRadius(22).objectFit(ImageFit.Cover)
                Column({ space: 6 }) {
                  Text(topic.title).fontSize(16).fontWeight(FontWeight.Medium).maxLines(2)
                  Row({ space: 8 }) {
                    Text(topic.node).fontSize(12).fontColor('#2389E8')
                    Text(topic.author).fontSize(12).fontColor('#777777')
                    Blank()
                    Text(`${topic.replies} 回复`).fontSize(12).fontColor('#777777')
                  }.width('100%')
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              }
              .padding(14).backgroundColor(Color.White)
              .onClick(() => router.pushUrl({
                url: 'pages/TopicPage', params: { id: topic.id, title: topic.title }
              }))
            }
          }, (topic: Topic) => topic.id)
        }.layoutWeight(1).width('100%')
      }

      Row() {
        Text('首页').fontColor('#2389E8').layoutWeight(1).textAlign(TextAlign.Center)
        Text('节点').layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => router.pushUrl({ url: 'pages/NodesPage' }))
        Text(GuozaokeService.isLoggedIn() ? '个人中心' : '登录')
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => router.pushUrl({ url: GuozaokeService.isLoggedIn() ? 'pages/ProfilePage' : 'pages/LoginPage' }))
      }
      .width('100%').height(54).backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#EEEEEE' })
      Button('发表主题').position({ x: '78%', y: '82%' }).onClick(() => router.pushUrl({ url: 'pages/NewTopicPage' }))
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
