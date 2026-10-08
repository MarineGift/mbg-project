'use server';

/**
 * Mentor actions.
 * setMentorGender - records a CONFIRMED gender for a mentor (app.mentors.gender).
 * Default is 'unknown' (shown as "Unconfirmed"); only set male/female when it
 * has been confirmed (own pronouns on a profile, direct contact, etc.).
 */

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

const schema = z.object({
  partyId: z.string().uuid(),
  gender: z.enum(['male', 'female', 'unknown']),
});

export async function setMentorGender(
  partyId: string,
  gender: 'male' | 'female' | 'unknown',
): Promise<{ ok: boolean; errorMessage?: string }> {
  try { await requireAuth(); } catch { return { ok: false, errorMessage: 'unauthorized' }; }
  const parsed = schema.safeParse({ partyId, gender });
  if (!parsed.success) return { ok: false, errorMessage: 'invalid input' };

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('mentors' as never)
    .update({ gender: parsed.data.gender, updated_at: new Date().toISOString() } as never)
    .eq('party_id' as never, parsed.data.partyId);
  if (error) return { ok: false, errorMessage: error.message };

  revalidatePath('/mentor/parties');
  revalidatePath(`/mentor/parties/${parsed.data.partyId}`);
  return { ok: true };
}
