import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { NodeItem } from '../model/NodeItem';

@Entry
@Component
struct NodesPage {
  @State nodes: Array<NodeItem> = [];
  @State selecting: boolean = false;
  @State loading: boolean = true;
  @State draftTitle: string = '';
  @State draftContent: string = '';
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
    try { this.nodes = await GuozaokeService.nodes(); } catch (_) { this.nodes = []; }
    this.loading = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text(this.selecting ? '选择发帖节点' : '节点').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      if (this.loading) { LoadingProgress().margin({ top: 70 }); }
      else if (this.nodes.length === 0) { Text('节点加载失败，点击重试').fontSize(15).fontColor('#7B8794').margin({ top: 70 }).onClick(() => this.load()); }
      List({ space: 1 }) { ForEach(this.nodes, (node: NodeItem) => { ListItem() { Row() { Text(node.title).fontSize(16).fontColor('#444444'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White).onClick(() => {
        if (this.selecting) router.replaceUrl({ url: 'pages/NewTopicPage', params: { nodeCode: node.code, nodeTitle: node.title, title: this.draftTitle, content: this.draftContent } });
        else router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'node', code: node.code, title: node.title } });
      }); } }, (node: NodeItem) => node.code) }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
