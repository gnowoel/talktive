import { logger } from 'firebase-functions';
import fetch from 'node-fetch';
import { CHATGPT_CONFIG } from '../config';
import { RoomMessage } from '../types';

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
  name?: string;
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
          max_completion_tokens: CHATGPT_CONFIG.maxCompletionToken,
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

  private static convertToContextMessages(messages: RoomMessage[]): ChatMessage[] {
    return messages.map(msg => {
      if (msg.userId === 'bot') {
        return {
          role: 'assistant',
          content: msg.content
        };
      } else {
        return {
          role: 'user',
          // Must not contain special characters
          name: msg.userName.replace(/[\W_]/g, ' ').split(/\s+/).join('_'),
          content: msg.content
        };
      }
    });
  }

  public static async generateResponse(currentMessage: RoomMessage, recentMessages: RoomMessage[] = []): Promise<string | null> {
    try {
      const messages: ChatMessage[] = [
        {
          role: 'system',
          content: CHATGPT_CONFIG.systemPrompt,
        }
      ];

      if (recentMessages.length > 0) {
        const contextMessages = this.convertToContextMessages(
          recentMessages.slice(-CHATGPT_CONFIG.maxContextMessages)
        );
        messages.push(...contextMessages);
      }

      messages.push({
        role: 'user',
        // Must not contain special characters
        name: currentMessage.userName.replace(/[\W_]/g, ' ').split(/\s+/).join('_'),
        content: currentMessage.content
      });

      return await this.callApi(messages);
    } catch (error) {
      // logger.error('Failed to generate response:', error);
      return null;
    }
  }
}
