export interface User {
  id?: string;
  createdAt: number;
  updatedAt: number;
  languageCode?: string;
  photoURL?: string;
  displayName?: string;
  description?: string;
  gender?: string;
}

export interface Pair {
  id?: string;
  createdAt: number;
  updatedAt: number;
  messageCount: number;
  firstUserId?: string;
  lastMessageContent?: string;
}

export interface Message {
  id?: string;
  userId: string;
  userName: string;
  userCode: string;
  content: string;
  createdAt: number;
}

export interface PairParams {
  messageCount?: number | object;
  firstUserId?: string;
  lastMessageContent?: string;
}

export interface StatParams {
  users?: number | object
  chats?: number | object
  rooms?: number | object
  messages?: number | object
  responses?: number | object
}
