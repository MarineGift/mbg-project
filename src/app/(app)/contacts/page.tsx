// src/app/(app)/contacts/page.tsx
// Contacts index -- all people across deals and parties.
// Server fetches; client component handles search/filter.
// For 200~500 contacts, client-side filter is fast enough (~10ms).
// Beyond that we'll move to server-side ILIKE with URL search params.

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ContactsTable } from './contacts-table';

export default async function ContactsPage() {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('contacts' as never)
    .select(
      'id, full_name, given_name, family_name, ' +
      'email, phone_e164, phone_mobile, ' +
      'title_text, department, role_category, ' +
      'is_decision_maker, is_primary, is_active, ' +
      'last_contacted_at, ' +
      'firm:parties!party_id(id, party_name, country_code)'
    )
    .is('deleted_at', null)
    .order('full_name', { ascending: true, nullsFirst: false })
    .limit(500);

  return <ContactsTable contacts={(data ?? []) as any[]} />;
}
