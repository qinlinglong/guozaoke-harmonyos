import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct NotificationsPage {
  @State items: Array<string> = [];
  aboutToAppear(): void { this.load(); }
  async load(): Promise<void> { try { this.items = await GuozaokeService.notifications(); } catch (_) { this.items = []; } }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('通知').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      if (this.items.length === 0) { Text('暂无通知').fontSize(16).fontColor('#999999').margin({ top: 80 }); }
      List({ space: 1 }) { ForEach(this.items, (item: string, index: number) => { ListItem() { Text(item).fontSize(15).fontColor('#444444').width('100%').padding(16).backgroundColor(Color.White); } }, (_: string, index: number) => `${index}`) }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
