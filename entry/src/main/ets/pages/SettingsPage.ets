import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { applySystemTheme, BLUE_THEME_COLOR, DEFAULT_THEME_COLOR, normalizeThemeColor, PINK_THEME_COLOR } from '../util/ThemeUtil';

@Entry
@Component
struct SettingsPage {
  @StorageLink('commentsOrderDesc') desc: boolean = false;
  @StorageLink('imageBedApiKey') apiKey: string = '';
  @StorageLink('themeColor') themeColor: string = DEFAULT_THEME_COLOR;
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State customColor: string = '';
  @State themeMessage: string = '';

  aboutToAppear(): void {
    this.customColor = this.themeColor;
  }

  private applyTheme(value: string): void {
    const color: string = normalizeThemeColor(value);
    if (color.length === 0) {
      this.themeMessage = '请输入 6 位十六进制颜色，例如 #51A775';
      return;
    }
    this.themeColor = color;
    this.customColor = color;
    this.themeMessage = '主题已应用';
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    applySystemTheme(context, color).catch(() => this.themeMessage = '主题已保存，系统栏将在下次启动后更新');
    setTimeout(() => { if (this.themeMessage === '主题已应用') this.themeMessage = ''; }, 1800);
  }

  private async openImageBedHelp(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        uri: 'https://smms.app/'
      });
    } catch (_) {}
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => setTimeout(() => router.back(), 80)); Text('设置').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      Row() {
        Column() {
          Text('评论按时间倒序').fontSize(16).fontColor('#444444')
          Text(this.desc ? '已开启 · 最新回复显示在前' : '已关闭 · 最早回复显示在前').fontSize(12).fontColor('#999999').margin({ top: 3 })
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.desc }).selectedColor(this.themeColor).onChange((v: boolean) => this.desc = v)
      }
        .width('100%').height(60).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
      Column() {
        Text('主题颜色').fontSize(16).fontColor('#444444').width('100%')
        Text('同步应用到页面强调色、状态栏和导航栏').fontSize(12).fontColor('#999999').width('100%').margin({ top: 3, bottom: 14 })
        Row() {
          this.themeOption(DEFAULT_THEME_COLOR, '青绿')
          this.themeOption(PINK_THEME_COLOR, '樱粉')
          this.themeOption(BLUE_THEME_COLOR, '天蓝')
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)
        Row() {
          TextInput({ placeholder: '#51A775', text: this.customColor }).layoutWeight(1).height(42)
            .fontColor('#3C4043').placeholderColor('#A0A5AB').backgroundColor('#F5F6F8').borderRadius(8)
            .onChange((value: string) => this.customColor = value)
          Button('应用').width(72).height(38).fontSize(14).margin({ left: 10 }).backgroundColor(this.themeColor)
            .onClick(() => this.applyTheme(this.customColor))
        }.width('100%').margin({ top: 14 })
        if (this.themeMessage.length > 0) {
          Text(this.themeMessage).fontSize(12).fontColor(this.themeMessage.indexOf('请输入') >= 0 ? '#D93025' : this.themeColor)
            .width('100%').margin({ top: 8 })
        }
      }.width('100%').padding(16).margin({ top: 10 }).backgroundColor(Color.White)
      Row() { Text('图床 API Key').fontSize(16).fontColor('#444444'); Blank(); Text(this.apiKey.length > 0 ? '已设置' : '未设置').fontSize(14).fontColor('#999999'); Text('›').fontSize(24).fontColor('#BBBBBB').margin({ left: 8 }); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
        .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/SettingsEditPage' }), 80))
      Row() { Text('如何获取图床 API Key').fontSize(16).fontColor('#444444'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }
        .width('100%').height(60).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
        .border({ width: { top: 1 }, color: '#ECEEF0' }).onClick(() => this.openImageBedHelp())
      Text('用于上传主题图片的图床配置').fontSize(12).fontColor('#999999').margin({ top: 10, left: 16, right: 16 })
      Blank()
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }

  @Builder
  themeOption(color: string, label: string) {
    Column() {
      Stack() {
        Row().width(36).height(36).borderRadius(18).backgroundColor(color)
        if (this.themeColor === color) { Text('✓').fontSize(18).fontColor(Color.White).fontWeight(FontWeight.Bold) }
      }.width(44).height(44)
      Text(label).fontSize(12).fontColor(this.themeColor === color ? color : '#7B8794').margin({ top: 3 })
    }.width('30%').onClick(() => this.applyTheme(color))
  }
}
