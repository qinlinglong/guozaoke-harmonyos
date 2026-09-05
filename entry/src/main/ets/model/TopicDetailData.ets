export class TopicDetailData {
  content: string = '';
  author: string = '';
  avatar: string = '';
  nodeTitle: string = '';
  nodeCode: string = '';
  createdTime: string = '';
  editedTime: string = '';
  images: Array<string> = [];
  editUrl: string = '';
  viewCount: number = 0;
  favoriteCount: number = 0;
  voteCount: number = 0;
  voteUrl: string = '';
  voted: boolean = false;
}
