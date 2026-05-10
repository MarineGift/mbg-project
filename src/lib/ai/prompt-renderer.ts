import type { SupabaseClient } from '@supabase/supabase-js';
import type Anthropic from '@anthropic-ai/sdk';
import type {
  AgentRow,
  BrandVoiceRow,
  KnowledgeChunkRow,
} from '@/types/ai';
import { toBrandVoiceRow } from '@/types/ai';
import { env } from '@/lib/env';

export interface RenderedPrompt {
  system: string;
  messages: Anthropic.Messages.MessageParam[];
  metadata: {
    brandVoiceId?: string;
    knowledgeChunkIds: string[];
    threadCommunicationIds: string[];
  };
}

export interface RenderPromptInput {
  supabase: SupabaseClient;
  organizationId: string;
  agent: AgentRow;
  partyId?: string;
  engagementId?: string;
  inboundMessage: string;
  language?: 'ko' | 'en' | 'ja';
  module?: string;
  generateEmbedding?: (text: string) => Promise<number[]>;
}

const KNOWLEDGE_TOP_K = 8;
const THREAD_RECENT_LIMIT = 5;
const MAX_INBOUND_FOR_EMBEDDING = 4_000;

export function applyLiquidVariables(
  template: string,
  values: Readonly<Record<string, string | number | undefined | null>>,
): string {
  return template.replace(/\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/g, (_, key: string) => {
    const v = values[key];
    if (v === undefined || v === null) return '';
    return String(v);
  });
}

export async function renderPrompt(input: RenderPromptInput): Promise<RenderedPrompt> {
  const { supabase, organizationId, agent } = input;

  const brandVoice = await loadBrandVoice(
    supabase,
    organizationId,
    input.module,
    input.language,
  );

  const knowledgeChunks = await loadKnowledgeChunks(
    supabase,
    organizationId,
    agent.knowledgeCollection,
    input.inboundMessage,
    input.generateEmbedding,
  );

  const threadHistory = await loadRecentThread(
    supabase,
    organizationId,
    input.partyId,
    input.engagementId,
  );

  const systemParts: string[] = [agent.systemPrompt.trim()];

  if (brandVoice) {
    systemParts.push('');
    systemParts.push('=== BRAND VOICE ===');
    systemParts.push(brandVoice.toneDescription);
    if (brandVoice.signatureBlock) {
      systemParts.push('');
      systemParts.push('=== SIGNATURE BLOCK ===');
      systemParts.push(brandVoice.signatureBlock);
    }
    if (brandVoice.fewShotExamples.length > 0) {
      systemParts.push('');
      systemParts.push('=== FEW-SHOT EXAMPLES ===');
      for (const [i, ex] of brandVoice.fewShotExamples.slice(0, 5).entries()) {
        systemParts.push(`[Example ${i + 1}]`);
        systemParts.push(`Inbound: ${ex.inbound}`);
        systemParts.push(`Outbound: ${ex.outbound}`);
        if (ex.note) systemParts.push(`Note: ${ex.note}`);
        systemParts.push('');
      }
    }
  }

  const system = systemParts.join('\n');

  const contextBundle = {
    inbound_message: input.inboundMessage,
    language: input.language ?? null,
    module: input.module ?? null,
    party_id: input.partyId ?? null,
    engagement_id: input.engagementId ?? null,
    knowledge: knowledgeChunks.map((c) => ({
      id: c.id,
      title: c.title ?? null,
      content: c.content,
      similarity: Number(c.similarity.toFixed(4)),
    })),
    thread_history: threadHistory.map((c) => ({
      id: c.id,
      direction: c.direction,
      from: c.from_address,
      subject: c.subject,
      body_excerpt: truncate(c.body_plain ?? '', 800),
      occurred_at: c.occurred_at,
    })),
  };

  const userMessage =
    'Process the following inbound message according to your role.\n' +
    'Respond strictly in the format defined by your system prompt.\n\n' +
    '<context>\n' +
    JSON.stringify(contextBundle, null, 2) +
    '\n</context>';

  return {
    system,
    messages: [{ role: 'user', content: userMessage }],
    metadata: {
      brandVoiceId: brandVoice?.id,
      knowledgeChunkIds: knowledgeChunks.map((c) => c.id),
      threadCommunicationIds: threadHistory.map((c) => c.id),
    },
  };
}

interface ThreadCommunicationRow {
  id: string;
  direction: 'inbound' | 'outbound';
  from_address: string | null;
  subject: string | null;
  body_plain: string | null;
  occurred_at: string;
}

async function loadBrandVoice(
  supabase: SupabaseClient,
  organizationId: string,
  module: string | undefined,
  language: 'ko' | 'en' | 'ja' | undefined,
): Promise<BrandVoiceRow | null> {
  if (module && language) {
    const { data, error } = await supabase
      .schema('ai')
      .from('brand_voice')
      .select('*')
      .eq('organization_id', organizationId)
      .eq('module', module)
      .eq('language', language)
      .order('is_default', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (!error && data) return toBrandVoiceRow(data as Record<string, unknown>);
  }

  if (language) {
    const { data, error } = await supabase
      .schema('ai')
      .from('brand_voice')
      .select('*')
      .eq('organization_id', organizationId)
      .eq('language', language)
      .eq('is_default', true)
      .limit(1)
      .maybeSingle();
    if (!error && data) return toBrandVoiceRow(data as Record<string, unknown>);
  }

  const { data, error } = await supabase
    .schema('ai')
    .from('brand_voice')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('is_default', true)
    .limit(1)
    .maybeSingle();
  if (error || !data) return null;
  return toBrandVoiceRow(data as Record<string, unknown>);
}

async function loadKnowledgeChunks(
  supabase: SupabaseClient,
  organizationId: string,
  collection: string | undefined,
  inboundMessage: string,
  generateEmbedding: ((text: string) => Promise<number[]>) | undefined,
): Promise<KnowledgeChunkRow[]> {
  if (!generateEmbedding) return [];

  const queryText = inboundMessage.length > MAX_INBOUND_FOR_EMBEDDING
    ? inboundMessage.slice(0, MAX_INBOUND_FOR_EMBEDDING)
    : inboundMessage;

  let embedding: number[];
  try {
    embedding = await generateEmbedding(queryText);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.warn('[prompt-renderer] embedding failed, skipping RAG:', (err as Error).message);
    return [];
  }

  const { data, error } = await supabase.schema('ai').rpc('match_knowledge_chunks', {
    p_organization_id: organizationId,
    p_collection: collection ?? null,
    p_embedding: embedding,
    p_match_count: KNOWLEDGE_TOP_K,
  });

  if (error || !Array.isArray(data)) {
    // eslint-disable-next-line no-console
    console.warn('[prompt-renderer] knowledge RPC failed:', error?.message);
    return [];
  }

  return (data as Array<Record<string, unknown>>).map((row) => ({
    id: String(row.id),
    organizationId: String(row.organization_id ?? organizationId),
    collection: typeof row.collection === 'string' ? row.collection : undefined,
    title: typeof row.title === 'string' ? row.title : undefined,
    content: String(row.content ?? ''),
    similarity: Number(row.similarity ?? 0),
    metadata: (row.metadata as Record<string, unknown>) ?? undefined,
  }));
}

async function loadRecentThread(
  supabase: SupabaseClient,
  organizationId: string,
  partyId: string | undefined,
  engagementId: string | undefined,
): Promise<ThreadCommunicationRow[]> {
  if (!partyId && !engagementId) return [];

  let query = supabase
    .schema('app')
    .from('communications')
    .select('id, direction, from_address, subject, body_plain, occurred_at')
    .eq('organization_id', organizationId)
    .is('deleted_at', null)
    .order('occurred_at', { ascending: false })
    .limit(THREAD_RECENT_LIMIT);

  if (engagementId) {
    query = query.eq('engagement_id', engagementId);
  } else if (partyId) {
    query = query.eq('party_id', partyId);
  }

  const { data, error } = await query;
  if (error || !Array.isArray(data)) return [];

  return (data as ThreadCommunicationRow[]).slice().reverse();
}

function truncate(text: string, max: number): string {
  if (text.length <= max) return text;
  return text.slice(0, max) + '…';
}

void env;
