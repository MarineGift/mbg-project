/**
 * lib/ai/openai-chat.ts
 *
 * Single place that talks to the OpenAI Chat Completions API for text
 * generation (the app previously used the Anthropic API for this).
 *
 * ai.agents rows still store the legacy model "tier" ids
 * (claude-opus-4-7 / claude-sonnet-4-6 / claude-haiku-4-5-20251001).
 * They are NOT sent to any provider any more; they are mapped to OpenAI
 * models here, so no DB migration is needed:
 *
 *   tier (ai.agents.model)       env override          default
 *   claude-opus-4-7          ->  OPENAI_MODEL_OPUS     gpt-5-mini
 *   claude-sonnet-4-6        ->  OPENAI_MODEL_SONNET   gpt-5-mini
 *   claude-haiku-4-5-20251001 -> OPENAI_MODEL_HAIKU    gpt-5-nano
 *
 * Defaults are chosen for low cost. Change them in Railway variables
 * without a code change.
 */

import OpenAI from 'openai';
import { env } from '../env';
import type { ClaudeModel } from '../../types/ai';

export type ChatMessage = { role: 'user' | 'assistant'; content: string };

const TIER_TO_ENV: Readonly<Record<ClaudeModel, () => string>> = {
  'claude-opus-4-7': () => env.OPENAI_MODEL_OPUS,
  'claude-sonnet-4-6': () => env.OPENAI_MODEL_SONNET,
  'claude-haiku-4-5-20251001': () => env.OPENAI_MODEL_HAIKU,
};

/** Legacy tier id (or an explicit OpenAI model id) -> OpenAI model id. */
export function resolveOpenAiModel(model: ClaudeModel | string): string {
  const fromTier = TIER_TO_ENV[model as ClaudeModel];
  return fromTier ? fromTier() : model;
}

/** gpt-5*, o1/o3/o4 are reasoning models: no temperature, max_completion_tokens. */
export function isReasoningModel(model: string): boolean {
  return /^(gpt-5|o\d)/i.test(model);
}

/**
 * The original gpt-5 / gpt-5-mini / gpt-5-nano accept reasoning_effort
 * 'minimal' (cheapest). Newer families (gpt-5.x) do not, so they get 'low'.
 */
function reasoningEffortFor(model: string): 'minimal' | 'low' {
  return /^gpt-5(-mini|-nano)?(-\d{4}-\d{2}-\d{2})?$/i.test(model)
    ? 'minimal'
    : 'low';
}

export interface BuildChatParamsInput {
  model: string;
  system: string;
  messages: ChatMessage[];
  maxTokens: number;
  temperature?: number;
}

/** Build a Chat Completions request body that is valid for the given model. */
export function buildChatParams(
  input: BuildChatParamsInput,
): OpenAI.Chat.ChatCompletionCreateParamsNonStreaming {
  const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
    { role: 'system', content: input.system },
    ...input.messages.map((m) => ({ role: m.role, content: m.content })),
  ];

  if (isReasoningModel(input.model)) {
    const effort = reasoningEffortFor(input.model);
    // Reasoning tokens count against max_completion_tokens; leave headroom
    // when the effort is above 'minimal' so the visible answer is not cut off.
    const budget = input.maxTokens + (effort === 'minimal' ? 0 : 2000);
    return {
      model: input.model,
      messages,
      max_completion_tokens: budget,
      // cast: 'minimal' is newer than some SDK type definitions
      reasoning_effort: effort as OpenAI.Chat.ChatCompletionCreateParams['reasoning_effort'],
    };
  }

  return {
    model: input.model,
    messages,
    max_tokens: input.maxTokens,
    ...(input.temperature !== undefined ? { temperature: input.temperature } : {}),
  };
}

export function extractChatText(res: OpenAI.Chat.ChatCompletion): string {
  return res.choices?.[0]?.message?.content ?? '';
}

let singleton: OpenAI | null = null;

/** Shared OpenAI client for text generation (SDK retries disabled by default). */
export function getOpenAiClient(opts: { maxRetries?: number; timeoutMs?: number } = {}): OpenAI {
  if (opts.maxRetries !== undefined || opts.timeoutMs !== undefined) {
    return new OpenAI({
      apiKey: env.OPENAI_API_KEY,
      maxRetries: opts.maxRetries ?? 0,
      timeout: opts.timeoutMs ?? 60_000,
    });
  }
  if (!singleton) {
    singleton = new OpenAI({ apiKey: env.OPENAI_API_KEY, maxRetries: 2, timeout: 60_000 });
  }
  return singleton;
}

/**
 * One-shot text generation for simple server actions (compose / reply draft).
 * Note: these calls are not written to ai.runs (same as before the switch).
 */
export async function generateText(input: {
  tier: ClaudeModel;
  system: string;
  user: string;
  maxTokens: number;
}): Promise<string> {
  const model = resolveOpenAiModel(input.tier);
  const res = await getOpenAiClient().chat.completions.create(
    buildChatParams({
      model,
      system: input.system,
      messages: [{ role: 'user', content: input.user }],
      maxTokens: input.maxTokens,
    }),
  );
  return extractChatText(res);
}
