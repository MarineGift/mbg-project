import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';

export class DraftExpiryWorkerError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'DraftExpiryWorkerError';
  }
}

export async function expireStaleDrafts(
  supabaseInjected?: SupabaseClient,
): Promise<{ expired: number }> {
  const supabase =
    supabaseInjected
    ?? createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

  const { data, error } = await supabase.schema('ai').rpc('expire_stale_drafts');
  if (error) {
    throw new DraftExpiryWorkerError(
      `expire_stale_drafts RPC failed: ${error.message}`,
      error,
    );
  }

  let expired = 0;
  if (typeof data === 'number') {
    expired = data;
  } else if (Array.isArray(data) && data.length > 0) {
    const first = data[0] as Record<string, unknown> | undefined;
    expired = Number(first?.expired_count ?? 0);
  } else if (data && typeof data === 'object') {
    expired = Number((data as Record<string, unknown>).expired_count ?? 0);
  }

  // eslint-disable-next-line no-console
  console.log(
    `[draft-expiry-worker] expired ${expired} drafts at ${new Date().toISOString()}`,
  );
  return { expired };
}

async function main(): Promise<void> {
  try {
    await expireStaleDrafts();
    process.exit(0);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error(
      '[draft-expiry-worker] fatal:',
      (err as Error).message,
    );
    process.exit(1);
  }
}

if (require.main === module) {
  void main();
}
