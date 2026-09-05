import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { UserProfile } from '../model/UserProfile';
import { Topic } from '../model/Topic';
import { TopicListResult } from '../model/TopicListResult';

@Entry
@Component
struct SearchPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State query: string = '';
  @State mode: string = 'topics';
  @State loading: boolean = false;
  @State message: string = '';
  @State topics: Array<Topic> = [];
  async search(): Promise<void> {
    if (this.loading) return;
    const keyword = this.query.trim();
    if (keyword.length === 0) { this.message = this.mode === 'users' ? '请输入用户 ID' : '请输入帖子关键词'; return; }
    this.loading = true;
    this.message = '';
    this.topics = [];
    try {
      if (this.mode === 'users') {
        const profile: UserProfile = await GuozaokeService.userProfile(keyword);
        if (profile.avatar.length > 0 && profile.username.length > 0) {
          router.pushUrl({ url: 'pages/ProfilePage', params: { username: profile.username } });
        } else this.message = '未找到该用户';
      } else {
        const result: TopicListResult = await GuozaokeService.searchTopics(keyword);
        this.topics = result.topics;
        if (this.topics.length === 0) this.message = '未找到相关主题';
      }
    } catch (_) { this.message = '搜索失败，请稍后重试'; }
    this.loading = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor(this.themeColor).onClick(() => setTimeout(() => router.back(), 80)); Text('搜索').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      Row() {
        Text('帖子').fontSize(15).fontColor(this.mode === 'topics' ? this.themeColor : '#7B8794').width('50%').textAlign(TextAlign.Center)
          .padding({ top: 11, bottom: 11 }).backgroundColor(this.mode === 'topics' ? '#E8F5EE' : Color.White)
          .borderRadius(8).onClick(() => { this.mode = 'topics'; this.message = ''; this.topics = []; })
        Text('用户').fontSize(15).fontColor(this.mode === 'users' ? this.themeColor : '#7B8794').width('50%').textAlign(TextAlign.Center)
          .padding({ top: 11, bottom: 11 }).backgroundColor(this.mode === 'users' ? '#E8F5EE' : Color.White)
          .borderRadius(8).onClick(() => { this.mode = 'users'; this.message = ''; this.topics = []; })
      }.width('92%').height(46).margin({ top: 14 }).padding(3).backgroundColor(Color.White).borderRadius(10)
      TextInput({ placeholder: this.mode === 'users' ? '请输入用户 ID' : '请输入帖子标题或正文关键词', text: this.query }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.query = v)
        .enterKeyType(EnterKeyType.Search).onSubmit(() => this.search())
        .width('92%').height(48).margin({ top: 16 })
      Button(this.loading ? '搜索中…' : '搜索').width('92%').height(44).margin({ top: 12 }).backgroundColor(this.themeColor)
        .enabled(!this.loading).onClick(() => this.search())
      if (this.loading) { LoadingProgress().margin({ top: 40 }); }
      if (this.message.length > 0) { Text(this.message).fontSize(14).fontColor('#7B8794').margin({ top: 24 }); }
      if (this.mode === 'topics' && this.topics.length > 0) {
        Scroll() {
          Column() {
            ForEach(this.topics, (topic: Topic) => {
              Column() {
                Row() {
                  Text(topic.author).fontSize(12).fontColor('#7B8794')
                  Blank()
                  Text(topic.node).fontSize(12).fontColor('#A0A5AB')
                }.width('100%')
                Text(topic.title).fontSize(16).fontColor('#3C4043').lineHeight(22).maxLines(2).margin({ top: 8 })
                Text(`${topic.replies} 回复`).fontSize(12).fontColor('#A0A5AB').margin({ top: 8 })
              }.width('100%').padding(16).backgroundColor(Color.White).margin({ bottom: 1 })
                .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/TopicPage', params: { id: topic.id, title: topic.title } }), 80))
            }, (topic: Topic) => topic.id)
          }.width('100%')
        }.layoutWeight(1).width('100%').margin({ top: 18 })
      } else {
        Blank()
      }
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
