import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { picker } from '@kit.CoreFileKit';
import { GuozaokeService } from '../service/GuozaokeService';
import { CommentItem } from '../model/CommentItem';
import { TopicDetailData } from '../model/TopicDetailData';
import { ContentPart } from '../model/ContentPart';
import { CommentListResult } from '../model/CommentListResult';

function emojiAlias(name: string): string {
  switch (name.toLowerCase()) {
    case '+1': case 'thumbsup': return '👍'; case '-1': case 'thumbsdown': return '👎'; case '100': return '💯';
    case 'angel': return '😇'; case 'anger': case 'angry': return '😠'; case 'beer': return '🍺';
    case 'joy': return '😂'; case 'laugh': return '😆'; case 'smile': return '😄'; case 'grin': return '😁';
    case 'blush': return '😊'; case 'wink': return '😉'; case 'heart': return '❤️'; case 'love': case 'heart_eyes': return '😍';
    case 'kiss': return '😘'; case 'cry': return '😢'; case 'sob': return '😭';
    case 'boom': return '💥'; case 'bow': return '🙇'; case 'broken_heart': return '💔'; case 'clap': return '👏';
    case 'cold_sweat': return '😰'; case 'scream': return '😱'; case 'confounded': case 'confused': return '😕';
    case 'thinking': return '🤔'; case 'sweat': return '😓'; case 'neutral': return '😐'; case 'sleep': case 'zzz': return '😴';
    case 'cool': return '😎'; case 'cow': return '🐮'; case 'dog': return '🐶'; case 'eggplant': return '🍆';
    case 'eyes': return '👀'; case 'flushed': return '😳'; case 'ghost': return '👻'; case 'gun': return '🔫';
    case 'kissing_heart': return '😘'; case 'laughing': return '😆'; case 'mask': return '😷'; case 'moneybag': return '💰';
    case 'muscle': return '💪'; case 'ng': return '🙅'; case 'octocat': return '🐙'; case 'ok_hand': return '👌';
    case 'paw_prints': return '🐾'; case 'pig': return '🐷'; case 'pill': return '💊'; case 'pray': return '🙏';
    case 'santa': return '🎅'; case 'shit': case 'poop': return '💩'; case 'smirk': return '😏'; case 'sos': return '🆘';
    case 'sparkles': return '✨'; case 'stuck_out_tongue_winking_eye': return '😜'; case 'swimmer': return '🏊';
    case 'trollface': return '🤪'; case 'underage': return '🔞'; case 'v': return '✌️'; case 'vs': return '🆚';
    case 'watermelon': return '🍉'; case 'star': return '⭐'; case 'tada': return '🎉'; case 'fire': return '🔥';
    default: return '';
  }
}

function emojiCode(value: string): string {
  switch (value) {
    case '👍': return '+1'; case '👎': return '-1'; case '💯': return '100'; case '😇': return 'angel';
    case '😠': return 'anger'; case '🍺': return 'beer'; case '💥': return 'boom'; case '🙇': return 'bow';
    case '💔': return 'broken_heart'; case '😰': return 'cold_sweat'; case '🐮': return 'cow'; case '🐶': return 'dog';
    case '🍆': return 'eggplant'; case '👀': return 'eyes'; case '😳': return 'flushed'; case '👻': return 'ghost';
    case '🔫': return 'gun'; case '😷': return 'mask'; case '💰': return 'moneybag'; case '💪': return 'muscle';
    case '🙅': return 'ng'; case '🐙': return 'octocat'; case '👌': return 'ok_hand'; case '🐾': return 'paw_prints';
    case '🐷': return 'pig'; case '💊': return 'pill'; case '🎅': return 'santa'; case '😏': return 'smirk';
    case '🆘': return 'sos'; case '✨': return 'sparkles'; case '😜': return 'stuck_out_tongue_winking_eye';
    case '🏊': return 'swimmer'; case '🤪': return 'trollface'; case '🔞': return 'underage'; case '✌️': return 'v';
    case '🆚': return 'vs'; case '🍉': return 'watermelon';
    case '😂': return 'joy'; case '😆': return 'laugh'; case '😄': return 'smile'; case '😁': return 'grin';
    case '😊': return 'blush'; case '😉': return 'wink'; case '❤️': case '❤': return 'heart'; case '😍': return 'love';
    case '😘': return 'kiss'; case '😢': return 'cry'; case '😭': return 'sob';
    case '😱': return 'scream'; case '😕': return 'confused'; case '🤔': return 'thinking'; case '😓': return 'sweat';
    case '😐': return 'neutral'; case '😎': return 'cool'; case '🙏': return 'pray'; case '👏': return 'clap';
    default: return '';
  }
}

function normalizeReplyContent(value: string): string {
  // Replies are plain text on the H5 endpoint. Remove native emoji and the
  // site's :name: aliases before encoding the request; never submit image or
  // emoji markup from the native composer.
  return value
    .replace(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\uFE0F\u200D]/gu, '')
    .replace(/:([A-Za-z0-9_+-]+):/g, (match: string, name: string) => emojiAlias(name).length > 0 ? '' : match);
}

function decodeEntity(value: string): string {
  return value.replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&').replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>').replace(/&#39;|&#x27;/gi, "'").replace(/&quot;/gi, '"')
    .replace(/&#x([0-9a-f]+);/gi, (_match: string, code: string) => {
      const point = Number.parseInt(code, 16);
      if (point <= 0xFFFF) return String.fromCharCode(point);
      const adjusted = point - 0x10000;
      return String.fromCharCode(0xD800 + (adjusted >> 10), 0xDC00 + (adjusted & 0x3FF));
    })
    .replace(/&#(\d+);/g, (_match: string, code: string) => {
      const point = Number(code);
      if (point <= 0xFFFF) return String.fromCharCode(point);
      const adjusted = point - 0x10000;
      return String.fromCharCode(0xD800 + (adjusted >> 10), 0xDC00 + (adjusted & 0x3FF));
    });
}

function htmlText(value: string, showImagePlaceholder: boolean = true): string {
  return value.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<br\s*\/?\s*>/gi, '\n').replace(/<\/(p|div|li|h[1-6]|blockquote|section)>/gi, '\n')
    .replace(/<li[^>]*>/gi, '• ').replace(/<img\b([^>]*)>/gi, (_tag: string, attrs: string) => {
      const alt = attrs.match(/\balt\s*=\s*["']([^"']*)["']/i);
      if (alt && alt[1].length > 0) {
        const decodedAlt = decodeEntity(alt[1]);
        const alias = decodedAlt.match(/^:([A-Za-z0-9_+-]+):$/);
        return alias ? (emojiAlias(alias[1]) || decodedAlt) : decodedAlt;
      }
      const src = attrs.match(/\bsrc\s*=\s*["']([^"']*)["']/i);
      const emoji = src ? src[1].match(/\/static\/emoji\/([^/?#\.]+)\.png/i) : null;
      if (emoji) return emojiAlias(emoji[1]) || `:${emoji[1]}:`;
      return showImagePlaceholder ? '[图片] ' : '';
    })
    .replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&#39;|&#x27;/gi, "'").replace(/&quot;/g, '"')
    .replace(/&#x([0-9a-f]+);/gi, (_: string, code: string) => decodeEntity(`&#x${code};`))
    .replace(/&#(\d+);/g, (_: string, code: string) => decodeEntity(`&#${code};`))
    .replace(/[ \t]+/g, ' ').replace(/\n[ \t]+/g, '\n').replace(/\n{3,}/g, '\n\n')
    .replace(/(^|\n)(加入收藏|编辑主题|新浪微博|分享到微信|❤️?赞|\d+ 次点击|\d+ 人赞|\d+ 人收藏)(?=\n|$)/g, '$1')
    // This is generated by the website after an edit, not user-authored
    // content. Strip it from the native detail view as well as the editor.
    .replace(/\s*本帖最后于[\s\S]*?编辑\s*$/i, '').trim();
}

function appendContentPart(result: Array<ContentPart>, text: string, bold: boolean = false, url: string = ''): void {
  if (text.length === 0) return;
  const part: ContentPart = new ContentPart();
  part.text = text;
  part.bold = bold;
  part.url = url;
  result.push(part);
}

function contentParts(value: string): Array<ContentPart> {
  const markdown = value
    .replace(/<(?:strong|b)\b[^>]*>/gi, '**').replace(/<\/(?:strong|b)>/gi, '**')
    .replace(/<a\b[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi,
      (_all: string, url: string, label: string) => {
      const cleanLabel: string = htmlText(label);
        if (cleanLabel.length === 0 || /^(?:#|\/favorite|\/unfavorite|\/vote)/i.test(url) || cleanLabel === '编辑主题') return '';
        const profile = url.match(/^\/u\/([A-Za-z0-9_-]+)(?:[?#].*)?$/i);
        if (profile && profile.length > 1) return `[${cleanLabel}](native-profile://${profile[1]})`;
        return `[${cleanLabel}](${url})`;
      });
  // Images are rendered as native Image components by the topic page. Do not
  // leave the parser's textual "[图片]" placeholder beside the real image.
  const source: string = htmlText(markdown, false);
  const result: Array<ContentPart> = [];
  const token = /(\*\*[\s\S]+?\*\*|\[[^\]]+\]\([^\s)]+\)|https?:\/\/[^\s<>()]+|@[A-Za-z0-9][A-Za-z0-9_-]{1,31})/g;
  let cursor: number = 0;
  let matched: RegExpExecArray | null = token.exec(source);
  while (matched) {
    appendContentPart(result, source.substring(cursor, matched.index));
    const raw: string = matched[0];
    if (raw.startsWith('**') && raw.endsWith('**')) {
      appendContentPart(result, raw.substring(2, raw.length - 2), true);
    } else if (raw.startsWith('[')) {
      const link = raw.match(/^\[([^\]]+)\]\(([^)]+)\)$/);
      if (link) appendContentPart(result, link[1], false, link[2]);
    } else if (raw.startsWith('@')) {
      const username = raw.substring(1);
      appendContentPart(result, raw, false, `native-profile://${username}`);
    } else {
      appendContentPart(result, raw, false, raw);
    }
    cursor = matched.index + raw.length;
    matched = token.exec(source);
  }
  appendContentPart(result, source.substring(cursor));
  if (result.length === 0) appendContentPart(result, source);
  return result;
}

function editableTopicText(value: string): string {
  // The redesigned detail container also includes the site's edit footer.
  // Never carry “本帖最后于……编辑” into the native editor and save it as
  // part of the user's actual post content.
  return htmlText(value, false)
    .replace(/\s*本帖最后于[\s\S]*?编辑\s*$/i, '')
    .trim();
}

@Entry
@Component
struct TopicPage {
  @StorageLink('themeColor') themeColor: string = '#51A775';
  @StorageLink('safeAreaTop') safeAreaTop: number = 0;
  @StorageLink('safeAreaBottom') safeAreaBottom: number = 0;
  @State title: string = '主题详情';
  @State topicId: string = '';
  @State body: string = '加载中…';
  @State comment: string = '';
  @State comments: Array<CommentItem> = [];
  @State shared: boolean = false;
  @State status: string = '';
  @State replyTarget: string = '';
  @State favorite: boolean = false;
  @State composerOpen: boolean = false;
  @State loading: boolean = true;
  @State author: string = '';
  @State selfName: string = '';
  @State avatar: string = '';
  @State nodeTitle: string = '';
  @State nodeCode: string = '';
  @State createdTime: string = '';
  @State editedTime: string = '';
  @State canEdit: boolean = false;
  @State viewCount: number = 0;
  @State favoriteCount: number = 0;
  @State voteCount: number = 0;
  @State topicVoteUrl: string = '';
  @State topicVoted: boolean = false;
  @State sending: boolean = false;
  @State favoriteBusy: boolean = false;
  @State images: Array<string> = [];
  @State imageHeights: Array<number> = [];
  @State commentPage: number = 1;
  @State commentsHasMore: boolean = false;
  @State commentsLoadingMore: boolean = false;
  @StorageLink('commentsOrderDesc') commentsOrderDesc: boolean = false;
  @StorageLink('imageBedApiKey') imageBedApiKey: string = '';
  @State uploadingImage: boolean = false;
  @State editingReplyId: string = '';

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, string>;
      this.topicId = params && params.id ? params.id : '';
      this.title = params && params.title ? params.title : '主题详情';
    } catch (_) {}
    this.loadBody();
  }

  pageTransition() {
    // The device default transition briefly scales/slides the detail card from
    // the centre. A zero-duration page transition keeps the layout stationary.
    PageTransitionEnter({ type: RouteType.None, duration: 0 })
    PageTransitionExit({ type: RouteType.None, duration: 0 })
  }

  async loadBody(): Promise<void> {
    if (this.topicId.length === 0) { this.body = '主题不存在'; this.loading = false; return; }
    this.loading = true;
    this.status = '';
    try {
      const detail = await Promise.all([
        GuozaokeService.topicDetail(this.topicId),
        GuozaokeService.topicCommentPage(this.topicId, 1),
        GuozaokeService.topicFavoriteState(this.topicId)
      ]);
      const topic: TopicDetailData = detail[0];
      this.body = topic.content;
      this.author = topic.author;
      this.avatar = topic.avatar;
      this.nodeTitle = topic.nodeTitle;
      this.nodeCode = topic.nodeCode;
      this.createdTime = topic.createdTime;
      this.editedTime = topic.editedTime;
      this.images = topic.images;
      this.imageHeights = topic.images.map(() => 220);
      this.viewCount = topic.viewCount;
      this.favoriteCount = topic.favoriteCount;
      this.voteCount = topic.voteCount;
      this.topicVoteUrl = topic.voteUrl;
      this.topicVoted = topic.voted;
      this.selfName = await GuozaokeService.selfUsername();
      this.canEdit = this.author.length > 0 && this.selfName.length > 0 && this.author === this.selfName;
      const commentResult: CommentListResult = detail[1];
      this.markEditable(commentResult.items);
      this.comments = this.commentsOrderDesc ? commentResult.items.slice().reverse() : commentResult.items;
      this.commentPage = 1;
      this.commentsHasMore = commentResult.hasMore;
      this.favorite = detail[2];
    }
    catch (_) { this.body = '加载失败，请稍后重试'; }
    this.loading = false;
  }

  private notify(message: string, duration: number = 2200): void {
    this.status = message;
    setTimeout(() => {
      if (this.status === message) this.status = '';
    }, duration);
  }

  private markEditable(items: Array<CommentItem>): Array<CommentItem> {
    items.forEach((item: CommentItem) => {
      item.editable = item.editable || (item.author.length > 0 && item.author === this.selfName && item.id.length > 0);
    });
    return items;
  }

  private async toggleFavorite(): Promise<void> {
    if (this.favoriteBusy) return;
    if (this.canEdit) {
      this.notify('自己发的主题不能收藏');
      return;
    }
    if (!GuozaokeService.isLoggedIn()) {
      this.notify('请先登录');
      return;
    }
    this.favoriteBusy = true;
    const ok = this.favorite ? await GuozaokeService.unfavorite(this.topicId) : await GuozaokeService.favorite(this.topicId);
    if (ok) {
      this.favorite = !this.favorite;
      this.notify(this.favorite ? '已加入收藏' : '已取消收藏');
    } else {
      this.notify('操作失败，请稍后重试');
    }
    this.favoriteBusy = false;
  }

  private async voteTopic(): Promise<void> {
    if (this.topicVoted || this.topicVoteUrl.length === 0) {
      this.notify(this.topicVoted ? '已经点过赞了' : '当前主题暂不支持点赞');
      return;
    }
    const ok = await GuozaokeService.vote(this.topicVoteUrl);
    if (ok) {
      this.topicVoted = true;
      this.voteCount += 1;
      this.notify('点赞成功');
    } else this.notify('点赞失败，请稍后重试');
  }

  private openEditor(): void {
    const text = editableTopicText(this.body);
    setTimeout(() => router.pushUrl({
      url: 'pages/NewTopicPage',
      params: { edit: '1', editId: this.topicId, title: this.title, content: text, nodeCode: this.nodeCode, nodeTitle: this.nodeTitle }
    }), 80);
  }

  private async sendComment(): Promise<void> {
    const raw = this.comment.trim();
    const value = normalizeReplyContent(raw).trim();
    if (this.sending) { this.notify('正在提交，请稍候'); return; }
    if (this.topicId.length === 0) { this.notify('主题信息无效，请返回后重试'); return; }
    if (raw.length === 0) { this.notify('请输入评论内容'); return; }
    if (value.length === 0) { this.notify('回复仅支持文本，表情已过滤'); return; }
    // Do not gate submission on cookie-name heuristics. The redesigned site
    // may keep the authenticated WebView session under a different cookie
    // name; the POST/XSRF response is the authoritative login check.
    this.sending = true;
    this.status = '发送中…';
    const editing = this.editingReplyId.length > 0;
    const content = !editing && this.replyTarget.length > 0 && value.indexOf(`@${this.replyTarget}`) !== 0 ? `@${this.replyTarget} ${value}` : value;
    try {
      const ok = editing ? await GuozaokeService.editComment(this.editingReplyId, content) : await GuozaokeService.comment(this.topicId, content);
      if (ok) {
        this.dismissComposer(true);
        this.notify(editing ? '回复已更新' : '评论成功');
        // A successful POST must not be reported as failed just because the
        // follow-up comment refresh times out or is blocked by the CDN.
        try {
          const commentResult = await GuozaokeService.topicCommentPage(this.topicId, 1);
          this.markEditable(commentResult.items);
          this.comments = this.commentsOrderDesc ? commentResult.items.slice().reverse() : commentResult.items;
          this.commentPage = 1;
          this.commentsHasMore = commentResult.hasMore;
        } catch (_) { }
      } else {
        this.notify('评论失败，请稍后重试');
      }
    } catch (_) {
      this.notify('评论失败，请稍后重试');
    } finally {
      this.sending = false;
    }
  }

  async copyShareLink(): Promise<void> {
    if (this.topicId.length === 0) return;
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, `https://www.guozaoke.com/t/${this.topicId}`);
      await pasteboard.getSystemPasteboard().setData(data);
      this.shared = true;
      setTimeout(() => this.shared = false, 1800);
    } catch (_) { this.status = '复制分享链接失败'; }
  }

  private async copyContent(value: string): Promise<void> {
    const plainText: string = htmlText(value);
    if (plainText.length === 0) return;
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, plainText);
      await pasteboard.getSystemPasteboard().setData(data);
      // A long-press already takes noticeable time; keep the confirmation on
      // screen long enough to be readable after the gesture completes.
      this.notify('内容已复制', 4000);
    } catch (_) { this.notify('复制失败'); }
  }

  private async openExternal(url: string): Promise<void> {
    const target: string = url.startsWith('/') ? `https://www.guozaoke.com${url}` : url;
    if (!/^https?:\/\//i.test(target)) return;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: target });
    } catch (_) { this.notify('无法打开链接'); }
  }

  private openComposer(target: string = ''): void {
    this.editingReplyId = '';
    this.replyTarget = target;
    if (target.length > 0) this.comment = `@${target} `;
    this.composerOpen = true;
    this.focusComposer();
  }

  private focusComposer(): void {
    setTimeout(() => {
      try { this.getUIContext().getFocusController().requestFocus('commentInput'); } catch (_) {}
    }, 120);
  }

  private dismissComposer(clearDraft: boolean = false): void {
    try { this.getUIContext().getFocusController().clearFocus(); } catch (_) {}
    this.composerOpen = false;
    if (clearDraft) {
      this.replyTarget = '';
      this.comment = '';
      this.editingReplyId = '';
    }
  }

  private async openReplyEditor(item: CommentItem): Promise<void> {
    if (!item.editable || item.id.length === 0) return;
    this.editingReplyId = item.id;
    this.replyTarget = '';
    this.comment = normalizeReplyContent(htmlText(item.content, false)).trim();
    this.composerOpen = true;
    // Focus immediately so the editor is usable while the canonical form is
    // loading. The second focus below covers the async draft replacement.
    this.focusComposer();
    // Read the canonical edit form so links, mentions and line breaks are
    // echoed exactly as stored by the website, instead of reverse-parsing the
    // rendered comment markup.
    const draft = await GuozaokeService.replyEditDraft(item.id);
    if (this.editingReplyId === item.id && draft.length > 0) {
      this.comment = normalizeReplyContent(draft).trim();
    }
    this.focusComposer();
  }

  private async chooseCommentImage(): Promise<void> {
    if (this.uploadingImage) return;
    if (this.imageBedApiKey.trim().length === 0) { this.notify('请先在设置中添加 sm.ms API Key'); return; }
    this.uploadingImage = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) { this.notify('无法打开系统图片选择器'); this.uploadingImage = false; return; }
      const viewPicker = new picker.PhotoViewPicker(context as common.UIAbilityContext);
      const result = await viewPicker.select({ MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1 });
      const uri = result.photoUris.length > 0 ? result.photoUris[0] : '';
      if (uri.length === 0) { this.uploadingImage = false; return; }
      const url = await GuozaokeService.uploadImage(uri, this.imageBedApiKey);
      if (url.length === 0) { this.notify('图片上传失败，请检查 sm.ms API Key'); this.uploadingImage = false; return; }
      this.comment = `${this.comment}${this.comment.length > 0 ? '\n' : ''}[![](${url})](${url})`;
      this.notify('图片已插入');
    } catch (_) { this.notify('已取消选择图片'); }
    this.uploadingImage = false;
  }

  private toggleCommentOrder(): void {
    this.commentsOrderDesc = !this.commentsOrderDesc;
    this.comments = this.comments.slice().reverse();
  }

  private async loadMoreComments(): Promise<void> {
    if (this.commentsLoadingMore || !this.commentsHasMore || this.topicId.length === 0) return;
    this.commentsLoadingMore = true;
    try {
      const nextPage: number = this.commentPage + 1;
      const result: CommentListResult = await GuozaokeService.topicCommentPage(this.topicId, nextPage);
      const knownIds: Set<string> = new Set(this.comments.map((item: CommentItem) => `${item.id}-${item.floor}`));
      this.markEditable(result.items);
      const nextItems: Array<CommentItem> = result.items.filter((item: CommentItem) => !knownIds.has(`${item.id}-${item.floor}`));
      this.comments = this.comments.concat(this.commentsOrderDesc ? nextItems.slice().reverse() : nextItems);
      this.commentPage = nextPage;
      this.commentsHasMore = result.hasMore && nextItems.length > 0;
    } catch (_) { this.notify('评论下一页加载失败'); }
    this.commentsLoadingMore = false;
  }

  onBackPress(): boolean {
    if (this.composerOpen) {
      this.dismissComposer();
      return true;
    }
    return false;
  }

  @Builder
  nativeContent(value: string, fontSize: number, lineHeight: number) {
    Text() {
      ForEach(contentParts(value), (part: ContentPart, index: number) => {
      Span(part.text)
        .fontWeight(part.bold ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(part.url.length > 0 ? this.themeColor : '#3C4043')
        .decoration({ type: part.url.length > 0 ? TextDecorationType.Underline : TextDecorationType.None,
          color: part.url.length > 0 ? this.themeColor : '#3C4043' })
        .onClick(() => {
          if (part.url.startsWith('native-profile://')) {
            const username = part.url.substring('native-profile://'.length);
            if (username.length > 0) setTimeout(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username } }), 80);
          } else if (part.url.length > 0) {
            this.openExternal(part.url);
          }
        })
      }, (part: ContentPart, index: number) => `${index}-${part.text}-${part.url}`)
    }.fontSize(fontSize).lineHeight(lineHeight).width('100%')
      // Let HarmonyOS provide the native long-press menu, including copy,
      // select-all and partial selection across apps.
      .copyOption(CopyOptions.LocalDevice)
      .textSelectable(TextSelectableMode.SELECTABLE_FOCUSABLE)
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(30).fontColor(this.themeColor).width(44).textAlign(TextAlign.Center).onClick(() => {
          if (this.composerOpen) this.dismissComposer();
          else setTimeout(() => router.back(), 80);
        })
        Text('主题详情').fontSize(18).fontColor('#333333').fontWeight(FontWeight.Medium).margin({ left: 8 })
        Blank()
        Image($r('app.media.ic_share')).width(24).height(24).fillColor(this.themeColor).margin({ right: 8 })
          .onClick(() => this.copyShareLink())
      }.width('100%').height(56).flexShrink(0).padding({ left: 8, right: 12 }).backgroundColor(Color.White)
      Stack() {
        Scroll() {
          Column() {
          Column() {
            Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#202124').lineHeight(26).width('100%')
            Row() {
              Stack() {
                Image($r('app.media.avatar_placeholder')).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover)
                if (this.avatar.length > 0) { Image(this.avatar).width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover) }
              }.onClick(() => {
                if (this.author.length > 0) setTimeout(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: this.author } }), 80);
              })
              Column() {
                Text(this.author.length > 0 ? this.author : '过早客用户').fontSize(13).fontColor(this.themeColor).fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    if (this.author.length > 0) setTimeout(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: this.author } }), 80);
                  })
                Row() {
                  if (this.createdTime.length > 0) { Text(this.createdTime).fontSize(11).fontColor('#8A9199'); }
                  if (this.nodeTitle.length > 0) {
                    Text(this.nodeTitle).fontSize(11).fontColor(this.themeColor).margin({ left: this.createdTime.length > 0 ? 8 : 0 })
                      .onClick(() => setTimeout(() => router.pushUrl({ url: 'pages/TopicListPage', params: { kind: 'node', code: this.nodeCode, title: this.nodeTitle } }), 80));
                  }
                }.margin({ top: 3 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
            }.width('100%').margin({ top: 12, bottom: 16 }).alignItems(VerticalAlign.Center)
            if (this.loading) {
              Row() { LoadingProgress().width(22).height(22); Text('正在加载详情…').fontSize(13).fontColor('#8A9199').margin({ left: 10 }); }
                .width('100%').height(64).justifyContent(FlexAlign.Center)
            } else {
              this.nativeContent(this.body, 15, 24)
              ForEach(this.images, (url: string, index: number) => {
                Image(url).width('100%').height(this.imageHeights[index]).objectFit(ImageFit.Contain)
                  .margin({ top: 12 }).borderRadius(6).backgroundColor('#F7F8FA')
                  .onComplete((event) => {
                    if (event && event.width > 0 && event.height > 0) {
                      const next = this.imageHeights.slice();
                      next[index] = Math.max(120, Math.min(420, 344 * event.height / event.width));
                      this.imageHeights = next;
                    }
                  })
              }, (url: string) => url)
            }
          }.width('100%').padding(18).backgroundColor(Color.White).borderRadius(10)
          if (this.editedTime.length > 0) {
            Text(`本帖最后于 ${this.editedTime} 编辑`).fontSize(12).fontColor('#8A9199')
              .width('100%').textAlign(TextAlign.End).margin({ top: 6, right: 8 })
          }
          // Keep the primary actions directly under the post body. They are
          // intentionally grouped together instead of spreading across the
          // row, which mirrors the compact action area in the H5 client.
          Row() {
            Row() {
              Image($r('app.media.ic_reply')).width(19).height(19).fillColor(this.themeColor).margin({ right: 5 })
              Text('回复').fontSize(13).fontColor(this.themeColor)
            }.layoutWeight(1).height(46).justifyContent(FlexAlign.Center).onClick(() => this.openComposer())
            Row() {
              Image($r('app.media.ic_favorite')).width(19).height(19).fillColor(this.favorite ? this.themeColor : '#7B8794').margin({ right: 5 })
              Text(this.favoriteBusy ? '处理中…' : (this.favorite ? '已收藏' : '收藏')).fontSize(13).fontColor(this.favorite ? this.themeColor : '#7B8794')
            }.layoutWeight(1).height(46).justifyContent(FlexAlign.Center).onClick(() => this.toggleFavorite())
            Row() {
              Image($r('app.media.ic_like')).width(19).height(19).fillColor(this.topicVoted ? '#F59E0B' : this.themeColor).margin({ right: 5 })
              Text(this.topicVoted ? '已赞' : '赞').fontSize(13).fontColor(this.topicVoted ? '#F59E0B' : this.themeColor)
            }.layoutWeight(1).height(46).justifyContent(FlexAlign.Center).onClick(() => this.voteTopic())
            Row() {
              Image($r('app.media.ic_share')).width(19).height(19).fillColor(this.themeColor)
              Text('分享').fontSize(13).fontColor(this.themeColor).margin({ left: 5 })
            }.layoutWeight(1).height(46).justifyContent(FlexAlign.Center).onClick(() => this.copyShareLink())
            if (this.canEdit) {
              Row() {
                Image($r('app.media.ic_edit')).width(19).height(19).fillColor(this.themeColor)
                Text('编辑').fontSize(13).fontColor(this.themeColor).margin({ left: 5 })
              }.layoutWeight(1).height(46).justifyContent(FlexAlign.Center).onClick(() => this.openEditor())
            }
          }.width('100%').height(48).padding({ left: 2, right: 2 }).backgroundColor(Color.White).borderRadius(8)
            .border({ width: { top: 1, bottom: 1 }, color: '#E6E8EB' }).margin({ top: 8, bottom: 4 })
          // Secondary metadata stays on its own line so the actions remain
          // easy to hit and the counts are visually subordinate.
          Row() {
            Text(`${this.viewCount} 次点击`).fontSize(12).fontColor('#8A9199')
            Blank()
            Text(`${this.favoriteCount} 人收藏`).fontSize(12).fontColor('#8A9199')
            Text(`${this.voteCount} 人赞`).fontSize(12).fontColor(this.topicVoted ? '#F59E0B' : '#8A9199').margin({ left: 12 })
          }.width('100%').padding({ left: 4, right: 4, top: 8, bottom: 4 })
          Row() {
            Text(`评论 ${this.comments.length}`).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#30343B')
            Blank()
            Text(this.commentsOrderDesc ? '倒序排列' : '正序排列').fontSize(12).fontColor(this.themeColor)
              .padding({ left: 10, right: 2, top: 6, bottom: 6 }).onClick(() => this.toggleCommentOrder())
          }.width('100%').padding({ top: 20, bottom: 10, left: 4, right: 4 })
          ForEach(this.comments, (item: CommentItem, index: number) => {
            Row() {
              Image(item.avatar.length > 0 ? item.avatar : $r('app.media.avatar_placeholder')).width(34).height(34).borderRadius(17).objectFit(ImageFit.Cover)
                .onClick(() => {
                  if (item.author.length > 0) setTimeout(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } }), 80);
                })
              Column() {
                Row() {
                  Text(item.author.length > 0 ? item.author : `用户 ${index + 1}`).fontSize(13).fontColor(this.themeColor).fontWeight(FontWeight.Medium)
                    .onClick(() => {
                      if (item.author.length > 0) setTimeout(() => router.pushUrl({ url: 'pages/ProfilePage', params: { username: item.author } }), 80);
                    })
                  Text(item.time).fontSize(11).fontColor('#A0A5AB').margin({ left: 8 })
                  Blank()
                  Text(item.floor.startsWith('#') ? item.floor : `#${item.floor}`).fontSize(12).fontColor('#A0A5AB')
                }.width('100%')
                Column() { this.nativeContent(item.content, 14, 21) }.width('100%').margin({ top: 6 })
                Row() {
                  Blank()
                  Text('回复').fontSize(12).fontColor(this.themeColor).padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.openComposer(item.author.length > 0 ? item.author : `用户 ${index + 1}`);
                    })
                  Text(item.voted ? '已赞' : '赞').fontSize(12).fontColor(item.voted ? '#F59E0B' : '#7B8794')
                    .padding({ left: 10, right: 6, top: 4, bottom: 4 }).onClick(async () => {
                      if (item.voted || item.voteUrl.length === 0) return;
                      const voted = await GuozaokeService.vote(item.voteUrl);
                      if (voted) { item.voted = true; item.voteCount += 1; this.comments = this.comments.slice(); }
                      this.status = voted ? '点赞成功' : '点赞失败';
                    })
                  Text(`${item.voteCount}`).fontSize(11).fontColor('#A0A5AB').margin({ right: 2 })
                  if (item.editable) {
                    Text('编辑').fontSize(12).fontColor(this.themeColor).padding({ left: 10, right: 6, top: 4, bottom: 4 })
                      .onClick(() => this.openReplyEditor(item))
                  }
                }.width('100%').margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
            }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(8).margin({ bottom: 8 })
          }, (item: CommentItem, index: number) => `${item.id}-${index}`)
          if (this.commentsLoadingMore || this.commentsHasMore) {
            Row() {
              if (this.commentsLoadingMore) { LoadingProgress().width(18).height(18).color(this.themeColor) }
              Text(this.commentsLoadingMore ? '正在加载更多评论…' : '继续上滑加载更多评论').fontSize(12).fontColor('#7B8794')
                .margin({ left: this.commentsLoadingMore ? 8 : 0 })
            }.width('100%').height(48).justifyContent(FlexAlign.Center)
          }
          }.width('100%').constraintSize({ minHeight: '100%' }).justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start).padding({ left: 12, right: 12, top: 12, bottom: 16 })
        }.width('100%').height('100%').onReachEnd(() => this.loadMoreComments())
        if (this.composerOpen) {
          Column().width('100%').height('100%').backgroundColor('#01000000')
            .hitTestBehavior(HitTestMode.Block).onClick(() => this.dismissComposer())
        }
      }.layoutWeight(1).width('100%')
      if (this.composerOpen) {
        Column() {
          Row() {
            Text('×').fontSize(23).fontColor('#7B8794').width(40).height(48).textAlign(TextAlign.Center)
              .onClick(() => this.dismissComposer(true))
            Text(this.uploadingImage ? '上传中…' : '图片').fontSize(12).fontColor(this.uploadingImage ? '#A0A5AB' : this.themeColor)
              .width(44).textAlign(TextAlign.Center).onClick(() => this.chooseCommentImage())
            TextArea({ placeholder: this.editingReplyId.length > 0 ? '编辑回复…' : (this.replyTarget.length > 0 ? `回复 ${this.replyTarget}…` : '请输入评论内容'), text: this.comment })
              .id('commentInput')
              .focusOnTouch(true)
              .fontSize(15)
              .fontColor('#30343B')
              .placeholderColor('#9AA0A6')
              .caretColor(this.themeColor)
              .textAlign(TextAlign.Start)
              .lineHeight(21)
              .maxLines(3)
              .layoutWeight(1)
              .height(56)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor('#F5F6F8')
              .borderRadius(8)
              .onChange((v: string) => this.comment = v)
              .onKeyPreIme((event: KeyEvent) => {
                if (event.keyCode !== 2) return false;
                // Consume both phases. Removing the editor on key-down would let
                // the matching key-up reach the page and navigate away.
                if (event.type === KeyType.Up) this.dismissComposer();
                return true;
              })
            Row() {
              Text(this.sending ? '保存中…' : (this.editingReplyId.length > 0 ? '保存' : '评论'))
                .fontSize(14).fontColor(Color.White).textAlign(TextAlign.Center).width('100%')
            }.id('commentSubmit').height(44).width(68).margin({ left: 8, right: 8 })
              .borderRadius(22).backgroundColor(this.themeColor)
              // Row keeps a stable, full-size hit target while TextArea focus
              // and the soft keyboard are changing in the same frame.
              .opacity(this.sending ? 0.55 : 1).justifyContent(FlexAlign.Center)
              .onClick(() => this.sendComment())
          }.width('100%').height(72).alignItems(VerticalAlign.Center)
        }.width('100%').height(110).flexShrink(0).backgroundColor(Color.White)
          .border({ width: { top: 1 }, color: '#E6E8EB' })
      }
      if (this.status.length > 0) {
        Row() { Text(this.status).fontSize(13).fontColor(this.themeColor).textAlign(TextAlign.Center).width('100%') }
          .width('92%').height(36).backgroundColor('#E8F5EE').borderRadius(18)
          .shadow({ radius: 8, color: '#33000000', offsetY: 2 }).position({ x: '4%', y: '46%' }).zIndex(20)
      }
      if (this.shared) {
        Row() { Text('分享链接已复制').fontSize(13).fontColor(this.themeColor).textAlign(TextAlign.Center).width('100%') }
          .width('92%').height(36).backgroundColor('#E8F5EE').borderRadius(18)
          .shadow({ radius: 8, color: '#33000000', offsetY: 2 }).position({ x: '4%', y: '46%' }).zIndex(20)
      }
    }.width('100%').height('100%').padding({ top: this.safeAreaTop, bottom: this.safeAreaBottom }).backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
  }
}
