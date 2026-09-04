import { router } from '@kit.ArkUI';

@Entry
@Component
struct SettingsEditPage {
  @StorageLink('imageBedApiKey') apiKey: string = '';
  @State draft: string = '';

  aboutToAppear(): void {
    this.draft = this.apiKey;
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back())
        Text('图床 API Key').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 })
        Blank()
        Text('保存').fontSize(16).fontColor('#258DF5').margin({ right: 18 }).onClick(() => {
          this.apiKey = this.draft.trim();
          router.back();
        })
      }.width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      TextInput({ placeholder: '请输入 API Key', text: this.draft })
        .type(InputType.Password).showPasswordIcon(true).onChange((value: string) => this.draft = value)
        .width('92%').height(48).margin({ top: 18 }).backgroundColor(Color.White)
      Text('API Key 仅保存在本机，用于后续图片上传功能。留空保存可清除。')
        .fontSize(13).fontColor('#7B8794').width('92%').margin({ top: 12 })
      Blank()
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
