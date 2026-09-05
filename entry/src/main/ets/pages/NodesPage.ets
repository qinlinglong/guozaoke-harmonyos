import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { GuozaokeService } from '../service/GuozaokeService';
import { NodeItem } from '../model/NodeItem';

@Entry
@Component
struct NodesPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State nodes: Array<NodeItem> = [];
  @State selecting: boolean = false;
  @State loading: boolean = true;
  @State draftTitle: string = '';
  @State draftContent: string = '';
  @State bootstrapping: boolean = false;
  @State message: string = '';
  private bootstrapAttempted: boolean = false;
  controller: webview.WebviewController = new webview.WebviewController();
  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.selecting = !!params && params.select === '1';
      this.draftTitle = params && params.draftTitle ? params.draftTitle : '';
      this.draftContent = params && params.draftContent ? params.draftContent : '';
    } catch (_) { this.selecting = false; }
    this.load();
  }
  async load(): Promise<void> {
    this.loading = true;
    this.message = '';
    try {
      this.nodes = await GuozaokeService.nodes();
    } catch (_) { this.nodes = []; }
    if (this.nodes.length === 0 && !this.bootstrapAttempted) {
      this.bootstrapping = true;
      setTimeout(() => {
        if (this.bootstrapping) {
          this.bootstrapAttempted = true;
          this.bootstrapping = false;
          this.load();
        }
      }, 6000);
      return;
    }
    this.message = this.nodes.length === 0 ? '节点加载失败，点击重试' : `已从网站同步 ${this.nodes.length} 个节点`;
    this.loading = false;
  }
  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => setTimeout(() => router.back(), 80))
        Text(this.selecting ? '选择发帖节点' : '节点').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 })
        Blank()
        Image($r('app.media.ic_refresh')).width(22).height(22).fillColor(this.themeColor).margin({ right: 18 })
          .onClick(() => { this.bootstrapAttempted = false; this.load(); })
      }.width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      if (this.loading) { LoadingProgress().color(this.themeColor).margin({ top: 54 }); }
      if (this.bootstrapping) {
        Web({ src: 'https://www.guozaoke.com/nodes', controller: this.controller })
          .javaScriptAccess(true).domStorageAccess(true).height(1).width(1).opacity(0.01)
          .onPageEnd(() => {
            if (this.bootstrapping) {
              this.bootstrapAttempted = true;
              this.bootstrapping = false;
              setTimeout(() => this.load(), 600);
            }
          })
      }
      if (!this.loading && this.message.length > 0) {
        Text(this.message).fontSize(12).fontColor(this.nodes.length > 0 ? this.themeColor : '#7B8794')
          .width('100%').height(34).textAlign(TextAlign.Center).onClick(() => { if (this.nodes.length === 0) this.load(); })
      }
      List({ space: 1 }) { ForEach(this.nodes, (node: NodeItem) => { ListItem() { Row() { Text(node.title).fontSize(16).fontColor('#444444'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White).onClick(() => {
        setTimeout(() => {
          if (this.selecting) router.replaceUrl({ url: 'pages/NewTopicPage', params: { nodeCode: node.code, nodeTitle: node.title, title: this.draftTitle, content: this.draftContent } });
          else router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'node', code: node.code, title: node.title } });
        }, 80);
      }); } }, (node: NodeItem) => node.code) }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
