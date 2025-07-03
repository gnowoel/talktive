import * as admin from 'firebase-admin';

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
  languageCode?: string | null;
  photoURL?: string | null;
  displayName?: string | null;
  description?: string;
  gender?: string | null;
  fcmToken?: string;
  revivedAt?: number | null;
  messageCount?: number | null;
  reportCount?: number | null;
  role?: string | null;
  followeeCount?: number | null;
  followerCount?: number | null;
}

export interface Pair {
  id?: string;
  followers: [string, string];
  createdAt: number;
  updatedAt: number;
  messageCount: number;
  firstUserId?: string | null;
  lastMessageContent?: string | null;
  v2: boolean;
}

export interface Chat {
  id?: string;
  createdAt: number;
  updatedAt: number;
  partner: User;
  messageCount: number;
  readMessageCount?: number;
  firstUserId?: string | null;
  lastMessageContent?: string | null;
  mute?: boolean;
}

export interface Topic {
  id?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  title: string;
  creator: User;
  messageCount: number;
  readMessageCount?: number | null;
  lastMessageContent?: string | null;
  mute?: boolean;
  isPublic?: boolean;
  reportCount?: number;
}

export interface Message {
  id?: string;
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: number;
  type: string;
  reportCount?: number;
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
  users?: number | object;
  chats?: number | object;
  topics?: number | object;
  chatMessages?: number | object;
  topicMessages?: number | object;
  follows?: number | object;
  unfollows?: number | object;
}

export interface PartnerParams {
  revivedAt?: number | object;
}

export interface ReportParams {
  status?: string;
  revivedAt?: number;
}

export interface Follow {
  id?: string;
  createdAt: number;
  updatedAt: number;
  user: {
    createdAt: number;
    updatedAt: number;
    photoURL: string | null;
    displayName: string | null;
    description: string | null;
    languageCode: string | null;
    gender: string | null;
  };
}

export interface FollowRequest {
  followerId: string;
  followeeId: string;
}

export interface MessageReport {
  id?: string;
  chatId: string;
  messageId: string;
  messageAuthorId: string;
  reporterUserId: string;
  createdAt: number;
  status: 'pending' | 'resolved';
}
