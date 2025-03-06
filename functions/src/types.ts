export interface Report {
  id?: string;
  chatId: string;
  createdAt: number;
  partnerDisplayName: string;
  status: string;
  userId: string;
  revivedAt?: number;
}

export interface User {
  id?: string;
  createdAt: number;
  updatedAt: number;
  languageCode?: string|null;
  photoURL?: string|null;
  displayName?: string|null;
  description?: string;
  gender?: string|null;
  fcmToken?: string;
  revivedAt?: number|null;
  messageCount?: number|null;
}

export interface Pair {
  id?: string;
  followers: [string, string];
  createdAt: number;
  updatedAt: number;
  messageCount: number;
  firstUserId?: string|null;
  lastMessageContent?: string|null;
  v2: boolean;
}

export interface Chat {
  id?: string;
  createdAt: number;
  updatedAt: number;
  partner: User;
  messageCount: number;
  readMessageCount?: number;
  firstUserId?: string|null;
  lastMessageContent?: string|null;
  mute?: boolean;
}

export interface RoomMessage {
  id?: string;
  userId: string;
  userName: string;
  userCode: string;
  content: string;
  createdAt: number;
}

export interface Message {
  id?: string;
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: number;
  type: string;
}

export interface UserParams {
  updatedAt?: number;
  messageCount?: number | object;
}

export interface PairParams {
  updatedAt?: number;
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

export interface PartnerParams {
  revivedAt?: number | object;
}

export interface ReportParams {
  status?: string;
  revivedAt?: number;
}
