import { http } from '@kit.NetworkKit';
import { webview } from '@kit.ArkWeb';
import { Topic } from '../model/Topic';

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

export class GuozaokeService {
  static cookie(): string {
    try {
      return webview.WebCookieManager.fetchCookieSync(BASE_URL);
    } catch (_) {
      return '';
    }
  }

  static isLoggedIn(): boolean {
    return GuozaokeService.cookie().split(';').some((item: string) => item.trim().startsWith('user='));
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
        expectDataType: http.HttpDataType.STRING
      });
      return response.result as string;
    } finally {
      request.destroy();
    }
  }

  static async topics(tab: string = ''): Promise<Array<Topic>> {
    const html: string = await GuozaokeService.get(tab.length > 0 ? `/?tab=${tab}` : '/');
    const cards: Array<string> = html.match(/<div[^>]*class="[^"]*topic-item[^"]*"[\s\S]*?(?=<div[^>]*class="[^"]*topic-item|<\/main>|<\/body>)/g) ?? [];
    const result: Array<Topic> = [];
    cards.forEach((card: string) => {
      const topic: Topic = new Topic();
      topic.id = firstMatch(card, /href="\/t\/(\d+)/);
      topic.title = firstMatch(card, /<h3[^>]*class="[^"]*title[^"]*"[^>]*>[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/);
      topic.author = firstMatch(card, /class="[^"]*username[^"]*"[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/);
      topic.node = firstMatch(card, /class="[^"]*node[^"]*"[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/);
      topic.avatar = firstMatch(card, /<img[^>]*src="([^"]+)"[^>]*class="[^"]*avatar[^"]*"/).replace('//static/', '/static/');
      topic.replies = firstMatch(card, /class="[^"]*count[^"]*"[\s\S]*?<a[^>]*>([\s\S]*?)<\/a>/) || '0';
      if (topic.id.length > 0 && topic.title.length > 0) {
        result.push(topic);
      }
    });
    return result;
  }

  static async topicDetail(id: string): Promise<string> {
    const html: string = await GuozaokeService.get(`/t/${id}`);
    const content: string = firstMatch(html,
      /<div[^>]*class="[^"]*ui-content[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>/);
    return content.length > 0 ? content : '暂时无法解析主题内容';
  }

  static async nodes(): Promise<Array<string>> {
    const html: string = await GuozaokeService.get('/nodes');
    const result: Array<string> = [];
    const links: Array<string> = html.match(/<a[^>]*href="\/node\/[^\"]+"[^>]*>[\s\S]*?<\/a>/g) ?? [];
    links.forEach((link: string) => { const value: string = firstMatch(link, />([\s\S]*?)<\/a>/); if (value.length > 0 && result.indexOf(value) < 0) result.push(value); });
    return result;
  }

  static async search(query: string): Promise<Array<Topic>> {
    return GuozaokeService.topics(`search=${encodeURIComponent(query)}`);
  }

  static async notifications(): Promise<Array<string>> {
    const html: string = await GuozaokeService.get('/notifications');
    const result: Array<string> = [];
    const items: Array<string> = html.match(/<li[^>]*>[\s\S]*?<\/li>/g) ?? [];
    items.forEach((item: string) => { const value: string = decodeHtml(item.replace(/<[^>]+>/g, '').trim()); if (value.length > 0) result.push(value); });
    return result;
  }
}
