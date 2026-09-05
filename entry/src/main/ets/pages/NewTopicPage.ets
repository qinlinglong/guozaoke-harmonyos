import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { GuozaokeService } from '../service/GuozaokeService';

@Entry
@Component
struct NewTopicPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State title: string = '';
  @State content: string = '';
  @State submitted: boolean = false;
  @State status: string = '';
  @State nodeCode: string = '';
  @State nodeTitle: string = '';
  @State submitting: boolean = false;
  @StorageLink('imageBedApiKey') apiKey: string = '';
  @State uploading: boolean = false;
  @State editId: string = '';
  @State editing: boolean = false;
  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.nodeCode = params && params.nodeCode ? params.nodeCode : '';
      this.nodeTitle = params && params.nodeTitle ? params.nodeTitle : '';
      this.title = params && params.title ? params.title : this.title;
      this.content = params && params.content ? params.content : this.content;
      this.editId = params && params.editId ? params.editId : '';
      this.editing = this.editId.length > 0 || params.edit === '1';
    } catch (_) {}
  }
  private async openMarkdownHelp(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: 'https://github.github.com/gfm/' });
    } catch (_) { this.status = '无法打开 Markdown 帮助'; }
  }

  private async chooseAndUploadImage(): Promise<void> {
    if (this.uploading) return;
    if (this.apiKey.trim().length === 0) { this.status = '请先到设置里添加 sm.ms 图床 API Key'; return; }
    this.uploading = true;
    this.status = '正在选择图片…';
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) { this.status = '无法打开系统图片选择器'; this.uploading = false; return; }
      const viewPicker = new picker.PhotoViewPicker(context as common.UIAbilityContext);
      const result = await viewPicker.select({ MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1 });
      const uri = result.photoUris.length > 0 ? result.photoUris[0] : '';
      if (uri.length === 0) { this.status = ''; this.uploading = false; return; }
      this.status = '正在上传图片…';
      const url = await GuozaokeService.uploadImage(uri, this.apiKey);
      if (url.length === 0) { this.status = '图片上传失败，请检查 sm.ms API Key'; this.uploading = false; return; }
      const markdown = `[![](${url})](${url})`;
      this.content = this.content.trim().length > 0 ? `${this.content.trim()}\n${markdown}` : markdown;
      this.status = '图片已插入';
    } catch (_) { this.status = '已取消选择图片'; }
    this.uploading = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => setTimeout(() => router.back(), 80)); Text(this.editing ? '编辑主题' : '发表主题').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); Blank(); Text(this.uploading ? '上传中…' : '图片').fontSize(14).fontColor(this.uploading ? '#A0A5AB' : this.themeColor).margin({ right: 14 }).onClick(() => this.chooseAndUploadImage()); Text(this.submitting ? (this.editing ? '保存中…' : '发布中…') : (this.editing ? '保存' : '发布')).fontSize(16).fontColor(this.submitting ? '#A0A5AB' : this.themeColor).onClick(async () => {
        if (this.submitting) return;
        if (!this.editing && this.nodeCode.length === 0) { this.status = '请先选择节点'; return; }
        if (this.title.trim().length < 3 || this.content.trim().length < 3) { this.status = '标题和内容至少需要 3 个字符'; return; }
        this.submitting = true; this.status = '';
        try {
          const ok = this.editing
            ? await GuozaokeService.editTopic(this.editId, this.title.trim(), this.content.trim())
            : await GuozaokeService.newTopic(this.nodeCode, this.title.trim(), this.content.trim());
          if (ok) {
            this.status = this.editing ? '保存成功' : '发布成功'; setTimeout(() => router.back(), 500);
          } else this.status = this.editing ? '保存失败，请稍后重试' : '发布失败，请稍后重试';
        } catch (_) { this.status = this.editing ? '保存失败，请稍后重试' : '发布失败，请稍后重试'; }
        this.submitting = false;
      }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      if (!this.editing) {
        Row() { Text('发布到').fontSize(14).fontColor('#7B8794'); Text(this.nodeTitle.length > 0 ? this.nodeTitle : '未选择节点').fontSize(15).fontColor(this.themeColor).margin({ left: 10 }); Blank(); Text('更换 ›').fontSize(14).fontColor(this.themeColor); }
          .width('92%').height(48).onClick(() => setTimeout(() => router.replaceUrl({ url: 'pages/NodesPage', params: { select: '1', draftTitle: this.title, draftContent: this.content } }), 80))
      }
      Text() {
        Span('Tips：编辑器支持 GFM Markdown，可在文字两侧各加两个星号以加粗：')
        Span('**文字**').fontWeight(FontWeight.Bold)
        Span('。更多功能请参考').fontColor(this.themeColor).decoration({ type: TextDecorationType.Underline, color: this.themeColor })
          .onClick(() => this.openMarkdownHelp())
      }.fontSize(12).fontColor('#7B8794').lineHeight(18).width('92%').margin({ top: 4 })
      TextInput({ placeholder: '请输入标题', text: this.title }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.title = v).fontSize(20).fontWeight(FontWeight.Bold)
        .width('92%').height(52).margin({ top: 16 })
      TextArea({ placeholder: '请输入内容', text: this.content }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.content = v)
        .width('92%').layoutWeight(1).margin({ top: 16, bottom: 12 }).fontSize(16).backgroundColor('#F7F8FA').borderRadius(8).padding(12)
      if (this.status.length > 0) { Text(this.status).fontSize(13).fontColor('#999999').margin({ bottom: 12 }); }
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor(Color.White)
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
