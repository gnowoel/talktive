export interface Message {
  id?: string;
  userId: string;
  userName: string;
  userCode: string;
  content: string;
  createdAt: number;
}

export interface StatParams {
  users?: number | object
  rooms?: number | object
  messages?: number | object
  responses?: number | object
}
