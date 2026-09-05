import { router } from '@kit.ArkUI';
import { GuozaokeService } from '../service/GuozaokeService';
import { UserProfile } from '../model/UserProfile';

// Keep the last successfully loaded profile in memory while navigating. The
// persisted self snapshot also survives process restarts, so the page paints
// immediately and refreshes it in the background.
const profileCache: Map<string, UserProfile> = new Map();

@Entry
@Component
struct ProfilePage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @StorageLink('selfProfileCache') selfProfileCache: string = '';
  @State avatar: string = '';
  @State username: string = '';
  @State number: string = '';
  @State since: string = '';
  @State self: boolean = true;
  @State followed: boolean = false;
  @State blocked: boolean = false;
  @State loading: boolean = true;
  @State actionBusy: boolean = false;
  @State status: string = '';
  private requestedSelf: boolean = true;
  private hadCachedProfile: boolean = false;

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.username = params && params.username ? params.username : '';
    } catch (_) {}
    this.requestedSelf = this.username.length === 0;
    this.self = this.requestedSelf;
    if (this.requestedSelf) this.restoreSelfCache();
    const cached: UserProfile | undefined = profileCache.get(this.requestedSelf ? '__self__' : this.username);
    if (cached) {
      this.hadCachedProfile = true;
      this.applyProfile(cached);
      this.loading = false;
    }
    this.load();
  }

  private applyProfile(profile: UserProfile): void {
    this.avatar = profile.avatar;
    this.username = profile.username;
    this.number = profile.number;
    this.since = profile.since;
    this.followed = profile.followed;
    this.blocked = profile.blocked;
  }

  private restoreSelfCache(): void {
    if (this.selfProfileCache.trim().length === 0) return;
    try {
      const data = JSON.parse(this.selfProfileCache) as Record<string, Object>;
      const cached = new UserProfile();
      cached.username = typeof data.username === 'string' ? data.username : '';
      cached.avatar = typeof data.avatar === 'string' ? data.avatar : '';
      cached.number = typeof data.number === 'string' ? data.number : '';
      cached.since = typeof data.since === 'string' ? data.since : '';
      cached.followed = data.followed === true;
      cached.blocked = data.blocked === true;
      if (cached.username.length > 0) {
        profileCache.set('__self__', cached);
        profileCache.set(cached.username, cached);
        this.hadCachedProfile = true;
        this.applyProfile(cached);
        this.loading = false;
      }
    } catch (_) { }
  }

  private persistSelfProfile(profile: UserProfile): void {
    if (!this.requestedSelf || profile.username.length === 0) return;
    try {
      this.selfProfileCache = JSON.stringify({
        username: profile.username,
        avatar: profile.avatar,
        number: profile.number,
        since: profile.since,
        followed: profile.followed,
        blocked: profile.blocked
      });
    } catch (_) { }
  }

  async load(): Promise<void> {
    const selfName = await GuozaokeService.selfUsername();
    if (this.requestedSelf && this.username.length === 0) this.username = selfName;
    this.self = this.requestedSelf || (selfName.length > 0 && this.username === selfName);
    try {
      const profile: UserProfile = await GuozaokeService.userProfile(this.username);
      this.applyProfile(profile);
      profileCache.set(profile.username, profile);
      if (this.requestedSelf) {
        profileCache.set('__self__', profile);
        this.persistSelfProfile(profile);
      }
    } catch (_) {
      if (this.self) this.avatar = await GuozaokeService.selfAvatar();
      if (!this.hadCachedProfile) this.status = '资料加载失败，点击重试';
    }
    this.loading = false;
  }

  private async follow(): Promise<void> {
    if (this.actionBusy || this.self) return;
    this.actionBusy = true;
    try {
      this.followed = await GuozaokeService.toggleFollow(this.username);
      this.status = this.followed ? '关注成功' : '已取消关注';
    } catch (_) { this.status = '操作失败，请稍后重试'; }
    this.actionBusy = false;
  }

  private async block(): Promise<void> {
    if (this.actionBusy || this.self) return;
    this.actionBusy = true;
    try {
      const before = this.blocked;
      this.blocked = await GuozaokeService.toggleBlock(this.username, this.number, before);
      this.status = this.blocked ? '已屏蔽此账号' : '已解除屏蔽';
    } catch (_) { this.status = '操作失败，请稍后重试'; }
    this.actionBusy = false;
  }

  @Builder
  profileBanner() {
    Stack() {
      Row().width('100%').height(112).backgroundColor(this.themeColor)
      Stack() {
        Image($r('app.media.avatar_placeholder')).width(72).height(72).borderRadius(36).objectFit(ImageFit.Cover)
          .border({ width: 3, color: Color.White })
        if (this.avatar.length > 0) {
          Image(this.avatar).width(72).height(72).borderRadius(36).objectFit(ImageFit.Cover)
            .border({ width: 3, color: Color.White })
        }
      }.position({ x: 16, y: 56 })
    }.width('100%').height(140)
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(32).fontColor(Color.White).onClick(() => setTimeout(() => router.back(), 80))
        Text('个人中心').fontSize(20).fontColor(Color.White).fontWeight(FontWeight.Bold).margin({ left: 18 })
        Blank()
      }.width('100%').height(60).flexShrink(0).padding({ left: 16 }).backgroundColor(this.themeColor)
      this.profileBanner()
      Scroll() {
        Column() {
          Column() {
            Text(this.username.length > 0 ? this.username : '过早客用户').fontSize(22).fontColor('#444444')
            Text(this.number.length > 0 ? `${this.number}${this.since.length > 0 ? ` · ${this.since}` : ''}` : (this.self ? '已登录 · guozaoke.com' : 'guozaoke.com'))
              .fontSize(12).fontColor('#999999').margin({ top: 4 })
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 16, top: 10, bottom: 16 })
          if (this.loading) {
            LoadingProgress().width(24).height(24).margin({ bottom: 16 })
          }
          if (this.status.length > 0) {
            Text(this.status).fontSize(13).fontColor(this.status.indexOf('失败') >= 0 ? '#D93025' : this.themeColor)
              .margin({ left: 16, right: 16, bottom: 10 }).onClick(() => {
                if (this.status.indexOf('失败') >= 0) { this.loading = true; this.status = ''; this.load(); }
              })
          }
          this.menuItem(this.self ? '我的收藏' : '收藏', 'favorites')
          this.menuItem(this.self ? '我的主题' : '主题', 'topics')
          this.menuItem(this.self ? '我的回复' : '回复', 'replies')
          if (this.self) {
            Row() { Text('已屏蔽用户').fontSize(16).fontColor('#444444'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }
              .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
              .border({ width: { bottom: 1 }, color: '#E6E6E6' })
              .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/BlockedUsersPage' }), 80))
          }
          if (!this.self && GuozaokeService.isLoggedIn()) {
            Text(this.actionBusy ? '处理中…' : (this.followed ? '取消关注' : '+ 关注')).fontSize(16).fontColor(this.themeColor)
              .width('100%').height(56).textAlign(TextAlign.Center).margin({ top: 12 }).backgroundColor(Color.White)
              .onClick(() => this.follow())
            Text(this.actionBusy ? '处理中…' : (this.blocked ? '解除屏蔽' : '屏蔽此账号')).fontSize(16).fontColor('#7B8794')
              .width('100%').height(56).textAlign(TextAlign.Center).margin({ top: 1 }).backgroundColor(Color.White)
              .onClick(() => this.block())
          }
          if (this.self) {
            Row() { Text('退出登录').fontSize(16).fontColor('#D93025'); Blank(); Text('›').fontSize(24).fontColor('#BBBBBB'); }
              .width('100%').height(56).padding({ left: 16, right: 16 }).margin({ top: 10 }).backgroundColor(Color.White)
              .onClick(() => AlertDialog.show({
                title: '退出登录',
                message: '确定要退出当前账号吗？',
                primaryButton: { value: '取消', action: () => {} },
                secondaryButton: { value: '退出', fontColor: '#D93025', action: () => {
                  GuozaokeService.clearCookies();
                  router.replaceUrl({ url: 'pages/Index' });
                } }
              }))
          }
        }.width('100%').constraintSize({ minHeight: '100%' }).justifyContent(FlexAlign.Start).backgroundColor('#F5F5F5')
      }.layoutWeight(1).width('100%').padding(0).margin(0).backgroundColor(this.themeColor)
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor(this.themeColor)
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }

  @Builder
  menuItem(label: string, kind: string) {
    Row() {
      Text(label).fontSize(16).fontColor('#444444')
      Blank()
      Text('›').fontSize(24).fontColor('#BBBBBB')
    }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E6E6E6' })
      .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind, username: this.username } }), 80))
  }
}
