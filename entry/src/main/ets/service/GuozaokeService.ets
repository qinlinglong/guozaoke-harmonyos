import { http } from '@kit.NetworkKit';
import { webview } from '@kit.ArkWeb';
import { Topic } from '../model/Topic';
import { CommentItem } from '../model/CommentItem';
import { NodeItem } from '../model/NodeItem';
import { UserProfile } from '../model/UserProfile';

export const BASE_URL: string = 'https://www.guozaoke.com';
export const LOGIN_URL: string = `${BASE_URL}/login`;

function decodeHtml(value: string): string {
  return value.replace(/<[^>]+>/g, '').replace(/&amp;/g, '&').replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>').replace(/&#39;/g, "'").replace(/&quot;/g, '"').trim();
}

function firstMatch(source: string, expression: RegExp): string {
  const matched: RegExpMatchArray | null = source.match(expression);
  return matched && matched.length > 1 ? decodeHtml(matched[1]) : '';
}

function normalizeImageUrl(value: string): string {
  const clean: string = value.trim().replace(/^['"]|['"]$/g, '');
  if (clean.length === 0 || clean.startsWith('data:')) return '';
  if (clean.startsWith('//')) return `https:${clean}`;
  if (clean.startsWith('/static/')) return `https://static.guozaoke.com${clean}`;
  if (clean.startsWith('/')) return `${BASE_URL}${clean}`;
  // The redesigned markup currently emits ...com//static/... URLs. ArkUI's
  // image loader follows that malformed path as a protocol-relative redirect.
  return clean.replace('https://static.guozaoke.com//', 'https://static.guozaoke.com/');
}

function avatarFromHtml(source: string): string {
  // The redesigned site lazy-loads avatars via data-src/data-original on
  // some pages, while the legacy markup uses src. Accept all three forms.
  const image = source.match(/<(?:img|image)\b[^>]*(?:src|data-src|data-original)=["']([^"']+)["'][^>]*>/i);
  if (!image || image.length < 2) return '';
  return normalizeImageUrl(image[1]);
}

export class GuozaokeService {
  static parseTopics(html: string): Array<Topic> {
    const cards: Array<string> = html.match(/<div[^>]*class="[^"]*topic-item[^"]*"[\s\S]*?(?=<div[^>]*class="[^"]*topic-item|<\/main>|<\/body>)/g) ?? [];
    const result: Array<Topic> = [];
    cards.forEach((card: string) => {
      const topic: Topic = new Topic();
      topic.id = firstMatch(card, /href="\/t\/(\d+)/);
      topic.title = firstMatch(card, /<h3[^>]*class="[^"]*title[^"]*"[^>]*>[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/);
      topic.author = firstMatch(card, /class="[^"]*username[^"]*"[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/);
      topic.node = firstMatch(card, /class="[^"]*node[^"]*"[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/);
      const avatarTag = card.match(/<(?:img|image)\b[^>]*class=["'][^"']*avatar[^"']*["'][^>]*>/i);
      topic.avatar = avatarTag ? avatarFromHtml(avatarTag[0]) : avatarFromHtml(card);
      topic.replies = firstMatch(card, /class="[^"]*count[^"]*"[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/) || '0';
      if (topic.id.length > 0 && topic.title.length > 0) result.push(topic);
    });
    return result;
  }
  static cookie(): string {
    try {
      return webview.WebCookieManager.fetchCookieSync(BASE_URL);
    } catch (_) {
      return '';
    }
  }

  static isLoggedIn(): boolean {
    return GuozaokeService.cookie().split(';').some((item: string) => {
      const key = item.trim().split('=')[0].toLowerCase();
      return key === 'user' || key === 'session' || key === 'sid' || key === 'token' || key === 'auth';
    });
  }

  static clearCookies(): void {
    try { webview.WebCookieManager.clearAllCookiesSync(); } catch (_) { }
  }

  static async get(path: string): Promise<string> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(`${BASE_URL}${path}`, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'Mozilla/5.0 (HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept-Language': 'zh-CN,zh;q=0.9',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Referer': BASE_URL + '/',
          'Cache-Control': 'no-cache',
          'Cookie': GuozaokeService.cookie()
        },
        // Avoid leaving the native home screen in an endless loading state when
        // the redesigned site or network does not answer promptly.
        connectTimeout: 8000,
        readTimeout: 10000,
        expectDataType: http.HttpDataType.STRING
      });
      return response.result as string;
    } finally {
      request.destroy();
    }
  }

  static async topics(tab: string = ''): Promise<Array<Topic>> {
    const html: string = await GuozaokeService.get(tab.length > 0 ? `/?tab=${tab}` : '/');
    return GuozaokeService.parseTopics(html);
  }

  static async userTopics(kind: string): Promise<Array<Topic>> {
    const profile = await GuozaokeService.selfProfileUrl();
    const match = profile.match(/\/u\/([A-Za-z0-9_-]+)/);
    if (!match) return [];
    return GuozaokeService.userTopicsFor(match[1], kind);
  }

  static async userTopicsFor(username: string, kind: string): Promise<Array<Topic>> {
    const safeName = username.replace(/[^A-Za-z0-9_-]/g, '');
    if (safeName.length === 0) return [];
    return GuozaokeService.parseTopics(await GuozaokeService.get(`/u/${safeName}/${kind}`));
  }

  static async selfProfileUrl(): Promise<string> {
    try {
      const html = await GuozaokeService.get('/');
      // The first /u/ link on the home page usually belongs to a topic
      // author. The authenticated account lives in the sidebar usercard.
      const path = firstMatch(html,
        /<div[^>]*class=["'][^"']*usercard[^"']*["'][\s\S]*?href=["'](\/u\/(?!0(?:["'\/]))[A-Za-z0-9_-]+)["']/i);
      return path.length > 0 ? `${BASE_URL}${path}` : `${BASE_URL}/`;
    } catch (_) {
      return `${BASE_URL}/`;
    }
  }

  static async selfAvatar(): Promise<string> {
    try {
      const profileUrl = await GuozaokeService.selfProfileUrl();
      const path = profileUrl.replace(BASE_URL, '');
      const html = await GuozaokeService.get(path);
      const avatarTag = html.match(/<(?:img|image)\b[^>]*class=["'][^"']*avatar[^"']*["'][^>]*>/i);
      return avatarTag ? avatarFromHtml(avatarTag[0]) : '';
    } catch (_) { return ''; }
  }

  static async selfUsername(): Promise<string> {
    const profileUrl = await GuozaokeService.selfProfileUrl();
    const match = profileUrl.match(/\/u\/([A-Za-z0-9_-]+)/);
    return match ? match[1] : '';
  }

  static async userProfile(username: string): Promise<UserProfile> {
    const profile: UserProfile = new UserProfile();
    const safeName = username.replace(/[^A-Za-z0-9_-]/g, '');
    if (safeName.length === 0) return profile;
    const html = await GuozaokeService.get(`/u/${safeName}`);
    const profileBlock = html.match(/<div[^>]*class="[^"]*profile[^"]*"[\s\S]*?(?=<\/main>|<div[^>]*class="[^"]*sidebar)/i);
    const scope = profileBlock ? profileBlock[0] : html;
    const avatarTag = scope.match(/<(?:img|image)\b[^>]*class=["'][^"']*avatar[^"']*["'][^>]*>/i);
    profile.avatar = avatarTag ? avatarFromHtml(avatarTag[0]) : '';
    profile.username = firstMatch(scope, /class="[^"]*username[^"]*"[^>]*>([\s\S]*?)<\/(?:div|span|a)>/i) || safeName;
    profile.number = firstMatch(scope, /class="[^"]*number[^"]*"[^>]*>([\s\S]*?)<\/(?:div|span)>/i);
    profile.since = firstMatch(scope, /class="[^"]*since[^"]*"[^>]*>([\s\S]*?)<\/(?:div|span)>/i);
    return profile;
  }

  static async topicDetail(id: string): Promise<string> {
    const html: string = await GuozaokeService.get(`/t/${id}`);
    const content: string = firstMatch(html,
      /<div[^>]*class="[^"]*ui-content[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>/);
    return content.length > 0 ? content : '暂时无法解析主题内容';
  }

  static async topicComments(id: string): Promise<Array<CommentItem>> {
    // The Android client requests the first paginated detail page for comments;
    // the redesigned site omits the reply list from the bare /t/:id response.
    let html: string = await GuozaokeService.get(`/t/${id}?p=1`);
    // Some CDN edges serve the anti-bot shell for the paginated URL only.
    // Retry the canonical detail response before presenting a false empty list.
    if (!/(reply-item|topic-reply|J_replyVote|comment-content|reply-content)/i.test(html)) {
      html = await GuozaokeService.get(`/t/${id}`);
    }
    const result: Array<CommentItem> = [];
    const blocks: Array<string> = html.match(/<div[^>]*class=["'][^"']*reply-item[^"']*["'][\s\S]*?(?=<div[^>]*class=["'][^"']*reply-item|<div[^>]*class=["'][^"']*topic-reply-create|<\/body>)/gi) ?? [];
    blocks.forEach((block: string, index: number) => {
      const item: CommentItem = new CommentItem();
      item.id = firstMatch(block, /(?:id|data-id)="(?:reply|comment)?-?(\d+)"/i) || `${index + 1}`;
      item.author = firstMatch(block, /<a[^>]*class=["'][^"']*reply-username[^"']*["'][^>]*>([\s\S]*?)<\/a>/i) ||
        firstMatch(block, /class=["'][^"']*username[^"']*["'][^>]*>([\s\S]*?)<\/(?:span|a)>/i) || '用户';
      item.time = firstMatch(block, /class=["'][^"']*time[^"']*["'][^>]*>([\s\S]*?)<\/span>/i);
      item.floor = firstMatch(block, /class=["'][^"']*floor[^"']*["'][^>]*>([\s\S]*?)<\/span>/i) || `#${index + 1}`;
      const avatarTag = block.match(/<img[^>]*class=["'][^"']*avatar[^"']*["'][^>]*>/i);
      item.avatar = avatarTag ? avatarFromHtml(avatarTag[0]) : '';
      const vote = block.match(/<a[^>]*class=["'][^"']*J_replyVote[^"']*["'][^>]*href=["']([^"']*)["'][^>]*data-count=["'](\d+)["']/i);
      if (vote) { item.voteUrl = vote[1]; item.voteCount = Number(vote[2]); }
      item.content = firstMatch(block, /<(?:span|div)[^>]*class=["'][^"']*content[^"']*["'][^>]*>([\s\S]*?)<\/(?:span|div)>/i);
      if (item.content.length > 0 && item.content.length <= 4000) result.push(item);
    });
    if (result.length === 0) {
      // Only accept explicit alternative reply-content classes. Matching a
      // generic "content" class also captures the topic body, composer and
      // sidebar cards, which used to create fake comments on zero-reply posts.
      const replies: Array<string> = html.match(/<(?:span|div|p|article)[^>]*class=["'][^"']*(?:comment-content|reply-content)[^"']*["'][^>]*>[\s\S]*?<\/(?:span|div|p|article)>/gi) ?? [];
      replies.forEach((reply: string, index: number) => {
        const item: CommentItem = new CommentItem();
        item.id = `${index + 1}`;
        item.floor = `#${index + 1}`;
        item.content = reply;
        if (decodeHtml(reply).replace(/\s+/g, ' ').trim().length > 0) result.push(item);
      });
    }
    return result;
  }

  static async topicFavoriteState(id: string): Promise<boolean> {
    try {
      const html = await GuozaokeService.get(`/t/${id}`);
      const element = html.match(/class="[^"]*J_topicFavorite[^"]*"[^>]*data-type="([^"]+)"/i);
      return !!element && element[1] !== 'favorite';
    } catch (_) { return false; }
  }

  static async favorite(id: string): Promise<boolean> {
    try { return (await GuozaokeService.get(`/favorite?topic_id=${encodeURIComponent(id)}`)).length > 0; }
    catch (_) { return false; }
  }

  static async unfavorite(id: string): Promise<boolean> {
    try { return (await GuozaokeService.get(`/unfavorite?topic_id=${encodeURIComponent(id)}`)).length > 0; }
    catch (_) { return false; }
  }

  static async vote(url: string): Promise<boolean> {
    try {
      const path = url.startsWith(BASE_URL) ? url.substring(BASE_URL.length) : url;
      return (await GuozaokeService.get(path)).length > 0;
    } catch (_) { return false; }
  }

  static async comment(id: string, content: string): Promise<boolean> {
    const token = GuozaokeService.xsrf();
    const response = await GuozaokeService.post(`/t/${id}`, `tid=${encodeURIComponent(id)}&content=${encodeURIComponent(content)}&_xsrf=${encodeURIComponent(token)}`);
    return response.length > 0;
  }

  static async newTopic(nodeCode: string, title: string, content: string): Promise<boolean> {
    const safeCode = nodeCode.replace(/[^A-Za-z0-9_-]/g, '');
    if (safeCode.length === 0) return false;
    const token = GuozaokeService.xsrf();
    const response = await GuozaokeService.post(`/t/create/${safeCode}`, `title=${encodeURIComponent(title)}&content=${encodeURIComponent(content)}&_xsrf=${encodeURIComponent(token)}`);
    return response.length > 0;
  }

  static xsrf(): string {
    const item = GuozaokeService.cookie().split(';').find((part: string) => part.trim().startsWith('_xsrf='));
    if (!item) return '';
    return item.trim().substring('_xsrf='.length);
  }

  static async post(path: string, form: string): Promise<string> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(`${BASE_URL}${path}`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/x-www-form-urlencoded', 'Cookie': GuozaokeService.cookie(), 'Referer': BASE_URL + '/' },
        extraData: form,
        connectTimeout: 8000,
        readTimeout: 10000,
        expectDataType: http.HttpDataType.STRING
      });
      return response.result as string;
    } finally { request.destroy(); }
  }

  static async nodes(): Promise<Array<NodeItem>> {
    const html: string = await GuozaokeService.get('/nodes');
    const result: Array<NodeItem> = [];
    const links: Array<string> = html.match(/<a[^>]*href="\/node\/[^\"]+"[^>]*>[\s\S]*?<\/a>/g) ?? [];
    links.forEach((link: string) => {
      const item: NodeItem = new NodeItem();
      item.title = firstMatch(link, />([\s\S]*?)<\/a>/);
      item.code = firstMatch(link, /href="\/node\/([^\"?#]+)(?:[?#][^\"]*)?"/);
      if (item.title.length > 0 && item.code.length > 0 && !result.some((value: NodeItem) => value.code === item.code)) result.push(item);
    });
    return result;
  }

  static async nodeTopics(code: string): Promise<Array<Topic>> {
    const safeCode = code.replace(/[^A-Za-z0-9_-]/g, '');
    return safeCode.length > 0 ? GuozaokeService.parseTopics(await GuozaokeService.get(`/node/${safeCode}`)) : [];
  }

  static async notifications(): Promise<Array<string>> {
    const html: string = await GuozaokeService.get('/notifications');
    const result: Array<string> = [];
    const items: Array<string> = html.match(/<li[^>]*>[\s\S]*?<\/li>/g) ?? [];
    items.forEach((item: string) => {
      // The redesigned site may return login/bootstrap scripts inside list markup.
      // Remove non-content blocks before extracting text so tokens are never shown.
      const content: string = item.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '');
      const value: string = decodeHtml(content.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim());
      const navigation = ['首页', '节点', '成员', '广告投放', '设置', '退出', '登录', '注册'];
      if (value.length > 0 && value.length <= 300 && navigation.indexOf(value) < 0 && !/[A-Za-z0-9+/]{80,}/.test(value)) result.push(value);
    });
    return result;
  }
}
