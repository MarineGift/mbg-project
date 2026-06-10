import { createClient } from '@supabase/supabase-js';

export function webAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );
}

export async function getSiteId(slug = 'marinebiogroup'): Promise<string | null> {
  const sb = webAdminClient();
  const { data } = await sb
    .schema('web')
    .from('sites' as never)
    .select('id')
    .eq('slug', slug)
    .maybeSingle();
  return (data as { id?: string } | null)?.id ?? null;
}