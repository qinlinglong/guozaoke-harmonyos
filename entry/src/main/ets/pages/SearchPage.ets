import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { UserProfile } from '../model/UserProfile';

@Entry
@Component
struct SearchPage {
  @State query: string = '';
  @State loading: boolean = false;
  @State message: string = '';
  async search(): Promise<void> {
    if (this.loading) return;
    const keyword = this.query.trim();
    if (keyword.length === 0) { this.message = '请输入用户 ID'; return; }
    this.loading = true;
    this.message = '';
    try {
      const profile: UserProfile = await GuozaokeService.userProfile(keyword);
      if (profile.avatar.length > 0 && profile.username.length > 0) {
        router.pushUrl({ url: 'pages/ProfilePage', params: { username: profile.username } });
      } else this.message = '未找到该用户';
    } catch (_) { this.message = '搜索失败，请稍后重试'; }
    this.loading = false;
  }
  build() {
    Column() {
      Row() { Text('‹').fontSize(32).fontColor('#258DF5').onClick(() => router.back()); Text('搜索用户').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 18 }); }
        .width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(Color.White)
      TextInput({ placeholder: '请输入用户 ID', text: this.query }).fontColor('#444444').placeholderColor('#999999').onChange((v: string) => this.query = v)
        .enterKeyType(EnterKeyType.Search).onSubmit(() => this.search())
        .width('92%').height(48).margin({ top: 16 })
      Button(this.loading ? '搜索中…' : '搜索').width('92%').height(44).margin({ top: 12 }).backgroundColor('#258DF5')
        .enabled(!this.loading).onClick(() => this.search())
      if (this.loading) { LoadingProgress().margin({ top: 40 }); }
      if (this.message.length > 0) { Text(this.message).fontSize(14).fontColor('#7B8794').margin({ top: 24 }); }
      Blank()
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
