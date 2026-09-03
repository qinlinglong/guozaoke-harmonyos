import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry @Component
struct NodesPage {
  @State nodes: Array<string> = []; @State message: string = '加载中…';
  aboutToAppear(): void { this.load(); }
  async load(): Promise<void> { try { this.nodes = await GuozaokeService.nodes(); this.message = this.nodes.length ? '' : '暂无节点'; } catch (_) { this.message = '加载失败'; } }
  build() {
    Column() {
      Row() { Text('‹ 返回').onClick(() => router.back()); Text('节点').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 }); }.width('100%').height(56).padding({ left: 16 });
      if (this.message.length > 0) { Text(this.message).margin({ top: 48 }); } else {
        List({ space: 1 }) { ForEach(this.nodes, (node: string) => ListItem() { Text(node).width('100%').padding(16).backgroundColor(Color.White).onClick(() => router.pushUrl({ url: 'pages/Index', params: { tab: node } })); }, (node: string) => node); }.layoutWeight(1).width('100%');
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5');
  }
}
