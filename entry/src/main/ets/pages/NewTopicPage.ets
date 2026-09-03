import { router } from '@kit.ArkUI';

@Entry @Component
struct NewTopicPage {
  @State title: string = ''; @State body: string = '';
  build() { Column({ space: 16 }) { Row() { Text('‹ 返回').onClick(() => router.back()); Text('发表主题').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 24 }); }.width('100%').height(56).padding({ left: 16 }); TextInput({ placeholder: '主题标题' }).width('92%').onChange((v: string) => this.title = v); TextArea({ placeholder: '主题内容' }).layoutWeight(1).width('92%').onChange((v: string) => this.body = v); Button('发表').width('80%').onClick(() => router.back()); }.width('100%').height('100%').padding({ bottom: 20 }); }
}
