import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

const PROJECT_URL: string = 'https://github.com/qinlinglong/guozaoke-harmonyos';

@Entry
@Component
struct AboutPage {
  @State status: string = '';

  private notify(message: string): void {
    this.status = message;
    setTimeout(() => { if (this.status === message) this.status = ''; }, 2200);
  }

  private async openExternal(url: string): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: url });
    } catch (_) { this.notify('无法打开链接'); }
  }

  private async copyProjectLink(): Promise<void> {
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, PROJECT_URL);
      await pasteboard.getSystemPasteboard().setData(data);
      this.notify('项目地址已复制');
    } catch (_) { this.notify('复制失败'); }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#258DF5').width(44).textAlign(TextAlign.Center).onClick(() => router.back())
        Text('关于过早客').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 8 })
      }.width('100%').height(60).flexShrink(0).padding({ left: 8 }).backgroundColor(Color.White)
      Scroll() {
        Column() {
          Column() {
            Image($r('app.media.pixel_icon')).width(84).height(84).borderRadius(18).margin({ bottom: 14 })
            Text('过早客').fontSize(23).fontWeight(FontWeight.Bold).fontColor('#30343B')
            Text('HarmonyOS 原生客户端 · v1.0.0').fontSize(13).fontColor('#7B8794').margin({ top: 7 })
            Text('社区内容与账号服务来自 guozaoke.com').fontSize(12).fontColor('#9AA0A6').margin({ top: 5 })
          }.width('100%').height(230).justifyContent(FlexAlign.Center)
          this.actionRow('检查新版本', '前往 GitHub Releases', () => this.openExternal(`${PROJECT_URL}/releases`))
          this.actionRow('建议与反馈', '提交 Issue', () => this.openExternal(`${PROJECT_URL}/issues`))
          this.actionRow('分享给好友', '复制项目地址', () => this.copyProjectLink())
          this.actionRow('隐私与政策', '查看隐私说明', () => this.openExternal(`${PROJECT_URL}#privacy`))
          this.actionRow('获取源代码', 'qinlinglong/guozaoke-harmonyos', () => this.openExternal(PROJECT_URL))
          if (this.status.length > 0) {
            Text(this.status).fontSize(13).fontColor('#258DF5').margin({ top: 18 })
          }
        }.width('100%').alignItems(HorizontalAlign.Center).padding({ bottom: 24 })
      }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  actionRow(title: string, detail: string, action: () => void) {
    Row() {
      Column() {
        Text(title).fontSize(16).fontColor('#3C4043')
        Text(detail).fontSize(12).fontColor('#9AA0A6').margin({ top: 3 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Text('›').fontSize(24).fontColor('#A0A5AB')
    }.width('100%').height(64).padding({ left: 20, right: 18 }).backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#ECEEF0' }).onClick(action)
  }
}
