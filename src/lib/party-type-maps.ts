/**
 * lib/party-type-maps.ts
 *
 * DB-backed party_type id <-> code maps. Replaces the hardcoded
 * PARTY_TYPE_ID_BY_CODE / PARTY_TYPE_CODE_BY_ID objects that used to live in
 * types/party-type.ts and had to be edited by hand every time a party_type was
 * added to app.party_types (the root cause of the mentor id/404 drift).
 *
 * The mapping is read from app.party_types and cached at module scope. That
 * table is effectively static configuration, so a single fetch per server
 * instance / browser session is plenty. Call clearPartyTypeMapsCache() if you
 * ever mutate party_types at runtime and need the change reflected immediately.
 *
 * Works with either the server or the browser Supabase client (both expose
 * .schema('app').from('party_types')). Typed as `any` on purpose so the same
 * helper serves both without importing client-specific generics.
 */

export type PartyTypeMaps = {
  idToCode: Record<number, string>;
  codeToId: Record<string, number>;
};

let cache: PartyTypeMaps | null = null;
let inflight: Promise<PartyTypeMaps> | null = null;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function fetchPartyTypeMaps(supabase: any): Promise<PartyTypeMaps> {
  if (cache) return cache;
  if (inflight) return inflight;

  inflight = (async () => {
    try {
      const { data } = await supabase
        .schema('app')
        .from('party_types')
        .select('id, code');

      const idToCode: Record<number, string> = {};
      const codeToId: Record<string, number> = {};
      for (const r of ((data ?? []) as Array<{ id: number; code: string }>)) {
        if (r?.id == null || !r.code) continue;
        idToCode[r.id] = r.code;
        codeToId[r.code] = r.id;
      }
      cache = { idToCode, codeToId };
      return cache;
    } finally {
      inflight = null;
    }
  })();

  return inflight;
}

/** Reset the cached maps (use after changing app.party_types at runtime). */
export function clearPartyTypeMapsCache(): void {
  cache = null;
  inflight = null;
}
