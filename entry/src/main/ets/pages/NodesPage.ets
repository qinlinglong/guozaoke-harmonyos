import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct NodesPage {
  @State nodes: Array<string> = [];
  aboutToAppear(): void { this.load(); }
  async load(): Promise<void> { try { this.nodes = await GuozaokeService.nodes(); } catch (_) { this.nodes = []; } }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('节点').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      List({ space: 1 }) { ForEach(this.nodes, (node: string) => { ListItem() { Row() { Text(node).fontSize(16).fontColor('#444444'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White).onClick(() => router.pushUrl({ url: 'pages/Index', params: { tab: 'node=' + encodeURIComponent(node) } })); } }) }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
