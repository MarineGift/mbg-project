/**
 * lib/ai/prompt-renderer.ts
 *
 * ClaudeClient의 입력을 Anthropic Messages API의
 * { system, messages } 포맷으로 변환한다.
 *
 * 합성 데이터:
 *   1. agent.systemPrompt           → system
 *   2. brand_voice (모듈+언어 매칭)  → 사용자 메시지 컨텍스트 번들
 *   3. knowledge_chunks (vector top_k=8) → 동일
 *   4. party 컨텍스트 (선택)        → 동일
 *   5. thread_history (최근 5개)    → 동일
 *   6. inboundMessage              → 동일
 *
 * 임베딩 생성은 lib/ai/embeddings.ts에서 별도 처리.
 * (본 파일에서는 query embedding을 외부 인자로 받는 buildBundle 분기 제공)
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
 * 1. 입출력 타입
 * ============================================================ */

export interface RenderInput {
  supabase: SupabaseClient;
  organizationId: string;
  agent: AgentRow;
  partyId?: string;
  engagementId?: string;
  inboundMessage: string;
  language?: Language;
  /** 호출자가 미리 계산한 임베딩(테스트용 또는 캐시 적중 시). */
  precomputedEmbedding?: number[];
  /** 추가 컨텍스트(예: classification 결과). */
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
 * 2. OpenAI 임베딩 클라이언트 (싱글턴)
 * ----------------------------------------------------------
 * embedQuery는 본 모듈 내부에서만 사용. 외부에서 query embedding을
 * 미리 계산해 넘기려면 RenderInput.precomputedEmbedding 사용.
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
 * 텍스트 → 1536차원 임베딩 벡터.
 * 짧은 입력에 한해 호출 (정규화: 공백 정규화, 4000자로 절단).
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
 * 3. 보조 조회 함수
 * ============================================================ */

async function loadBrandVoice(
  supabase: SupabaseClient,
  organizationId: string,
  partyType: PartyTypeCode | undefined,
  language: Language | undefined,
): Promise<BrandVoiceRow | null> {
  if (!module || !language) return null;
  const { data, error } = await supabase
    .schema('ai')
    .from('brand_voice')
    .select(
      'id, organization_id, module, language, tone_guidelines, do_say, dont_say, glossary, few_shot_examples, is_active, version',
    )
    .eq('organization_id', organizationId)
    .eq('module', module)
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
    partyType: data.partyType,
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
    .select('id, name, module, tier, country_code, industry_tags, module_data')
    .eq('id', partyId)
    .maybeSingle();
  if (error || !data) return null;
  return {
    id: data.id,
    name: data.name,
    partyType: data.partyType ?? undefined,
    tier: data.tier ?? undefined,
    countryCode: data.country_code ?? undefined,
    industryTags: data.industry_tags ?? [],
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
 * 4. 메인 — renderPrompt
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

  // 1. brand_voice (agent.applicableModules[0]을 우선 사용)
  const PartyTypeCode = agent.applicableModules?.[0];
  const brandVoice = await loadBrandVoice(
    supabase,
    organizationId,
    PartyTypeCode,
    language,
  );

  // 2. party 컨텍스트
  const party = partyId ? await loadParty(supabase, partyId) : null;

  // 3. 임베딩 + knowledge_chunks
  let embeddingTokens = 0;
  let queryEmbedding = precomputedEmbedding;
  if (!queryEmbedding) {
    try {
      const r = await embedQuery(inboundMessage);
      queryEmbedding = r.vector;
      embeddingTokens = r.tokens;
    } catch (err) {
      // 임베딩 실패는 치명적이지 않음 — knowledge_chunks 없이 진행
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

  // 5. 컨텍스트 번들 합성
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
 * 5. Liquid 변수 치환 (이메일 템플릿 본문 렌더링용)
 * ----------------------------------------------------------
 * 본 모듈의 부가 기능. email_templates의 본문에 {{ company_name }}
 * 같은 변수가 있을 때, 키-값 맵을 받아 안전하게 치환.
 * 정확한 LiquidJS 호환은 별도 모듈에서 처리하고, 여기는 단순
 * `{{ key }}` 치환만 지원.
 * ============================================================ */

/**
 * Liquid-스타일 변수 치환(단순 {{ key }} 형태만).
 * 공백 변형 허용: `{{key}}`, `{{ key }}`, `{{  key  }}`.
 * 미정의 키는 빈 문자열로 치환하지 않고 토큰 그대로 남겨, 호출자가
 * 검증할 수 있게 한다.
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
        return full; // 토큰 보존
      }
      return String(value);
    },
  );
  return { rendered, missingKeys: Array.from(missing) };
}
