import { createSupabaseServerClient } from '@/lib/supabase/server';

export async function NavUnreadBadge() {
  try {
    const supabase = await createSupabaseServerClient();
    const { count } = await supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .eq('direction', 'inbound')
      .is('read_at' as any, null);
    if (!count || count === 0) return null;
    return (
      <span className="ml-auto inline-flex items-center justify-center rounded-full bg-primary text-primary-foreground text-[11px] font-semibold min-w-[20px] h-5 px-1.5 tabular-nums leading-none">
        {count > 99 ? '99+' : count}
      </span>
    );
  } catch (_) {
    return null;
  }
}