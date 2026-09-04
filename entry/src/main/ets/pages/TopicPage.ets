import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { GuozaokeService } from '../service/GuozaokeService';

interface TopicParams {
  id: string;
  title: string;
}

@Entry
@Component
struct TopicPage {
  @State title: string = '主题详情';
  @State content: string = '加载中…';
  @State loading: boolean = true;
  @State topicUrl: string = 'https://www.guozaoke.com/';
  controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    const params: TopicParams = router.getParams() as TopicParams;
    this.title = params && params.title ? params.title : '主题详情';
    this.topicUrl = params && params.id ? `https://www.guozaoke.com/t/${params.id}` : 'https://www.guozaoke.com/';
    this.loading = false;
  }

  async load(id: string): Promise<void> {
    try {
      this.content = await GuozaokeService.topicDetail(id);
    } catch (_) {
      this.content = '加载失败，请返回重试';
    }
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor('#1677C8').onClick(() => router.back())
        Text('主题详情').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 })
        Blank()
        Text('分享').fontSize(14).fontColor('#1677C8')
      }.width('100%').height(60).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      Web({ src: this.topicUrl, controller: this.controller })
        .javaScriptAccess(true).domStorageAccess(true)
        // Some redesigned pages still reference the old static host. Replace failed
        // image requests so the detail page never shows broken-image placeholders.
        .runJavaScriptOnDocumentEnd([{
          script: `document.querySelectorAll('img').forEach(function(i){i.addEventListener('error',function(){if(!i.dataset.guozaokeFallback){i.dataset.guozaokeFallback='1';i.src='https://static.guozaoke.com/static/avatar/m_default.gif';}});});`,
          scriptRules: ['*']
        }])
        .layoutWeight(1).width('100%')
    }.width('100%').height('100%')
      .backgroundColor('#F5F7FA')
  }
}
