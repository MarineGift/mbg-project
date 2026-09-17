/**
 * lib/ai/openai-chat.ts
 *
 * The ONLY place the app calls an AI API.
 * Used only when the user presses "Generate AI reply" in the compose dialog
 * (lib/actions/email-compose.ts -> generateAIReply). Nothing runs automatically.
 *
 * Railway variables (web service):
 *   OPENAI_API_KEY      required for the button to work
 *   OPENAI_REPLY_MODEL  optional, default gpt-5-mini
 */

import OpenAI from 'openai';
import { env } from '../env';

/** gpt-5*, o1/o3/o4 are reasoning models: no temperature, max_completion_tokens. */
function isReasoningModel(model: string): boolean {
  return /^(gpt-5|o\d)/i.test(model);
}

/** Original gpt-5 / -mini / -nano accept 'minimal'; newer gpt-5.x use 'low'. */
function reasoningEffortFor(model: string): 'minimal' | 'low' {
  return /^gpt-5(-mini|-nano)?(-\d{4}-\d{2}-\d{2})?$/i.test(model) ? 'minimal' : 'low';
}

let client: OpenAI | null = null;

export async function generateReply(input: {
  system: string;
  user: string;
  maxTokens: number;
}): Promise<string> {
  if (!env.OPENAI_API_KEY) {
    throw new Error('OPENAI_API_KEY is not set');
  }
  client ??= new OpenAI({ apiKey: env.OPENAI_API_KEY, maxRetries: 1, timeout: 60_000 });

  const model = env.OPENAI_REPLY_MODEL;
  const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
    { role: 'system', content: input.system },
    { role: 'user', content: input.user },
  ];

  const params: OpenAI.Chat.ChatCompletionCreateParamsNonStreaming = isReasoningModel(model)
    ? (() => {
        const effort = reasoningEffortFor(model);
        return {
          model,
          messages,
          // reasoning tokens count against this budget - leave headroom above 'minimal'
          max_completion_tokens: input.maxTokens + (effort === 'minimal' ? 0 : 2000),
          reasoning_effort: effort as OpenAI.Chat.ChatCompletionCreateParams['reasoning_effort'],
        };
      })()
    : { model, messages, max_tokens: input.maxTokens };

  const res = await client.chat.completions.create(params);
  return res.choices?.[0]?.message?.content ?? '';
}
