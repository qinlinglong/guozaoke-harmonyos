import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { Topic } from '../model/Topic';
import { GuozaokeService } from '../service/GuozaokeService';

interface DrawerRouteParams {
  kind?: string;
  id?: string;
  title?: string;
}

@Entry
@Component
struct Index {
  @State topics: Array<Topic> = [];
  @State loading: boolean = true;
  @State message: string = '';
  @State tab: string = '';
  @State webFallback: boolean = false;
  @State challengeReady: boolean = false;
  @State drawerOpen: boolean = false;
  @State selfAvatar: string = '';
  @State selfName: string = '';
  private topicCache: Map<string, Array<Topic>> = new Map();
  private requestSerial: number = 0;
  controller: webview.WebviewController = new webview.WebviewController();

  private closeDrawer(): void {
    // Keep the overlay alive until the current pointer sequence has finished.
    // Removing it synchronously lets the release event hit a topic underneath.
    setTimeout(() => this.drawerOpen = false, 80);
  }

  private openFromDrawer(url: string, params: DrawerRouteParams = {}): void {
    this.drawerOpen = false;
    setTimeout(() => router.pushUrl({ url, params }), 80);
  }

  onBackPress(): boolean {
    if (this.drawerOpen) {
      this.drawerOpen = false;
      return true;
    }
    return false;
  }

  aboutToAppear(): void {
    this.drawerOpen = false;
    try {
      const params = router.getParams() as Record<string, string>;
      this.tab = params && params.tab ? params.tab : '';
    } catch (_) { this.tab = ''; }
    if (GuozaokeService.isLoggedIn()) {
      GuozaokeService.selfAvatar().then((value: string) => this.selfAvatar = value);
      GuozaokeService.selfUsername().then((value: string) => this.selfName = value);
    }
    this.loadTopics();
    // Do not leave the native page blocked if the anti-bot bootstrap is slow
    // or unavailable; continue with the normal native request after a bound.
    setTimeout(() => {
      if (!this.challengeReady) {
        this.challengeReady = true;
        this.loadTopics();
      }
    }, 5000);
  }

  async loadTopics(): Promise<void> {
    if (!this.challengeReady) {
      this.loading = true;
      return;
    }
    const requestedTab = this.tab;
    const serial = ++this.requestSerial;
    this.loading = true;
    this.message = '';
    this.webFallback = false;
    try {
      const timeout = new Promise<Array<Topic>>((_, reject) => {
        setTimeout(() => reject(new Error('native request timeout')), 12000);
      });
      const nextTopics = await Promise.race([GuozaokeService.topics(requestedTab), timeout]);
      if (serial !== this.requestSerial) return;
      this.topicCache.set(requestedTab, nextTopics);
      this.topics = nextTopics;
      if (nextTopics.length === 0) {
        this.message = GuozaokeService.isLoggedIn() ? '暂时没有可显示的主题，点击刷新重试' : '正在加载社区内容…';
        this.webFallback = !GuozaokeService.isLoggedIn();
      }
    } catch (_) {
      if (serial !== this.requestSerial) return;
      const loggedIn = GuozaokeService.isLoggedIn();
      this.message = loggedIn ? '原生列表加载失败，请点击刷新重试' : '原生接口暂时不可用，正在打开社区页面…';
      this.webFallback = !loggedIn && this.topics.length === 0;
      if (this.topics.length > 0) {
        const currentMessage = this.message;
        setTimeout(() => { if (this.message === currentMessage) this.message = ''; }, 2200);
      }
    }
    if (serial === this.requestSerial) this.loading = false;
  }

  private switchTab(nextTab: string): void {
    if (this.tab === nextTab) return;
    this.tab = nextTab;
    const cached = this.topicCache.get(nextTab);
    if (cached !== undefined) this.topics = cached;
    this.message = '';
    this.webFallback = false;
    this.loadTopics();
  }

  build() {
    Column() {
      Row() {
        Row() { Image($r('app.media.ic_menu')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          .onClick(() => setTimeout(() => this.drawerOpen = true, 80))
        Text('过早客').fontSize(20).fontWeight(FontWeight.Medium).fontColor(Color.White).margin({ left: 22 })
        Blank()
        Row() { Image($r('app.media.ic_refresh')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center).onClick(() => this.loadTopics())
        Row() { Image($r('app.media.ic_search')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          .onClick(() => router.pushUrl({ url: 'pages/SearchPage' }))
        Row() { Image($r('app.media.ic_notifications')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          .onClick(() => router.pushUrl({ url: 'pages/NotificationsPage' }))
      }
      .width('100%').height(56).flexShrink(0).padding({ left: 18, right: 18 }).backgroundColor('#258DF5')

      if (this.loading && this.topics.length === 0) {
        LoadingProgress().margin({ top: 80 })
        // The site currently serves an anti-bot bootstrap page to raw HTTP
        // clients. Let WebView establish its cookie, then retry native parsing.
        Web({ src: 'https://www.guozaoke.com/', controller: this.controller })
          .javaScriptAccess(true).domStorageAccess(true).height(1).width(1).opacity(0.01)
          .onPageEnd(() => {
            if (!this.challengeReady) {
              this.challengeReady = true;
              setTimeout(() => this.loadTopics(), 1200);
            }
          })
      } else if (this.webFallback) {
        Web({ src: this.tab.length > 0 ? `https://www.guozaoke.com/?tab=${this.tab}` : 'https://www.guozaoke.com/', controller: this.controller })
          .javaScriptAccess(true).domStorageAccess(true)
          .runJavaScriptOnDocumentEnd([{ script: `document.querySelector('meta[name=viewport]')||document.head.insertAdjacentHTML('beforeend','<meta name=viewport content="width=device-width,initial-scale=1">');var s=document.createElement('style');s.textContent='[id*=ad],[class*=ad],[class*=advert],iframe[src*=ad]{display:none!important}';document.head.appendChild(s);`, scriptRules: ['*'] }])
          .layoutWeight(1).width('100%')
      } else {
        Row() {
          Text('首页').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === '' ? Color.White : '#B3FFFFFF').onClick(() => this.switchTab(''))
          Text('最新').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === 'latest' ? Color.White : '#B3FFFFFF').onClick(() => this.switchTab('latest'))
          Text('精华').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === 'elite' ? Color.White : '#B3FFFFFF').onClick(() => this.switchTab('elite'))
          Text('关注').layoutWeight(1).textAlign(TextAlign.Center).fontColor(this.tab === 'follows' ? Color.White : '#B3FFFFFF').onClick(() => this.switchTab('follows'))
        }.width('100%').height(40).padding({ left: 10, right: 10, bottom: 4 }).backgroundColor('#258DF5')
        Stack({ alignContent: Alignment.TopEnd }) {
          if (this.message.length > 0 && this.topics.length === 0) {
            Text(this.message).fontColor('#777777').width('100%').textAlign(TextAlign.Center).margin({ top: 80 })
          } else {
            List({ space: 1 }) {
              ForEach(this.topics, (topic: Topic) => {
                ListItem() {
                  Column() {
                    Row() {
                      Stack() {
                        // Keep the local avatar visible if the CDN image is slow,
                        // blocked, or returns an unsupported animated format.
                        Image($r('app.media.avatar_placeholder'))
                          .width(20).height(20).borderRadius(10).objectFit(ImageFit.Cover)
                        if (topic.avatar.length > 0) {
                          Image(topic.avatar).width(20).height(20).borderRadius(10).objectFit(ImageFit.Cover)
                        }
                      }
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
            }.width('100%').height('100%')
          }
          if (this.loading && this.topics.length > 0) {
            Row() {
              LoadingProgress().width(16).height(16).color('#258DF5')
              Text('更新中').fontSize(11).fontColor('#5F6B76').margin({ left: 5 })
            }.height(30).padding({ left: 10, right: 10 }).margin({ top: 8, right: 12 })
              .backgroundColor('#F2FFFFFF').borderRadius(15).shadow({ radius: 4, color: '#22000000', offsetY: 1 })
          } else if (this.message.length > 0 && this.topics.length > 0) {
            Text(this.message).fontSize(11).fontColor('#5F6B76').height(30).padding({ left: 10, right: 10 })
              .margin({ top: 8, right: 12 }).backgroundColor('#F2FFFFFF').borderRadius(15)
              .shadow({ radius: 4, color: '#22000000', offsetY: 1 })
          }
        }.layoutWeight(1).width('100%')
      }

      Image($r('app.media.pixel_icon')).width(46).height(46).borderRadius(23)
        .position({ x: '84%', y: '84%' }).shadow({ radius: 8, color: '#55000000', offsetY: 3 })
        .onClick(() => router.pushUrl({ url: 'pages/NodesPage', params: { select: '1' } }))
      if (this.drawerOpen) {
        Row() {
          Column() {
            Column() {
              Row() {
                Stack() {
                  Image($r('app.media.avatar_placeholder')).width(64).height(64).borderRadius(32).objectFit(ImageFit.Cover)
                  if (this.selfAvatar.length > 0) {
                    Image(this.selfAvatar).width(64).height(64).borderRadius(32).objectFit(ImageFit.Cover)
                  }
                }.onClick(() => this.openFromDrawer(GuozaokeService.isLoggedIn() ? 'pages/ProfilePage' : 'pages/LoginPage'))
                Blank()
                Row() {
                  Image($r('app.media.ic_search')).width(22).height(22).objectFit(ImageFit.Contain)
                }.width(42).height(42).justifyContent(FlexAlign.Center)
                  .onClick(() => this.openFromDrawer('pages/SearchPage'))
                Row() {
                  Text('×').fontSize(28).fontColor(Color.White)
                }.width(42).height(42).justifyContent(FlexAlign.Center)
                  .onClick(() => this.closeDrawer())
              }
                .width('100%').padding({ top: 24, bottom: 14 })
              Text(GuozaokeService.isLoggedIn() ? (this.selfName.length > 0 ? this.selfName : '过早客用户') : '未登录').fontSize(18).fontWeight(FontWeight.Medium).fontColor(Color.White).width('100%')
                .onClick(() => this.openFromDrawer(GuozaokeService.isLoggedIn() ? 'pages/ProfilePage' : 'pages/LoginPage'))
              Text(GuozaokeService.isLoggedIn() ? '已登录 · guozaoke.com' : '登录后参与讨论').fontSize(12).fontColor('#D7E8FF').width('100%').margin({ top: 6, bottom: 20 })
            }.width('100%').padding({ left: 20, right: 20 }).backgroundColor('#258DF5')
            Scroll() {
              Column() {
                this.drawerItem('ic_person', GuozaokeService.isLoggedIn() ? '个人中心' : '登录', () => this.openFromDrawer(GuozaokeService.isLoggedIn() ? 'pages/ProfilePage' : 'pages/LoginPage'))
                this.drawerItem('ic_favorite', '我的收藏', () => this.openFromDrawer('pages/TopicListPage', { kind: 'favorites' }))
                this.drawerItem('ic_nodes', '节点', () => this.openFromDrawer('pages/NodesPage'))
                this.drawerItem('ic_help', '新手指南', () => this.openFromDrawer('pages/TopicPage', { id: '2657', title: '新手指南' }))
                this.drawerItem('ic_info', '关于', () => this.openFromDrawer('pages/AboutPage'))
              }.width('100%').constraintSize({ minHeight: '100%' }).justifyContent(FlexAlign.Start)
                .backgroundColor(Color.White)
            }.layoutWeight(1).width('100%').scrollBar(BarState.Auto)
          }.width('78%').height('100%').backgroundColor('#F5F6F8').shadow({ radius: 16, color: '#55000000', offsetX: 4 })
            .hitTestBehavior(HitTestMode.Default)
          // The dismiss surface only occupies the area outside the drawer, so
          // it can never steal taps from lower menu rows.
          Row().layoutWeight(1).height('100%').backgroundColor('#00000055')
            .hitTestBehavior(HitTestMode.Block)
            .onClick(() => this.closeDrawer())
        }.alignItems(VerticalAlign.Top).position({ x: 0, y: 0 }).width('100%').height('100%')
          .hitTestBehavior(HitTestMode.Default)
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  drawerItem(icon: string, label: string, action: () => void) {
    Row() {
      Image($r(`app.media.${icon}`)).width(22).height(22).margin({ right: 18 })
      Text(label).fontSize(16).fontColor('#3C4043').layoutWeight(1)
      Text('›').fontSize(24).fontColor('#A0A5AB')
    }.width('100%').height(60).padding({ left: 22, right: 18 }).border({ width: { bottom: 1 }, color: '#ECEEF0' }).onClick(action)
  }
}
