import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry @Component
struct NotificationsPage {
  @State items: Array<string> = []; @State message: string = '加载中…';
  aboutToAppear(): void { this.load(); }
  async load(): Promise<void> { try { this.items = await GuozaokeService.notifications(); this.message = this.items.length ? '' : '暂无通知'; } catch (_) { this.message = '加载失败'; } }
  build() { Column() { Row() { Text('‹ 返回').onClick(() => router.back()); Text('通知').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 }); }.width('100%').height(56).padding({ left: 16 }); if (this.message.length > 0) Text(this.message).margin({ top: 48 }); else List() { ForEach(this.items, (item: string) => ListItem() { Text(item).padding(16).width('100%').backgroundColor(Color.White); }, (item: string) => item); }.layoutWeight(1).width('100%'); }.width('100%').height('100%').backgroundColor('#F5F5F5'); }
}
