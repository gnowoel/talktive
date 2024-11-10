import { logger } from 'firebase-functions';
import fetch from 'node-fetch';
import { CHATGPT_CONFIG } from '../config';

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface ApiResponse {
  choices: Array<{
    message: {
      content: string;
    };
  }>;
}

export class ChatGPTService {
  private static async callApi(messages: ChatMessage[]): Promise<string> {
    try {
      const response = await fetch(CHATGPT_CONFIG.apiUrl.value(), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${CHATGPT_CONFIG.apiKey.value()}`,
        },
        body: JSON.stringify({
          model: CHATGPT_CONFIG.model,
          messages,
          temperature: CHATGPT_CONFIG.temperature,
          max_tokens: CHATGPT_CONFIG.maxTokens,
        }),
      });

      if (!response.ok) {
        throw new Error(`API call failed with status: ${response.status}`);
      }

      const data = await response.json() as ApiResponse;
      return data.choices[0].message.content.trim();
    } catch (error) {
      logger.error('ChatGPT API error:', error);
      throw error;
    }
  }

  public static async generateResponse(userMessage: string): Promise<string> {
    const messages: ChatMessage[] = [
      { role: 'system', content: CHATGPT_CONFIG.systemPrompt },
      { role: 'user', content: userMessage }
    ];

    try {
      return await this.callApi(messages);
    } catch (error) {
      logger.error('Failed to generate response:', error);
      return "I apologize, but I'm having trouble responding right now. Please try again later.";
    }
  }
}
