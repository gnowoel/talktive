import { defineString } from 'firebase-functions/params';

export const CHATGPT_CONFIG = {
  apiUrl: defineString('CHATGPT_API_URL', {
    default: 'https://api.openai.com/v1/chat/completions',
    description: 'OpenAI API URL for ChatGPT'
  }),
  apiKey: defineString('CHATGPT_API_KEY', {
    description: 'OpenAI API Key for ChatGPT - REQUIRED for production'
  }),
  model: 'gpt-4o-mini',
  temperature: 0.7,
  maxCompletionToken: 150,
  maxContextMessages: 9,
  systemPrompt: "You are a friendly and engaging chat assistant. Keep responses concise and natural. Encourage conversation without being pushy."
};
