import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { GuozaokeService } from '../service/GuozaokeService';
import { setEditingKeepScreenOn } from '../util/ThemeUtil';

class PreviewPart {
  kind: string = 'text';
  value: string = '';
  constructor(kind: string, value: string) {
    this.kind = kind;
    this.value = value;
  }
}

function isPreviewImageUrl(value: string): boolean {
  return /\.(?:png|jpe?g|gif|webp|bmp|svg)(?:[?#].*)?$/i.test(value)
    || /(?:article\.biliimg\.com|bfs\/new_dyn|static\.guozaoke\.com)/i.test(value);
}

function previewParts(value: string): Array<PreviewPart> {
  const parts: Array<PreviewPart> = [];
  // Support the uploader's linked-image form `[![](url)](url)` as well as
  // ordinary Markdown `![alt](url)`, keeping surrounding text in place.
  const pattern = /\[\s*!\[\]\((https?:\/\/[^)\s]+)\)\]\((?:https?:\/\/[^)\s]+)\)|!\[[^\]]*\]\((https?:\/\/[^)\s]+)\)|\[[^\]]*\]\((https?:\/\/[^)\s]+)\)/gi;
  let cursor: number = 0;
  let match: RegExpExecArray | null = pattern.exec(value);
  while (match) {
    const before: string = value.substring(cursor, match.index);
    const imageUrl: string = match[1] || match[2] || match[3];
    if (!isPreviewImageUrl(imageUrl)) {
      if (before.trim().length > 0) parts.push(new PreviewPart('text', before.trim()));
      parts.push(new PreviewPart('text', match[0]));
      cursor = match.index + match[0].length;
      match = pattern.exec(value);
      continue;
    }
    if (before.trim().length > 0) parts.push(new PreviewPart('text', before.trim()));
    parts.push(new PreviewPart('image', imageUrl));
    cursor = match.index + match[0].length;
    match = pattern.exec(value);
  }
  const tail: string = value.substring(cursor).trim();
  if (tail.length > 0) parts.push(new PreviewPart('text', tail));
  if (parts.length === 0 && value.trim().length > 0) parts.push(new PreviewPart('text', value.trim()));
  return parts;
}

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
  @State previewing: boolean = false;
  aboutToAppear(): void {
    this.setKeepScreenOn(true);
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
  aboutToDisappear(): void {
    this.setKeepScreenOn(false);
  }
  private setKeepScreenOn(enabled: boolean): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      setEditingKeepScreenOn(context, enabled);
    } catch (_) { }
  }
  private async openMarkdownHelp(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: 'https://github.github.com/gfm/' });
    } catch (_) { this.status = '无法打开 Markdown 帮助'; }
  }

  private async submitTopic(): Promise<void> {
    if (this.submitting) return;
    if (!this.editing && this.nodeCode.length === 0) { this.status = '请先选择节点'; return; }
    if (this.title.trim().length < 3 || this.content.trim().length < 3) { this.status = '标题和内容至少需要 3 个字符'; return; }
    this.submitting = true; this.status = '';
    try {
      const ok = this.editing
        ? await GuozaokeService.editTopic(this.editId, this.title.trim(), this.content.trim())
        : await GuozaokeService.newTopic(this.nodeCode, this.title.trim(), this.content.trim());
      if (ok) {
        this.status = this.editing ? '保存成功' : '发布成功';
        setTimeout(() => router.back(), 500);
      } else this.status = this.editing ? '保存失败，请稍后重试' : '发布失败，请稍后重试';
    } catch (_) { this.status = this.editing ? '保存失败，请稍后重试' : '发布失败，请稍后重试'; }
    this.submitting = false;
  }

  private async chooseAndUploadImage(): Promise<void> {
    if (this.uploading) return;
    if (!GuozaokeService.biliLoggedIn() && this.apiKey.trim().length === 0) { this.status = '请先配置 sm.ms 或登录 Bilibili 图床'; return; }
    this.uploading = true;
    this.status = '正在选择图片…';
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) { this.status = '无法打开系统图片选择器'; this.uploading = false; return; }
      const viewPicker = new picker.PhotoViewPicker(context as common.UIAbilityContext);
      const result = await viewPicker.select({ MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 9 });
      if (result.photoUris.length === 0) { this.status = ''; this.uploading = false; return; }
      // sm.ms is the default bed; Bilibili is used when sm.ms has not been configured.
      const useBili = this.apiKey.trim().length === 0 && GuozaokeService.biliLoggedIn();
      const markdown: Array<string> = [];
      for (let index = 0; index < result.photoUris.length; index++) {
        this.status = `正在上传图片 ${index + 1}/${result.photoUris.length}…`;
        const uri: string = result.photoUris[index];
        const url = useBili ? await GuozaokeService.uploadBilibiliImage(uri) : await GuozaokeService.uploadImage(uri, this.apiKey);
        if (url.length > 0) markdown.push(`[![](${url})](${url})`);
      }
      if (markdown.length === 0) { this.status = useBili ? 'Bilibili 图片上传失败，请重新登录' : '图片上传失败，请检查 sm.ms API Key'; this.uploading = false; return; }
      const inserted: string = markdown.join('\n');
      this.content = this.content.trim().length > 0 ? `${this.content.trim()}\n\n${inserted}` : inserted;
      this.status = markdown.length === result.photoUris.length ? `已插入 ${markdown.length} 张图片` : `已插入 ${markdown.length} 张，部分上传失败`;
    } catch (_) { this.status = '已取消选择图片'; }
    this.uploading = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => setTimeout(() => router.back(), 80)); Text(this.editing ? '编辑主题' : '发表主题').fontSize(20).fontColor('#444444').fontWeight(FontWeight.Bold).margin({ left: 18 }); Blank();
        Image($r('app.media.ic_image')).width(22).height(22).fillColor(this.uploading ? '#A0A5AB' : this.themeColor).margin({ right: 16 }).onClick(() => this.chooseAndUploadImage());
        Image($r('app.media.ic_preview')).width(22).height(22).fillColor(this.themeColor).margin({ right: 16 }).onClick(() => this.previewing = true);
        Image($r('app.media.ic_save')).width(22).height(22).fillColor(this.submitting ? '#A0A5AB' : this.themeColor).id('topicSubmit').onClick(() => this.submitTopic()); }
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
      if (this.previewing) {
        Column() {
          Row() { Text('预览').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333'); Blank(); Image($r('app.media.ic_edit')).width(22).height(22).fillColor(this.themeColor).onClick(() => this.previewing = false); }
            .width('100%').height(56).padding({ left: 18, right: 18 }).backgroundColor(Color.White)
          Scroll() {
            Column() {
              Text(this.title.trim()).fontSize(21).fontWeight(FontWeight.Bold).fontColor('#202124').width('100%').margin({ bottom: 14 })
              Text(this.nodeTitle.length > 0 ? this.nodeTitle : '未选择节点').fontSize(12).fontColor(this.themeColor).width('100%').margin({ bottom: 18 })
              ForEach(previewParts(this.content), (part: PreviewPart, index: number) => {
                if (part.kind === 'image') {
                  Image(part.value).width('100%').height(220).objectFit(ImageFit.Contain).margin({ top: 12, bottom: 12 }).borderRadius(6).backgroundColor('#F7F8FA')
                } else {
                  Text(part.value).fontSize(16).lineHeight(25).fontColor('#3C4043').width('100%').textSelectable(TextSelectableMode.SELECTABLE_FOCUSABLE).margin({ bottom: 10 })
                }
              }, (part: PreviewPart, index: number) => `${index}-${part.kind}-${part.value}`)
            }.width('100%').padding(20)
          }.layoutWeight(1).width('100%')
          Row() {
            Button('返回编辑').layoutWeight(1).height(44).fontColor(this.themeColor).backgroundColor('#E8F5EE').onClick(() => this.previewing = false)
            Button(this.editing ? '确认保存' : '确认发布').layoutWeight(1).height(44).fontColor(Color.White).backgroundColor(this.themeColor).margin({ left: 12 }).onClick(() => { this.previewing = false; this.submitTopic(); })
          }.width('100%').padding(14).backgroundColor(Color.White)
        }.width('100%').height('100%').position({ x: 0, y: 0 }).zIndex(20).backgroundColor('#F5F5F5')
      }
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor(Color.White)
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
