import { router } from '@kit.ArkUI';

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back())
        Text('关于过早客').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 })
      }.width('100%').height(60).padding({ left: 16 }).backgroundColor(Color.White)
      Column() {
        Image($r('app.media.pixel_icon')).width(88).height(88).borderRadius(20).margin({ bottom: 16 })
        Text('过早客').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#30343B')
        Text('HarmonyOS 原生客户端').fontSize(14).fontColor('#7B8794').margin({ top: 8 })
        Text('版本 1.0.0').fontSize(13).fontColor('#9AA0A6').margin({ top: 4 })
        Text('社区内容与账号服务来自 guozaoke.com').fontSize(13).fontColor('#7B8794').margin({ top: 28 })
      }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
