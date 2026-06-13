/**
 * lib/ai/prompt-renderer.ts
 *
 * Converts ClaudeClient's input into the Anthropic Messages API's
 * { system, messages } format.
 *
 * Composed data:
 *   1. agent.systemPrompt           → system
 *   2. brand_voice (module + language match)  -> user-message context bundle
 *   3. knowledge_chunks (vector top_k=8) -> same
 *   4. party context (optional)        -> same
 *   5. thread_history (most recent 5)    -> same
 *   6. inboundMessage              -> same
 *
 * Embedding generation is handled separately in lib/ai/embeddings.ts.
 * (this file provides a buildBundle branch that takes the query embedding as an external argument)
 */

import type Anthropic from '@anthropic-ai/sdk';
import type { SupabaseClient } from '@supabase/supabase-js';
import OpenAI from 'openai';
import { env } from '../env';
import type {
  AgentRow,
  BrandVoiceRow,
  KnowledgeChunkSearchResult,
  Language,
  PartyTypeCode,
} from '../../types/ai';

/* ============================================================
 * 1. Input/output types
 * ============================================================ */

export interface RenderInput {
  supabase: SupabaseClient;
  organizationId: string;
  agent: AgentRow;
  partyId?: string;
  engagementId?: string;
  inboundMessage: string;
  language?: Language;
  /** Embedding precomputed by the caller (for tests or on a cache hit). */
  precomputedEmbedding?: number[];
  /** Additional context (e.g. classification result). */
  extraContext?: Record<string, unknown>;
}

export interface RenderedPrompt {
  system: string;
  messages: Anthropic.MessageParam[];
  metadata: {
    brandVoiceId?: string;
    knowledgeChunkIds: string[];
    threadIds: string[];
    embeddingTokens: number;
  };
}

interface PartyContextSummary {
  id: string;
  name: string;
  partyType?: PartyTypeCode;
  tier?: string;
  countryCode?: string;
  industryTags?: string[];
  moduleData?: Record<string, unknown>;
}

interface ThreadHistoryItem {
  direction: 'inbound' | 'outbound';
  subject?: string;
  excerpt: string;
  occurredAt: string;
  threadId?: string;
}

/* ============================================================
 * 2. OpenAI embedding client (singleton)
 * ----------------------------------------------------------
 * embedQuery is used only inside this module. To pass a query embedding from outside,
 * precompute it and use RenderInput.precomputedEmbedding.
 * ============================================================ */
let openaiSingleton: OpenAI | null = null;
function getOpenAI(): OpenAI {
  if (!openaiSingleton) {
    openaiSingleton = new OpenAI({ apiKey: env.OPENAI_API_KEY });
  }
  return openaiSingleton;
}

export class EmbeddingError extends Error {
  public override readonly cause?: unknown;

  constructor(message: string, cause?: unknown) {
    super(message);
    this.name = 'EmbeddingError';
    this.cause = cause;
  }
}

/**
 * text -> 1536-dimensional embedding vector.
 * Called only for short inputs (normalization: whitespace normalized, truncated to 4000 chars).
 */
export async function embedQuery(
  text: string,
): Promise<{ vector: number[]; tokens: number }> {
  const normalized = (text ?? '').replace(/\s+/g, ' ').trim().slice(0, 4000);
  if (normalized.length === 0) {
    throw new EmbeddingError('embedQuery: empty input');
  }
  try {
    const openai = getOpenAI();
    const resp = await openai.embeddings.create({
      model: env.OPENAI_EMBEDDING_MODEL,
      input: normalized,
    });
    const vector = resp.data[0]?.embedding;
    if (!vector || vector.length === 0) {
      throw new EmbeddingError('embedQuery: empty embedding returned');
    }
    return { vector, tokens: resp.usage?.total_tokens ?? 0 };
  } catch (err) {
    if (err instanceof EmbeddingError) throw err;
    throw new EmbeddingError(
      `embedQuery failed: ${(err as Error).message}`,
      err,
    );
  }
}

/* ============================================================
 * 3. Helper lookup functions
 * ============================================================ */

async function loadBrandVoice(
  supabase: SupabaseClient,
  organizationId: string,
  partyType: PartyTypeCode | undefined,
  language: Language | undefined,
): Promise<BrandVoiceRow | null> {
  if (!partyType || !language) return null;
  const { data, error } = await supabase
    .schema('ai')
    .from('brand_voice')
    .select(
      'id, organization_id, party_type, party_type_id, language, tone_guidelines, do_say, dont_say, glossary, few_shot_examples, is_active, version',
    )
    .eq('organization_id', organizationId)
    .eq('party_type', partyType)
    .eq('language', language)
    .eq('is_active', true)
    .order('version', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[prompt-renderer.loadBrandVoice]', error);
    return null;
  }
  if (!data) return null;
  return {
    id: data.id,
    organizationId: data.organization_id,
    partyType: (data.party_type as PartyTypeCode) ?? partyType,
    language: data.language,
    toneGuidelines: data.tone_guidelines ?? '',
    doSay: data.do_say ?? [],
    dontSay: data.dont_say ?? [],
    glossary: data.glossary ?? {},
    fewShotExamples: data.few_shot_examples ?? [],
    isActive: data.is_active,
    version: data.version,
  };
}

async function loadParty(
  supabase: SupabaseClient,
  partyId: string,
): Promise<PartyContextSummary | null> {
  const { data, error } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name:party_name, country_code, module_data, party_types(code)')
    .eq('id', partyId)
    .maybeSingle();
  if (error || !data) return null;
  return {
    id: data.id,
    name: data.name,
    partyType: (Array.isArray(data.party_types) ? data.party_types[0]?.code : (data.party_types as { code?: string } | null)?.code) ?? undefined,
    tier: undefined,  // D6-5e: parties.tier column dropped
    countryCode: data.country_code ?? undefined,
    industryTags: [],  // D6-5e: parties.industry_tags array dropped (single industry_tag_id FK now)
    moduleData: data.module_data ?? {},
  };
}

async function loadKnowledgeChunks(
  supabase: SupabaseClient,
  organizationId: string,
  queryEmbedding: number[],
  collection: string | undefined,
  limit = 8,
  minSimilarity = 0.65,
): Promise<KnowledgeChunkSearchResult[]> {
  const { data, error } = await supabase.rpc('search_knowledge', {
    p_organization_id: organizationId,
    p_query_embedding: queryEmbedding,
    p_collection: collection ?? null,
    p_limit: limit,
    p_min_similarity: minSimilarity,
  });
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[prompt-renderer.loadKnowledgeChunks]', error);
    return [];
  }
  if (!Array.isArray(data)) return [];
  return data.map((row: Record<string, unknown>) => ({
    id: String(row.id),
    collection: String(row.collection ?? ''),
    content: String(row.content ?? ''),
    similarity: Number(row.similarity ?? 0),
    sourceType: String(row.source_type ?? ''),
    sourceUri: row.source_uri ? String(row.source_uri) : undefined,
    metadata:
      row.metadata && typeof row.metadata === 'object'
        ? (row.metadata as Record<string, unknown>)
        : undefined,
  }));
}

async function loadThreadHistory(
  supabase: SupabaseClient,
  organizationId: string,
  partyId: string | undefined,
  engagementId: string | undefined,
  limit = 5,
): Promise<ThreadHistoryItem[]> {
  const filter = engagementId
    ? { col: 'engagement_id', val: engagementId }
    : partyId
      ? { col: 'party_id', val: partyId }
      : null;
  if (!filter) return [];

  const { data, error } = await supabase
    .schema('app')
    .from('communications')
    .select(
      'direction, subject, body_plain, occurred_at, thread_id, organization_id',
    )
    .eq('organization_id', organizationId)
    .eq(filter.col, filter.val)
    .is('deleted_at', null)
    .order('occurred_at', { ascending: false })
    .limit(limit);

  if (error || !data) return [];
  return data.map((row) => ({
    direction: row.direction as 'inbound' | 'outbound',
    subject: row.subject ?? undefined,
    excerpt: ((row.body_plain ?? '') as string).slice(0, 500),
    occurredAt: row.occurred_at,
    threadId: row.thread_id ?? undefined,
  }));
}

/* ============================================================
 * 4. Main - renderPrompt
 * ============================================================ */

export async function renderPrompt(input: RenderInput): Promise<RenderedPrompt> {
  const {
    supabase,
    organizationId,
    agent,
    partyId,
    engagementId,
    inboundMessage,
    language,
    precomputedEmbedding,
    extraContext,
  } = input;

  // 1. brand_voice (prefers agent.applicableModules[0])
  const PartyTypeCode = agent.applicablePartyTypes?.[0];
  const brandVoice = await loadBrandVoice(
    supabase,
    organizationId,
    PartyTypeCode,
    language,
  );

  // 2. party context
  const party = partyId ? await loadParty(supabase, partyId) : null;

  // 3. embedding + knowledge_chunks
  let embeddingTokens = 0;
  let queryEmbedding = precomputedEmbedding;
  if (!queryEmbedding) {
    try {
      const r = await embedQuery(inboundMessage);
      queryEmbedding = r.vector;
      embeddingTokens = r.tokens;
    } catch (err) {
      // an embedding failure is not fatal - proceed without knowledge_chunks
      // eslint-disable-next-line no-console
      console.warn('[prompt-renderer] embedding failed, continuing without RAG:', err);
      queryEmbedding = undefined;
    }
  }

  const chunks = queryEmbedding
    ? await loadKnowledgeChunks(
        supabase,
        organizationId,
        queryEmbedding,
        agent.knowledgeCollection,
      )
    : [];

  // 4. thread_history
  const threadHistory = await loadThreadHistory(
    supabase,
    organizationId,
    partyId,
    engagementId,
  );

  // 5. compose the context bundle
  const contextBundle = {
    inbound_message: inboundMessage,
    target_language: language ?? null,
    party_context: party,
    brand_voice: brandVoice
      ? {
          tone_guidelines: brandVoice.toneGuidelines,
          do_say: brandVoice.doSay,
          dont_say: brandVoice.dontSay,
          glossary: brandVoice.glossary,
          few_shot_examples: brandVoice.fewShotExamples,
        }
      : null,
    knowledge_chunks: chunks.map((c) => ({
      id: c.id,
      collection: c.collection,
      content: c.content,
      similarity: Number(c.similarity.toFixed(4)),
      source_type: c.sourceType,
      source_uri: c.sourceUri,
    })),
    thread_history: threadHistory,
    extra_context: extraContext ?? null,
  };

  const userMessage: Anthropic.MessageParam = {
    role: 'user',
    content: JSON.stringify(contextBundle, null, 2),
  };

  return {
    system: agent.systemPrompt,
    messages: [userMessage],
    metadata: {
      brandVoiceId: brandVoice?.id,
      knowledgeChunkIds: chunks.map((c) => c.id),
      threadIds: threadHistory
        .map((t) => t.threadId)
        .filter((s): s is string => typeof s === 'string'),
      embeddingTokens,
    },
  };
}

/* ============================================================
 * 5. Liquid variable substitution (for rendering email-template bodies)
 * ----------------------------------------------------------
 * An add-on feature of this module. When an email_templates body has a variable like {{ company_name }},
 * it takes a key-value map and substitutes safely.
 * Exact LiquidJS compatibility is handled in a separate module; here only simple
 * `{{ key }}` substitution is supported.
 * ============================================================ */

/**
 * Liquid-style variable substitution (simple {{ key }} form only).
 * Whitespace variants allowed: `{{key}}`, `{{ key }}`, `{{  key  }}`.
 * Undefined keys are left as the original token rather than replaced with an empty string, so the caller
 * can validate them.
 */
export function renderLiquidVariables(
  template: string,
  variables: Record<string, string | number | undefined>,
): { rendered: string; missingKeys: string[] } {
  const missing: Set<string> = new Set();
  const rendered = template.replace(
    /\{\{\s*([a-zA-Z_][a-zA-Z0-9_.]*)\s*\}\}/g,
    (full, key: string) => {
      const value = variables[key];
      if (value === undefined || value === null) {
        missing.add(key);
        return full; // preserve the token
      }
      return String(value);
    },
  );
  return { rendered, missingKeys: Array.from(missing) };
}
