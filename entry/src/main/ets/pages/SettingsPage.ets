import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct SettingsPage {
  @StorageLink('commentsOrderDesc') desc: boolean = false;
  @StorageLink('imageBedApiKey') apiKey: string = '';

  private async openImageBedHelp(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        uri: 'https://github.com/qinlinglong/guozaoke-harmonyos#image-hosting'
      });
    } catch (_) {}
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('设置').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      Row() {
        Column() {
          Text('评论按时间倒序').fontSize(16).fontColor('#444444')
          Text(this.desc ? '已开启 · 最新回复显示在前' : '已关闭 · 最早回复显示在前').fontSize(12).fontColor('#999999').margin({ top: 3 })
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.desc }).onChange((v: boolean) => this.desc = v)
      }
        .width('100%').height(60).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
      Row() { Text('图床 API Key').fontSize(16).fontColor('#444444'); Blank(); Text(this.apiKey.length > 0 ? '已设置' : '未设置').fontSize(14).fontColor('#999999'); Text('›').fontSize(24).fontColor('#BBBBBB').margin({ left: 8 }); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
        .onClick(() => router.pushUrl({ url: 'pages/SettingsEditPage' }))
      Row() { Text('如何获取图床 API Key').fontSize(16).fontColor('#444444'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
        .border({ width: { top: 1 }, color: '#ECEEF0' }).onClick(() => this.openImageBedHelp())
      Text('用于上传主题图片的图床配置').fontSize(12).fontColor('#999999').margin({ top: 10, left: 16, right: 16 })
      Blank()
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
