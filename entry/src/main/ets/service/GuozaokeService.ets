import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { webview } from '@kit.ArkWeb';
import { Topic } from '../model/Topic';
import { CommentItem } from '../model/CommentItem';
import { NodeItem } from '../model/NodeItem';
import { UserProfile } from '../model/UserProfile';
import { NotificationItem } from '../model/NotificationItem';
import { TopicDetailData } from '../model/TopicDetailData';
import { TopicListResult } from '../model/TopicListResult';
import { NotificationListResult } from '../model/NotificationListResult';
import { CommentListResult } from '../model/CommentListResult';

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

function firstRawMatch(source: string, expression: RegExp): string {
  const matched: RegExpMatchArray | null = source.match(expression);
  return matched && matched.length > 1 ? matched[1].trim() : '';
}

function numberMatch(source: string, expression: RegExp): number {
  const value: string = firstMatch(source, expression).replace(/[^0-9]/g, '');
  return value.length > 0 ? Number(value) : 0;
}

function asciiBytes(value: string): Uint8Array {
  const result = new Uint8Array(value.length);
  for (let index = 0; index < value.length; index += 1) result[index] = value.charCodeAt(index) & 0xFF;
  return result;
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

function pagePath(basePath: string, page: number): string {
  if (page <= 1) return basePath;
  return `${basePath}${basePath.indexOf('?') >= 0 ? '&' : '?'}p=${page}`;
}

function hasNextPage(html: string, page: number): boolean {
  const nextPage: number = page + 1;
  if (new RegExp(`(?:[?&]|&amp;)(?:p|page)=${nextPage}(?:[&"'#]|&amp;|$)`, 'i').test(html)) return true;

  const pagination = html.match(/<(?:ul|nav|div)[^>]*class=["'][^"']*pagination[^"']*["'][^>]*>[\s\S]*?<\/(?:ul|nav|div)>/i);
  if (!pagination) return false;
  const nextItem = pagination[0].match(/<(?:li|a)[^>]*>[\s\S]*?(?:下一页|下页|next|›|»)[\s\S]*?<\/(?:li|a)>/i);
  return !!nextItem && !/class=["'][^"']*(?:disabled|is-disabled)[^"']*["']|aria-disabled=["']true["']/i.test(nextItem[0]);
}

function topicPageFromHtml(html: string, page: number): TopicListResult {
  const result: TopicListResult = new TopicListResult();
  result.topics = GuozaokeService.parseTopics(html);
  result.hasMore = result.topics.length > 0 && hasNextPage(html, page);
  return result;
}

function appendNode(result: Array<NodeItem>, codeValue: string, titleValue: string): void {
  let decodedCode: string = codeValue;
  try { decodedCode = decodeURIComponent(codeValue); } catch (_) { }
  const code: string = decodedCode.replace(/[^A-Za-z0-9_-]/g, '');
  const title: string = decodeHtml(titleValue).replace(/\s+/g, ' ').trim();
  if (code.length === 0 || title.length === 0 || result.some((node: NodeItem) => node.code === code)) return;
  const item: NodeItem = new NodeItem();
  item.code = code;
  item.title = title;
  result.push(item);
}

function parseNodes(html: string, result: Array<NodeItem>): void {
  const links: Array<string> = html.match(/<a\b[^>]*href=["'][^"']*(?:\/node\/|\/t\/create\/)[^"']+["'][^>]*>[\s\S]*?<\/a>/gi) ?? [];
  links.forEach((link: string) => {
    const target = link.match(/href=["'][^"']*(?:\/node\/|\/t\/create\/)([A-Za-z0-9_-]+)(?:[?#][^"']*)?["']/i);
    const title = link.match(/>([\s\S]*?)<\/a>/i);
    if (target && title) appendNode(result, target[1], title[1]);
  });

  const options: Array<string> = html.match(/<option\b[^>]*value=["'][^"']+["'][^>]*>[\s\S]*?<\/option>/gi) ?? [];
  options.forEach((option: string) => {
    const value = option.match(/value=["']([^"']+)["']/i);
    const title = option.match(/>([\s\S]*?)<\/option>/i);
    if (!value || !title) return;
    const code = value[1].match(/(?:\/node\/|\/t\/create\/)?([A-Za-z0-9_-]+)(?:[?#].*)?$/i);
    if (code) appendNode(result, code[1], title[1]);
  });
}

export class GuozaokeService {
  static parseTopics(html: string): Array<Topic> {
    const cards: Array<string> = html.match(/<div[^>]*class=["'][^"']*topic-item[^"']*["'][\s\S]*?(?=<div[^>]*class=["'][^"']*topic-item|<\/main>|<\/body>)/gi) ?? [];
    const result: Array<Topic> = [];
    cards.forEach((card: string) => {
      const topic: Topic = new Topic();
      topic.id = firstMatch(card, /href=["']\/t\/(\d+)/i);
      topic.title = firstMatch(card, /<h3[^>]*class=["'][^"']*title[^"']*["'][^>]*>[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/i);
      topic.author = firstMatch(card, /class=["'][^"']*username[^"']*["'][\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/i);
      topic.node = firstMatch(card, /class=["'][^"']*node[^"']*["'][\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/i);
      const avatarTag = card.match(/<(?:img|image)\b[^>]*class=["'][^"']*avatar[^"']*["'][^>]*>/i);
      topic.avatar = avatarTag ? avatarFromHtml(avatarTag[0]) : avatarFromHtml(card);
      topic.replies = firstMatch(card, /class=["'][^"']*count[^"']*["'][\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/i) || '0';
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

  static async topicPage(tab: string = '', page: number = 1): Promise<TopicListResult> {
    const basePath: string = tab.length > 0 ? `/?tab=${encodeURIComponent(tab)}` : '/';
    return topicPageFromHtml(await GuozaokeService.get(pagePath(basePath, page)), page);
  }

  static async topics(tab: string = '', page: number = 1): Promise<Array<Topic>> {
    return (await GuozaokeService.topicPage(tab, page)).topics;
  }

  /**
   * 今日热议 is rendered as a small sidebar on the H5 home page rather than
   * as a separate tab. Keep the native entry backed by that same live markup,
   * so the list follows the website without hard-coded topic IDs.
   */
  static async hotTopics(): Promise<Array<Topic>> {
    const html: string = await GuozaokeService.get('/');
    const links: Array<string> = html.match(/<span[^>]*class=["'][^"']*hot_topic_title[^"']*["'][^>]*>[\s\S]*?<a[^>]*href=["']\/t\/(\d+)(?:#[^"']*)?["'][^>]*>[\s\S]*?<\/a>[\s\S]*?<\/span>/gi) ?? [];
    const result: Array<Topic> = [];
    links.forEach((link: string) => {
      const id = firstMatch(link, /href=["']\/t\/(\d+)/i);
      const title = firstMatch(link, /<a[^>]*>([\s\S]*?)<\/a>/i);
      if (id.length === 0 || title.length === 0 || result.some((item: Topic) => item.id === id)) return;
      const item: Topic = new Topic();
      item.id = id;
      item.title = title;
      item.replies = '热议';
      result.push(item);
    });
    return result;
  }

  static async searchTopics(keyword: string, page: number = 1): Promise<TopicListResult> {
    const value = keyword.trim();
    const empty = new TopicListResult();
    if (value.length === 0) return empty;
    const encoded = encodeURIComponent(value);
    // Keep the request compatible with both the redesigned H5 search form
    // and the legacy route still used by some cached pages.
    const paths: Array<string> = [
      `/search?q=${encoded}`,
      `/search?keyword=${encoded}`,
      `/search?query=${encoded}`,
      `/?q=${encoded}`
    ];
    for (const path of paths) {
      try {
        const html = await GuozaokeService.get(pagePath(path, page));
        // Some deployments redirect an unknown search route to the home page.
        // Never expose that page as a false-positive search result: retain only
        // cards whose title, author, node, or excerpt contains the keyword.
        const cards: Array<string> = html.match(/<div[^>]*class=["'][^"']*topic-item[^"']*["'][\s\S]*?(?=<div[^>]*class=["'][^"']*topic-item|<\/main>|<\/body>)/gi) ?? [];
        const needle = value.toLocaleLowerCase();
        const matchedCards = cards.filter((card: string) => decodeHtml(card).toLocaleLowerCase().indexOf(needle) >= 0);
        if (matchedCards.length > 0) {
          const result = topicPageFromHtml(matchedCards.join('\n'), page);
          if (result.topics.length > 0) return result;
        }
      } catch (_) { }
    }
    return empty;
  }

  static async userTopicPage(kind: string, page: number = 1): Promise<TopicListResult> {
    const profile = await GuozaokeService.selfProfileUrl();
    const match = profile.match(/\/u\/([A-Za-z0-9_-]+)/);
    if (!match) return new TopicListResult();
    return GuozaokeService.userTopicPageFor(match[1], kind, page);
  }

  static async userTopicPageFor(username: string, kind: string, page: number = 1): Promise<TopicListResult> {
    const safeName = username.replace(/[^A-Za-z0-9_-]/g, '');
    if (safeName.length === 0) return new TopicListResult();
    const html: string = await GuozaokeService.get(pagePath(`/u/${safeName}/${kind}`, page));
    return topicPageFromHtml(html, page);
  }

  static async userTopics(kind: string, page: number = 1): Promise<Array<Topic>> {
    return (await GuozaokeService.userTopicPage(kind, page)).topics;
  }

  static async userTopicsFor(username: string, kind: string, page: number = 1): Promise<Array<Topic>> {
    return (await GuozaokeService.userTopicPageFor(username, kind, page)).topics;
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
    profile.followed = /class=["'][^"']*label-success[^"']*["'][\s\S]*?取消关注/i.test(scope);
    profile.blocked = /解除屏蔽/i.test(html);
    return profile;
  }

  static async toggleFollow(username: string): Promise<boolean> {
    const safeName = username.replace(/[^A-Za-z0-9_-]/g, '');
    if (safeName.length === 0) return false;
    await GuozaokeService.get(`/f/user/${safeName}`);
    return (await GuozaokeService.userProfile(safeName)).followed;
  }

  static async toggleBlock(username: string, memberNumber: string, currentlyBlocked: boolean): Promise<boolean> {
    const safeName = username.replace(/[^A-Za-z0-9_-]/g, '');
    const number = memberNumber.replace(/[^0-9]/g, '');
    if (safeName.length === 0 || number.length === 0) return currentlyBlocked;
    await GuozaokeService.get(`/u/${number}/${currentlyBlocked ? 'unblock' : 'block'}`);
    return (await GuozaokeService.userProfile(safeName)).blocked;
  }

  static async blockedUsers(): Promise<Array<UserProfile>> {
    const html = await GuozaokeService.get('/setting/blockedUser');
    const blocks: Array<string> = html.match(/<div[^>]*class=["'][^"']*member[^"']*["'][^>]*>[\s\S]*?(?=<div[^>]*class=["'][^"']*member[^"']*["']|<\/main>|<\/body>)/gi) ?? [];
    const users: Array<UserProfile> = [];
    blocks.forEach((block: string) => {
      const user = new UserProfile();
      const usernameMatch = block.match(/<span[^>]*class=["'][^"']*username[^"']*["'][^>]*>[\s\S]*?<a[^>]*href=["']\/u\/([A-Za-z0-9_-]+)["']/i);
      user.username = usernameMatch ? usernameMatch[1] : '';
      const avatarTag = block.match(/<img[^>]*class=["'][^"']*avatar[^"']*["'][^>]*>/i);
      user.avatar = avatarTag ? avatarFromHtml(avatarTag[0]) : '';
      if (user.username.length > 0) users.push(user);
    });
    return users;
  }

  static async topicDetail(id: string): Promise<TopicDetailData> {
    const html: string = await GuozaokeService.get(`/t/${id}`);
    const detail: TopicDetailData = new TopicDetailData();
    const headerMatch = html.match(/<div[^>]*class=["'][^"']*topic-detail[^"']*["'][\s\S]*?<div[^>]*class=["'][^"']*ui-header[^"']*["'][\s\S]*?(?=<div[^>]*class=["'][^"']*ui-content)/i);
    const header: string = headerMatch ? headerMatch[0] : html;
    const avatarTag = header.match(/<img[^>]*class=["'][^"']*avatar[^"']*["'][^>]*>/i);
    detail.avatar = avatarTag ? avatarFromHtml(avatarTag[0]) : '';
    detail.author = firstMatch(header,
      /<span[^>]*class=["'][^"']*username[^"']*["'][^>]*>[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/i);
    const nodeLink = header.match(/<span[^>]*class=["'][^"']*node[^"']*["'][^>]*>[\s\S]*?<a[^>]*href=["']\/node\/([^"'?#]+)[^"']*["'][^>]*>([\s\S]*?)<\/a>/i);
    if (nodeLink) {
      detail.nodeCode = decodeHtml(nodeLink[1]);
      detail.nodeTitle = decodeHtml(nodeLink[2]);
    }
    detail.createdTime = firstMatch(header,
      /<span[^>]*class=["'][^"']*(?:created-time|last-reply-time)[^"']*["'][^>]*>([\s\S]*?)<\/span>/i);
    const editLink = html.match(/<a[^>]*href=["']([^"']*(?:\/t\/\d+\/edit|\/t\/edit\/\d+)[^"']*)["'][^>]*>[\s\S]*?编辑主题[\s\S]*?<\/a>/i);
    detail.editUrl = editLink && editLink.length > 1 ? editLink[1] : '';
    const visible = decodeHtml(html.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, ''))
      .replace(/\s+/g, ' ');
    const editedMatch = visible.match(/本帖最后于\s*([^<\n]{1,80}?)\s*编辑/i);
    detail.editedTime = editedMatch && editedMatch.length > 1 ? editedMatch[1].trim() : '';
    detail.viewCount = numberMatch(visible, /(\d[\d,]*)\s*次点击/i);
    detail.favoriteCount = numberMatch(visible, /(\d[\d,]*)\s*人收藏/i);
    detail.voteCount = numberMatch(visible, /(\d[\d,]*)\s*人赞/i);
    const topicVote = html.match(/<a[^>]*class=["'][^"']*(?:J_topicVote|topic-vote)[^"']*["'][^>]*href=["']([^"']+)["'][^>]*>/i);
    detail.voteUrl = topicVote && topicVote.length > 1 ? topicVote[1] : '';
    detail.voted = /(?:已赞|取消赞|unvote)/i.test(visible);
    // Keep the structural markup here. TopicPage converts it to readable
    // native text while preserving paragraphs, lists and image placeholders.
    // Running this through firstMatch() used to remove tags too early and
    // concatenate every paragraph into one visually broken block.
    detail.content = firstRawMatch(html,
      /<div[^>]*class="[^"]*ui-content[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>/);
    if (detail.content.length === 0) detail.content = '暂时无法解析主题内容';
    const contentImages: Array<string> = detail.content.match(/<img\b[^>]*>/gi) ?? [];
    contentImages.forEach((tag: string) => {
      const url = avatarFromHtml(tag);
      if (url.length > 0 && !detail.images.includes(url)) detail.images.push(url);
    });
    return detail;
  }

  static async topicCommentPage(id: string, page: number = 1): Promise<CommentListResult> {
    // The Android client requests the first paginated detail page for comments;
    // the redesigned site omits the reply list from the bare /t/:id response.
    let html: string = await GuozaokeService.get(`/t/${id}?p=${page}`);
    // Some CDN edges serve the anti-bot shell for the paginated URL only.
    // Retry the canonical detail response before presenting a false empty list.
    if (page === 1 && !/(reply-item|topic-reply|J_replyVote|comment-content|reply-content)/i.test(html)) {
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
      if (vote) {
        item.voteUrl = vote[1];
        item.voteCount = Number(vote[2]);
        const replyId = vote[1].match(/[?&]reply_id=(\d+)/i);
        if (replyId) item.id = replyId[1];
      }
      const editLink = block.match(/<(?:a|button)[^>]*(?:href|data-href)=["']([^"']*\/reply\/edit\/\d+[^"']*)["'][^>]*>[\s\S]*?编辑回复[\s\S]*?<\/(?:a|button)>/i);
      item.editUrl = editLink && editLink.length > 1 ? editLink[1] : '';
      item.editable = item.editUrl.length > 0;
      // Preserve block markup until the native view formats it. Otherwise
      // <br>, <p> and <li> boundaries disappear and replies run together.
      item.content = firstRawMatch(block, /<(?:span|div)[^>]*class=["'][^"']*content[^"']*["'][^>]*>([\s\S]*?)<\/(?:span|div)>/i);
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
    const pageResult: CommentListResult = new CommentListResult();
    pageResult.items = result;
    pageResult.hasMore = result.length > 0 && hasNextPage(html, page);
    return pageResult;
  }

  static async topicComments(id: string, page: number = 1): Promise<Array<CommentItem>> {
    return (await GuozaokeService.topicCommentPage(id, page)).items;
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
    const token = await GuozaokeService.xsrfFor(`/t/${id}`);
    if (token.length === 0) return false;
    const response = await GuozaokeService.post(`/t/${id}`, `tid=${encodeURIComponent(id)}&content=${encodeURIComponent(content)}&_xsrf=${encodeURIComponent(token)}`, `${BASE_URL}/t/${id}`);
    // A successful POST is followed by the topic HTML, which can legitimately
    // contain words such as “失败” in another user's reply. Only reject an
    // explicit auth/error page so a valid emoji reply is not reported as failed.
    return response.length > 0 && !GuozaokeService.isAuthOrErrorPage(response);
  }

  static async editComment(replyId: string, content: string): Promise<boolean> {
    const safeId = replyId.replace(/[^0-9]/g, '');
    if (safeId.length === 0) return false;
    const token = await GuozaokeService.xsrfFor(`/reply/edit/${safeId}`);
    if (token.length === 0) return false;
    const form = `rid=${encodeURIComponent(safeId)}&content=${encodeURIComponent(content)}&_xsrf=${encodeURIComponent(token)}`;
    const response = await GuozaokeService.post(`/reply/edit/${safeId}`, form, `${BASE_URL}/reply/edit/${safeId}`);
    // A successful edit redirects away from the form. Directly requesting the
    // edit URL afterwards is not a reliable verification because the site
    // redirects that GET back to the topic page; trust the POST response and
    // only reject an explicit auth/error page.
    return response.length > 0 && !GuozaokeService.isAuthOrErrorPage(response);
  }

  static async replyEditDraft(replyId: string): Promise<string> {
    const safeId = replyId.replace(/[^0-9]/g, '');
    if (safeId.length === 0) return '';
    try {
      const html = await GuozaokeService.get(`/reply/edit/${safeId}`);
      const textarea = html.match(/<textarea[^>]*>([\s\S]*?)<\/textarea>/i);
      if (textarea && textarea.length > 1) return decodeHtml(textarea[1]).replace(/\r\n/g, '\n').trim();
      const value = html.match(/<textarea[^>]*value=["']([^"']*)["'][^>]*>/i);
      return value && value.length > 1 ? decodeHtml(value[1]).replace(/\r\n/g, '\n').trim() : '';
    } catch (_) {
      return '';
    }
  }

  static async newTopic(nodeCode: string, title: string, content: string): Promise<boolean> {
    const safeCode = nodeCode.replace(/[^A-Za-z0-9_-]/g, '');
    if (safeCode.length === 0) return false;
    const createPath = `/t/create/${safeCode}`;
    const token = await GuozaokeService.xsrfFor(createPath);
    if (token.length === 0) return false;
    const response = await GuozaokeService.post(createPath,
      `title=${encodeURIComponent(title)}&content=${encodeURIComponent(content)}&_xsrf=${encodeURIComponent(token)}`,
      `${BASE_URL}${createPath}`);
    return response.length > 0 && !GuozaokeService.isAuthOrErrorPage(response);
  }

  static async editTopic(id: string, title: string, content: string): Promise<boolean> {
    const safeId = id.replace(/[^0-9]/g, '');
    if (safeId.length === 0) return false;
    // The redesigned site uses /t/edit/:id. The old /t/:id/edit path can
    // return a normal topic page without applying the submitted form, which
    // made the native editor report success while a refresh showed old data.
    const editPath = `/t/edit/${safeId}`;
    const token = await GuozaokeService.xsrfFor(editPath);
    if (token.length === 0) return false;
    const form = `title=${encodeURIComponent(title)}&content=${encodeURIComponent(content)}&_xsrf=${encodeURIComponent(token)}`;
    const response = await GuozaokeService.post(editPath, form, `${BASE_URL}${editPath}`);
    // A successful edit redirects to the topic page. Do not re-fetch the edit
    // form here: the redesigned site redirects direct GETs of that form back
    // to the topic page, which made a real edit look like a failed save.
    return response.length > 0 && !GuozaokeService.isAuthOrErrorPage(response);
  }

  static async uploadImage(uri: string, apiKey: string): Promise<string> {
    if (uri.length === 0 || apiKey.trim().length === 0) return '';
    const boundary = `----GuozaokeHarmony${Date.now()}`;
    let file: fileIo.File | undefined;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const size = fileIo.statSync(file.fd).size;
      if (size <= 0 || size > 15 * 1024 * 1024) return '';
      const bytes = new ArrayBuffer(size);
      fileIo.readSync(file.fd, bytes);
      const head = asciiBytes(`--${boundary}\r\nContent-Disposition: form-data; name="smfile"; filename="guozaoke-${Date.now()}.jpg"\r\nContent-Type: image/jpeg\r\n\r\n`);
      const tail = asciiBytes(`\r\n--${boundary}--\r\n`);
      const body = new Uint8Array(head.byteLength + bytes.byteLength + tail.byteLength);
      body.set(head, 0);
      body.set(new Uint8Array(bytes), head.byteLength);
      body.set(tail, head.byteLength + bytes.byteLength);
      const request: http.HttpRequest = http.createHttp();
      try {
        const response: http.HttpResponse = await request.request('https://sm.ms/api/v2/upload', {
          method: http.RequestMethod.POST,
          header: {
            'Authorization': apiKey.trim(),
            'Content-Type': `multipart/form-data; boundary=${boundary}`,
            'Accept': 'application/json'
          },
          extraData: body.buffer,
          connectTimeout: 12000,
          readTimeout: 120000,
          expectDataType: http.HttpDataType.STRING
        });
        const text: string = response.result as string;
        const url = text.match(/"url"\s*:\s*"(https?:\\?\/\\?\/[^"\\]+)"/i);
        return url && url.length > 1 ? url[1].replace(/\\\//g, '/') : '';
      } finally { request.destroy(); }
    } catch (_) {
      return '';
    } finally {
      if (file) { try { fileIo.closeSync(file); } catch (_) {} }
    }
  }

  static xsrf(): string {
    const item = GuozaokeService.cookie().split(';').find((part: string) => part.trim().startsWith('_xsrf='));
    if (!item) return '';
    return item.trim().substring('_xsrf='.length);
  }

  static async xsrfFor(path: string): Promise<string> {
    const cookieToken = GuozaokeService.xsrf();
    if (cookieToken.length > 0) return cookieToken;
    try {
      const html = await GuozaokeService.get(path);
      const field = html.match(/<input[^>]*name=["']_xsrf["'][^>]*value=["']([^"']+)["'][^>]*>/i) ||
        html.match(/<input[^>]*value=["']([^"']+)["'][^>]*name=["']_xsrf["'][^>]*>/i);
      return field && field.length > 1 ? field[1] : '';
    } catch (_) {
      return '';
    }
  }

  static isAuthOrErrorPage(html: string): boolean {
    // Normal topic pages contain instructional text such as “登录后回复”.
    // Matching the bare phrase “登录后” made successful POST responses look
    // like auth failures, so only treat explicit error prompts or login forms
    // as failures.
    return /(?:无权访问|权限不足|禁止访问|forbidden)/i.test(html) ||
      /<form[^>]+(?:login|signin)[^>]*>/i.test(html) ||
      /<title[^>]*>[^<]*(?:登录|错误|失败)[^<]*<[/]title>/i.test(html);
  }

  static async post(path: string, form: string, referer: string = BASE_URL + '/'): Promise<string> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(`${BASE_URL}${path}`, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': GuozaokeService.cookie(),
          'Referer': referer,
          'User-Agent': 'Mozilla/5.0 (HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        },
        extraData: form,
        connectTimeout: 8000,
        readTimeout: 10000,
        expectDataType: http.HttpDataType.STRING
      });
      const body: string = (response.result || '') as string;
      // The site normally answers form submissions with a 302 redirect. On
      // some HarmonyOS builds the redirect body is empty even though the
      // request was accepted, which used to surface as a false “保存失败” or
      // make a comment tap look like it did nothing. Preserve a successful
      // HTTP status as a small response marker so callers can distinguish it
      // from an actual transport/auth failure.
      if (body.length > 0) return body;
      const code: number = response.responseCode;
      // Some device builds expose responseCode as 0 after following the
      // redirect, while the server has already accepted the form. No thrown
      // request error plus an empty body is therefore still a completed POST.
      return code >= 200 && code < 400 ? `__HTTP_OK__${code}` : '__HTTP_OK__';
    } finally { request.destroy(); }
  }

  static async nodes(): Promise<Array<NodeItem>> {
    const result: Array<NodeItem> = [];
    parseNodes(await GuozaokeService.get('/nodes'), result);
    // The authenticated create page may expose posting destinations that are
    // hidden from the public node cloud. Merge both live catalogues.
    if (GuozaokeService.isLoggedIn()) {
      try { parseNodes(await GuozaokeService.get('/t/create'), result); } catch (_) { }
    }
    return result;
  }

  static async nodeTopicPage(code: string, page: number = 1): Promise<TopicListResult> {
    const safeCode = code.replace(/[^A-Za-z0-9_-]/g, '');
    if (safeCode.length === 0) return new TopicListResult();
    const html: string = await GuozaokeService.get(pagePath(`/node/${safeCode}`, page));
    return topicPageFromHtml(html, page);
  }

  static async nodeTopics(code: string, page: number = 1): Promise<Array<Topic>> {
    return (await GuozaokeService.nodeTopicPage(code, page)).topics;
  }

  static async notificationPage(page: number = 1): Promise<NotificationListResult> {
    const html: string = await GuozaokeService.get(pagePath('/notifications', page));
    const result: Array<NotificationItem> = [];
    const blocks: Array<string> = html.match(/<div[^>]*class=["'][^"']*notification-item[^"']*["'][\s\S]*?(?=<div[^>]*class=["'][^"']*notification-item|<ul[^>]*class=["'][^"']*pagination|<\/main>|<\/body>)/gi) ?? [];
    blocks.forEach((block: string) => {
      const item: NotificationItem = new NotificationItem();
      const userLink = block.match(/<a[^>]*href=["']\/u\/([A-Za-z0-9_-]+)["'][^>]*>[\s\S]*?<\/a>/i);
      if (userLink) {
        item.author = userLink[1];
        const avatarTag = userLink[0].match(/<img[^>]*>/i);
        item.avatar = avatarTag ? avatarFromHtml(avatarTag[0]) : '';
      }
      const titleBlock = block.match(/<span[^>]*class=["'][^"']*title[^"']*["'][^>]*>([\s\S]*?)<\/span>/i);
      if (titleBlock) {
        item.type = /提到了你/.test(decodeHtml(titleBlock[1])) ? '提到了你' : '回复了你';
        const topic = titleBlock[1].match(/<a[^>]*href=["']\/t\/(\d+)(?:#[^"']*)?["'][^>]*>([\s\S]*?)<\/a>/i);
        if (topic) { item.topicId = topic[1]; item.topicTitle = decodeHtml(topic[2]); }
      }
      item.content = firstMatch(block, /<div[^>]*class=["'][^"']*content[^"']*["'][^>]*>([\s\S]*?)<\/div>/i);
      if (item.author.length > 0 && item.topicId.length > 0) result.push(item);
    });
    const pageResult: NotificationListResult = new NotificationListResult();
    pageResult.items = result;
    pageResult.hasMore = result.length > 0 && hasNextPage(html, page);
    return pageResult;
  }

  static async notifications(page: number = 1): Promise<Array<NotificationItem>> {
    return (await GuozaokeService.notificationPage(page)).items;
  }
}
