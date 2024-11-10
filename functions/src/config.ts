import { defineString } from 'firebase-functions/params';

export const CHATGPT_CONFIG = {
  apiUrl: defineString('CHATGPT_API_URL'), // 'https://api.openai.com/v1/chat/completions'
  apiKey: defineString('CHATGPT_API_KEY'),
  model: 'gpt-4o-mini',
  temperature: 0.7,
  maxTokens: 150,
  maxContextMessages: 10,
  systemPrompt: "You are a young female chat assistant acting as a close virtual girlfriend.",
};
