export interface User {
  id?: string;
  createdAt: number;
  updatedAt: number;
  languageCode?: string;
  photoURL?: string;
  displayName?: string;
  description?: string;
  genger?: string;
}

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
