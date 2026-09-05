import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { Topic } from '../model/Topic';
import { TopicListResult } from '../model/TopicListResult';
import { GuozaokeService } from '../service/GuozaokeService';

interface DrawerRouteParams {
  kind?: string;
  id?: string;
  title?: string;
}

@Entry
@Component
struct Index {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State topics: Array<Topic> = [];
  @State loading: boolean = true;
  @State message: string = '';
  @State tab: string = '';
  @State webFallback: boolean = false;
  @State challengeReady: boolean = false;
  @State drawerOpen: boolean = false;
  @State selfAvatar: string = '';
  @State selfName: string = '';
  @State currentPage: number = 1;
  @State hasMore: boolean = false;
  @State loadingMore: boolean = false;
  @State refreshing: boolean = false;
  private topicCache: Map<string, Array<Topic>> = new Map();
  private pageCache: Map<string, number> = new Map();
  private hasMoreCache: Map<string, boolean> = new Map();
  private requestSerial: number = 0;
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private touchMoved: boolean = false;
  private horizontalSwipeHandled: boolean = false;
  controller: webview.WebviewController = new webview.WebviewController();

  private trackTopicTouch(event: TouchEvent): void {
    const point = event.touches.length > 0 ? event.touches[0] : undefined;
    if (!point) return;
    if (event.type === TouchType.Down) {
      this.touchStartX = point.windowX;
      this.touchStartY = point.windowY;
      this.touchMoved = false;
      this.horizontalSwipeHandled = false;
    } else if (event.type === TouchType.Move) {
      const deltaX = point.windowX - this.touchStartX;
      const deltaY = point.windowY - this.touchStartY;
      if (Math.abs(deltaX) > 18 || Math.abs(deltaY) > 18) {
        this.touchMoved = true;
      }
      // A horizontal gesture changes the selected tab in sequence. Mark it
      // handled before switching because both the Refresh and its ListItem
      // receive the same pointer stream.
      if (!this.horizontalSwipeHandled && Math.abs(deltaX) > 72 && Math.abs(deltaX) > Math.abs(deltaY) * 1.25) {
        const tabs: Array<string> = ['', 'latest', 'elite', 'follows'];
        const currentIndex = tabs.indexOf(this.tab);
        const nextIndex = currentIndex + (deltaX < 0 ? 1 : -1);
        if (currentIndex >= 0 && nextIndex >= 0 && nextIndex < tabs.length) {
          this.horizontalSwipeHandled = true;
          this.switchTab(tabs[nextIndex]);
        }
      }
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      setTimeout(() => this.touchMoved = false, 240);
      setTimeout(() => this.horizontalSwipeHandled = false, 240);
    }
  }

  private closeDrawer(): void {
    // Keep the overlay alive until the current pointer sequence has finished.
    // Removing it synchronously lets the release event hit a topic underneath.
    setTimeout(() => this.drawerOpen = false, 80);
  }

  private openFromDrawer(url: string, params: DrawerRouteParams = {}): void {
    // Keep the drawer above the topic list for the entire pointer sequence.
    // Closing it before navigation lets the finger-up event activate the row
    // underneath and can replace the intended destination with a topic page.
    setTimeout(() => {
      router.pushUrl({ url, params });
      setTimeout(() => this.drawerOpen = false, 120);
    }, 80);
  }

  @Builder
  startupLoader() {
    Column() {
      Image($r('app.media.ic_hot_dry_noodles')).width(96).height(96)
        .objectFit(ImageFit.Contain)
        .backgroundColor('#F5F5F5')
      Text('过早客').fontSize(21).fontWeight(FontWeight.Medium).fontColor('#3C4043').margin({ top: 18 })
      Text('正在加载社区内容').fontSize(13).fontColor('#7B8794').margin({ top: 6 })
      LoadingProgress().width(24).height(24).color(this.themeColor).margin({ top: 20 })
    }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
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

  async loadTopics(loadMore: boolean = false): Promise<void> {
    if (!this.challengeReady) {
      this.loading = true;
      this.refreshing = false;
      return;
    }
    if (loadMore && (this.loadingMore || !this.hasMore)) return;
    const requestedTab = this.tab;
    const requestedPage = loadMore ? this.currentPage + 1 : 1;
    const serial = ++this.requestSerial;
    if (loadMore) this.loadingMore = true;
    else this.loading = true;
    this.message = '';
    this.webFallback = false;
    try {
      const timeout = new Promise<TopicListResult>((_, reject) => {
        setTimeout(() => reject(new Error('native request timeout')), 12000);
      });
      const pageResult = await Promise.race([GuozaokeService.topicPage(requestedTab, requestedPage), timeout]);
      if (serial !== this.requestSerial) return;
      const nextTopics: Array<Topic> = pageResult.topics;
      if (loadMore) {
        const knownIds: Set<string> = new Set(this.topics.map((topic: Topic) => topic.id));
        this.topics = this.topics.concat(nextTopics.filter((topic: Topic) => !knownIds.has(topic.id)));
      } else {
        this.topics = nextTopics;
      }
      this.currentPage = requestedPage;
      this.hasMore = pageResult.hasMore && nextTopics.length > 0;
      this.topicCache.set(requestedTab, this.topics);
      this.pageCache.set(requestedTab, this.currentPage);
      this.hasMoreCache.set(requestedTab, this.hasMore);
      if (!loadMore && nextTopics.length === 0) {
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
    if (serial === this.requestSerial) {
      this.loading = false;
      this.loadingMore = false;
      this.refreshing = false;
    }
  }

  private switchTab(nextTab: string): void {
    if (this.tab === nextTab) return;
    this.tab = nextTab;
    const cached = this.topicCache.get(nextTab);
    if (cached !== undefined) {
      this.topics = cached;
      this.currentPage = this.pageCache.get(nextTab) ?? 1;
      this.hasMore = this.hasMoreCache.get(nextTab) ?? false;
    } else {
      // Keep the current tab content in place while the next tab is loading.
      // Clearing the list first caused the whole page to collapse briefly.
      this.currentPage = 1;
      this.hasMore = false;
    }
    this.message = '';
    this.webFallback = false;
    this.loadTopics(false);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
      Row() {
        Row() { Image($r('app.media.ic_menu')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          // onClick is emitted after the menu button's pointer sequence. Show
          // the drawer immediately so a delayed overlay cannot receive the
          // same tap on its avatar (which would jump to the profile page).
          .onClick(() => this.drawerOpen = true)
        Text('过早客').fontSize(20).fontWeight(FontWeight.Medium).fontColor(Color.White).margin({ left: 22 })
        Blank()
        Row() { Image($r('app.media.ic_hot')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/HotTopicsPage' }), 80))
        Row() { Image($r('app.media.ic_nodes')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/NodesPage' }), 80))
        Row() { Image($r('app.media.ic_search')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/SearchPage' }), 80))
        Row() { Image($r('app.media.ic_notifications')).width(24).height(24).objectFit(ImageFit.Contain) }
          .width(44).height(56).justifyContent(FlexAlign.Center)
          .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/NotificationsPage' }), 80))
      }
      .width('100%').height(56).flexShrink(0).padding({ left: 18, right: 18 }).backgroundColor(this.themeColor)

      if (this.loading && this.topics.length === 0) {
        this.startupLoader()
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
        }.width('100%').height(40).padding({ left: 10, right: 10, bottom: 4 }).backgroundColor(this.themeColor)
        Stack({ alignContent: Alignment.TopEnd }) {
          if (this.message.length > 0 && this.topics.length === 0) {
            Text(this.message).fontColor('#777777').width('100%').textAlign(TextAlign.Center).margin({ top: 80 })
          } else {
            Refresh({ refreshing: this.refreshing }) {
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
                    .onTouch((event: TouchEvent) => this.trackTopicTouch(event))
                    .onClick(() => {
                      if (this.touchMoved) return;
                      router.pushUrl({
                        url: 'pages/TopicPage', params: { id: topic.id, title: topic.title }
                      });
                    })
                  }
                }, (topic: Topic) => topic.id)
                if (this.loadingMore || this.hasMore) {
                  ListItem() {
                    Row() {
                      if (this.loadingMore) { LoadingProgress().width(18).height(18).color(this.themeColor) }
                      Text(this.loadingMore ? '正在加载下一页…' : '继续上滑加载更多').fontSize(12).fontColor('#7B8794')
                        .margin({ left: this.loadingMore ? 8 : 0 })
                    }.width('100%').height(48).justifyContent(FlexAlign.Center)
                  }
                }
              }.width('100%').height('100%').onReachEnd(() => this.loadTopics(true))
            }.layoutWeight(1).width('100%').onTouch((event: TouchEvent) => this.trackTopicTouch(event)).onRefreshing(() => {
              this.refreshing = true;
              this.loadTopics(false);
            })
          }
          if (this.loading && this.topics.length > 0) {
            Row() {
              LoadingProgress().width(16).height(16).color(this.themeColor)
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
        .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/NodesPage', params: { select: '1' } }), 80))
      }.width('100%').height('100%').backgroundColor('#F5F5F5')

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
              Text(GuozaokeService.isLoggedIn() ? '已登录 · guozaoke.com' : '登录后参与讨论').fontSize(12).fontColor('#CCFFFFFF').width('100%').margin({ top: 6, bottom: 20 })
            }.width('100%').padding({ left: 20, right: 20 }).backgroundColor(this.themeColor)
            Scroll() {
              Column() {
                this.drawerItem('ic_person', GuozaokeService.isLoggedIn() ? '个人中心' : '登录', () => this.openFromDrawer(GuozaokeService.isLoggedIn() ? 'pages/ProfilePage' : 'pages/LoginPage'))
                this.drawerItem('ic_favorite', '我的收藏', () => this.openFromDrawer('pages/TopicListPage', { kind: 'favorites' }))
                this.drawerItem('ic_nodes_menu', '节点', () => this.openFromDrawer('pages/NodesPage'))
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
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
  }

  @Builder
  drawerItem(icon: string, label: string, action: () => void) {
    Row() {
      Image($r(`app.media.${icon}`)).width(22).height(22).margin({ right: 18 })
      Text(label).fontSize(16).fontColor('#3C4043').layoutWeight(1)
      Text('›').fontSize(24).fontColor('#A0A5AB')
    }.width('100%').height(60).padding({ left: 22, right: 18 }).border({ width: { bottom: 1 }, color: '#ECEEF0' }).onClick(action)
      .hitTestBehavior(HitTestMode.Block)
  }
}
