export interface Message {
  id?: string;
  userId: string;
  userName: string;
  userCode: string;
  content: string;
  createdAt: number;
}
