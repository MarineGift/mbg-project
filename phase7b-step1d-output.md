# Phase 7-b Step 1-d output
Generated: 2026-05-25 17:39:32

## 1. `app.contacts` Row block

Found at L8701 (Row at L8702)

```ts
L8702:         Row: {
L8703:           created_at: string | null
L8704:           created_by: string | null
L8705:           decision_role: Database["app"]["Enums"]["decision_role"] | null
L8706:           deleted_at: string | null
L8707:           department: string | null
L8708:           do_not_contact: boolean | null
L8709:           do_not_contact_reason: string | null
L8710:           email: string | null
L8711:           email_secondary: string | null
L8712:           family_name: string | null
L8713:           full_name: string | null
L8714:           given_name: string | null
L8715:           id: string | null
L8716:           is_active: boolean | null
L8717:           is_primary: boolean | null
L8718:           linkedin_url: string | null
L8719:           module_data: Json | null
L8720:           notes: string | null
L8721:           organization_id: string | null
L8722:           party_id: string | null
L8723:           phone: string | null
L8724:           phone_mobile: string | null
L8725:           preferred_language: string | null
L8726:           seniority: string | null
L8727:           timezone: string | null
L8728:           title: string | null
L8729:           updated_at: string | null
L8730:           updated_by: string | null
L8731:         }
```

**Quick check:**
- `party_id` column: YES
- `is_primary` column: YES

## 2. How other files obtain `organization_id`

Search across src/lib/actions and src/lib/queries for any pattern that
reads or derives organization_id. The most common idiom there is the
canonical replacement for the removed `org_members` lookup.

### 2a. JWT / session-based access

```
--- src\lib\actions\auth.ts L6
   *
>  * 중요: organization_id 검증은 session.access_token (JWT)을 직접 디코드한다.
   *       data.user.app_metadata는 DB의 raw_app_meta_data를 반환하므로

--- src\lib\actions\auth.ts L7
   * 중요: organization_id 검증은 session.access_token (JWT)을 직접 디코드한다.
>  *       data.user.app_metadata는 DB의 raw_app_meta_data를 반환하므로
   *       hook이 주입한 organization_id를 못 본다.

--- src\lib\actions\auth.ts L8
   *       data.user.app_metadata는 DB의 raw_app_meta_data를 반환하므로
>  *       hook이 주입한 organization_id를 못 본다.
   */

--- src\lib\actions\auth.ts L84
  
>   // JWT를 직접 디코드 — hook이 주입한 app_metadata가 여기 있음
    // data.user.app_metadata는 DB의 raw_app_meta_data라서 hook 결과 안 보임

--- src\lib\actions\auth.ts L85
    // JWT를 직접 디코드 — hook이 주입한 app_metadata가 여기 있음
>   // data.user.app_metadata는 DB의 raw_app_meta_data라서 hook 결과 안 보임
    const accessToken = data.session?.access_token;

--- src\lib\actions\auth.ts L90
      const payload = decodeJwtPayload(accessToken);
>     const meta = payload?.app_metadata as Record<string, unknown> | undefined;
      if (typeof meta?.organization_id === 'string') {

--- src\lib\actions\auth.ts L91
      const meta = payload?.app_metadata as Record<string, unknown> | undefined;
>     if (typeof meta?.organization_id === 'string') {
        orgId = meta.organization_id;

--- src\lib\actions\auth.ts L92
      if (typeof meta?.organization_id === 'string') {
>       orgId = meta.organization_id;
      }

--- src\lib\actions\communications.ts L142
    const insertRow: Record<string, unknown> = {
>     organization_id: auth.organizationId,
      channel: 'email',

--- src\lib\actions\communications.ts L229
        .eq('id', outboundId)
>       .eq('organization_id', auth.organizationId);
  

--- src\lib\actions\communications.ts L246
        .eq('id', outboundId)
>       .eq('organization_id', auth.organizationId);
  

--- src\lib\actions\contacts.ts L76
    const insertRow: Record<string, unknown> = {
>     organization_id: auth.organizationId,
      party_id: parsed.data.partyId,

--- src\lib\actions\contacts.ts L165
      .eq('id', parsed.data.contactId)
>     .eq('organization_id', auth.organizationId)
      .select('id')

--- src\lib\actions\contacts.ts L203
      .eq('id', parsed.data.contactId)
>     .eq('organization_id', auth.organizationId)
      .select('id')

--- src\lib\actions\drafts.ts L8
   *   - 모든 액션 첫 줄에 requireAuth() 호출
>  *   - RLS가 organization_id로 자동 격리 (별도 .eq 필요하지 않지만 명시적으로도 추가)
   *   - status 검증: pending_review 한정 approve/reject/edit 가능

--- src\lib\actions\drafts.ts L96
      .eq('id', parsed.data.draftId)
>     .eq('organization_id', auth.organizationId)
      .maybeSingle();

--- src\lib\actions\drafts.ts L119
      .eq('id', parsed.data.draftId)
>     .eq('organization_id', auth.organizationId);
  

--- src\lib\actions\drafts.ts L175
      .eq('id', parsed.data.draftId)
>     .eq('organization_id', auth.organizationId)
      .maybeSingle();

--- src\lib\actions\drafts.ts L212
      .eq('id', row.id)
>     .eq('organization_id', auth.organizationId)
      .eq('status', 'pending_review'); // 동시성 가드 — 다른 요청이 먼저 변경했으면 0행

--- src\lib\actions\drafts.ts L313
      .eq('id', parsed.data.draftId)
>     .eq('organization_id', auth.organizationId)
      .eq('status', 'pending_review');

--- src\lib\actions\drafts.ts L390
      .in('id', parsed.data as string[])
>     .eq('organization_id', auth.organizationId)
      .eq('status', 'pending_review')

--- src\lib\actions\drafts.ts L483
      .in('id', parsed.data.draftIds as string[])
>     .eq('organization_id', auth.organizationId)
      .eq('status', 'pending_review')

--- src\lib\actions\drafts.ts L593
      .eq('id', draft.inbound_communication_id)
>     .eq('organization_id', auth.organizationId)
      .maybeSingle();

--- src\lib\actions\drafts.ts L650
      .insert({
>       organization_id: auth.organizationId,
        channel: 'email',

--- src\lib\actions\drafts.ts L719
        .eq('id', outboundId)
>       .eq('organization_id', auth.organizationId);
  

--- src\lib\actions\drafts.ts L730
        .eq('id', draft.id)
>       .eq('organization_id', auth.organizationId);
  

--- src\lib\actions\drafts.ts L761
        .eq('id', outboundId)
>       .eq('organization_id', organizationId);
    } catch {

--- src\lib\actions\email-compose.ts L114
      .select("html_content")
>     .eq("organization_id", orgId)
      .eq("is_default", true)

--- src\lib\actions\email-compose.ts L187
      .from("org_members")
>     .select("organization_id")
      .eq("user_id", user.id)

--- src\lib\actions\email-compose.ts L192
  
>   const orgId = member.organization_id;
  

```

Total matches: 147

### 2b. Server / supabase helper modules

```
--- src\lib\supabase\admin.ts
L1: /**
L2:  * lib/supabase/admin.ts
L3:  *
L4:  * service_role ?ㅻ? ?ъ슜?섎뒗 Supabase ?대씪?댁뼵??(RLS ?고쉶).
L5:  *
L6:  * ?ъ슜 ?쒗븳:
L7:  *   - STEP 3 ?뚯빱 (consultation-worker, draft-expiry-worker, mail-merge-worker)
L8:  *   - ?몄쬆 肄쒕갚 (?ъ슜???앹꽦 吏곹썑 app.users ??INSERT ??
L9:  *   - ?뱁썒 ?몃뱾??(?몃? ?쒖뒪?????곕━ DB)
L10:  *   - ?덈? ?쇰컲 Server Action?먯꽌 ?ъ슜 湲덉? (?ъ슜??沅뚰븳 ?고쉶 ?꾪뿕)
L11:  *
L12:  * ?몄텧??梨낆엫:
L13:  *   - ?몃? ?낅젰???좊ː?섏? ?딄퀬 紐낆떆?곸쑝濡?organization_id瑜?WHERE???ы븿
L14:  *   - 蹂??대씪?댁뼵?몃줈 ??紐⑤뱺 蹂寃쎌? audit.change_log??湲곕줉?섏?留? *     changed_by媛 NULL???섎?濡??몃젅?댁떛 ?대젮? ??trace_label ?깆쑝濡?蹂댁셿
L15:  */
L16: 
L17: import { createClient } from '@supabase/supabase-js';
L18: import type { Database } from '@/types/database';
L19: import { env } from '@/lib/env';
L20: 
L21: // Stage 28-a: schema generic??'app'?쇰줈 蹂寃?(server.ts/client.ts? ?쇱튂).
L22: type SupabaseAdminDb = ReturnType<typeof createClient<Database, 'app'>>;
L23: 
L24: /** Stage 28-a: caller媛 type annotation 媛?ν븯?꾨줉 export. */
L25: export type SbAdminClient = SupabaseAdminDb;
L26: 
L27: let adminClient: SupabaseAdminDb | null = null;
L28: 
L29: export function createSupabaseAdminClient(): SupabaseAdminDb {
L30:   if (adminClient) return adminClient;
L31: 
L32:   adminClient = createClient<Database, 'app'>(
L33:     env.NEXT_PUBLIC_SUPABASE_URL,
L34:     env.SUPABASE_SERVICE_ROLE_KEY,
L35:     {
L36:       auth: {
L37:         autoRefreshToken: false,
L38:         persistSession: false,
L39:         detectSessionInUrl: false,
L40:       },
L41:     },
L42:   );
L43:   return adminClient;
L44: }

--- src\lib\supabase\client.ts
L1: /**
L2:  * lib/supabase/client.ts
L3:  *
L4:  * Client Component('use client')?먯꽌 ?ъ슜?섎뒗 Supabase ?대씪?댁뼵??
L5:  *
L6:  * ?듭떖:
L7:  *   - ?깃???(釉뚮씪?곗? 硫붾え由ъ뿉 1媛?
L8:  *   - Realtime 梨꾨꼸 援щ룆, ?ㅼ떆媛??좎뒪???깆뿉 ?ъ슜
L9:  *   - ?곌린??Server Action ?ъ슜 沅뚯옣 (RLS ?고쉶 ?꾪뿕 李⑤떒)
L10:  */
L11: 
L12: 'use client';
L13: 
L14: import { createBrowserClient } from '@supabase/ssr';
L15: import type { Database } from '@/types/database';
L16: 
L17: // Stage 28-a: schema generic??'app'?쇰줈 蹂寃?(server.ts? ?쇱튂).
L18: // ?댁쁺 ?뚯씠釉붿? app schema 嫄곗＜, public? RPC functions ?꾩슜.
L19: // SupabaseClient ?쒕꽕由?? ?쇱씠釉뚮윭由?踰꾩쟾???곕씪 ?몄옄 ?섍? ?ㅻ쫫 ??// createBrowserClient??諛섑솚 ??낆쓣 洹몃?濡??ъ슜 (single source of truth).
L20: type SupabaseDb = ReturnType<typeof createBrowserClient<Database, 'app'>>;
L21: 
L22: /** Stage 28-a: caller媛 type annotation 媛?ν븯?꾨줉 export. */
L23: export type SbBrowserClient = SupabaseDb;
L24: 
L25: let browserClient: SupabaseDb | null = null;
L26: 
L27: export function createSupabaseBrowserClient(): SupabaseDb {
L28:   if (browserClient) return browserClient;
L29: 
L30:   // NEXT_PUBLIC_* 蹂?섎뒗 client bundle???몃씪?몃릺誘濡?process.env 吏곸젒 ?묎렐.
L31:   // (lib/env??zod 寃利앹쓣 ?꾪븳 寃껋씠吏留?client bundle?먯꽑 server-only 蹂?섍? throw)
L32:   const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
L33:   const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
L34:   if (!url || !anonKey) {
L35:     throw new Error(
L36:       'NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY must be set in environment',
L37:     );
L38:   }
L39: 
L40:   browserClient = createBrowserClient<Database, 'app'>(url, anonKey);
L41:   return browserClient;
L42: }

--- src\lib\supabase\middleware.ts
L1: /**
L2:  * lib/supabase/middleware.ts
L3:  *
L4:  * Next.js middleware?먯꽌 Supabase ?몄뀡??媛깆떊?섎뒗 ?ы띁.
L5:  *
L6:  * ?듭떖:
L7:  *   - 留??붿껌留덈떎 supabase.auth.getUser() ?몄텧 ??留뚮즺 吏곸쟾 ?좏겙 ?먮룞 媛깆떊
L8:  *   - 媛깆떊??cookie瑜??묐떟??吏곸젒 ?ㅼ젙 (Server Component??cookie ?곌린 遺덇?)
L9:  *   - ?몄쬆?섏? ?딆? ?ъ슜?먮? 蹂댄샇 ?쇱슦?몄뿉??/login?쇰줈 由щ떎?대젆?? */
L10: 
L11: import { createServerClient, type CookieOptions } from '@supabase/ssr';
L12: import { NextResponse, type NextRequest } from 'next/server';
L13: import type { Database } from '@/types/database';
L14: 
L15: /**
L16:  * setAll 肄쒕갚 留ㅺ컻蹂?????
L17:  */
L18: type CookieToSet = { name: string; value: string; options?: CookieOptions };
L19: 
L20: /**
L21:  * 蹂댄샇?섏? ?딅뒗 寃쎈줈 (?몄쬆 遺덊븘??.
L22:  * 洹???紐⑤뱺 寃쎈줈???몄쬆 ?꾩슂 ??誘몄씤利???/login?쇰줈 由щ떎?대젆??
L23:  */
L24: const PUBLIC_PATHS: readonly string[] = [
L25:   '/login',
L26:   '/auth/callback',
L27:   '/auth/error',
L28: ];
L29: 
L30: /**
L31:  * ?뺤쟻 ?먯궛쨌?대? 寃쎈줈 ??middleware媛 ?쇱껜 愿?ы븯吏 ?딆쓬.
L32:  * matcher?먯꽌 1李??쒖쇅?섏?留?蹂닿컯.
L33:  */
L34: function isInternalPath(pathname: string): boolean {
L35:   return (
L36:     pathname.startsWith('/_next/') ||
L37:     pathname.startsWith('/api/') ||
L38:     pathname.startsWith('/favicon') ||
L39:     pathname.includes('.') // ?뺤옣???덈뒗 ?뚯씪
L40:   );
L41: }
L42: 
L43: function isPublicPath(pathname: string): boolean {
L44:   return PUBLIC_PATHS.some(
L45:     (p) => pathname === p || pathname.startsWith(`${p}/`),
L46:   );
L47: }
L48: 
L49: export async function updateSession(
L50:   request: NextRequest,
L51: ): Promise<NextResponse> {
L52:   const pathname = request.nextUrl.pathname;
L53: 
L54:   // ?대? 寃쎈줈??洹몃?濡??듦낵
L55:   if (isInternalPath(pathname)) {
L56:     return NextResponse.next({ request });
L57:   }
L58: 
L59:   let response = NextResponse.next({ request });
L60: 

--- src\lib\supabase\server.ts
L1: /**
L2:  * lib/supabase/server.ts
L3:  *
L4:  * Server Component쨌Server Action쨌Route Handler?먯꽌 ?ъ슜?섎뒗 Supabase ?대씪?댁뼵??
L5:  *
L6:  * ?듭떖:
L7:  *   - cookies()濡?JWT ?몄뀡 ?쎄린쨌媛깆떊
L8:  *   - 留??붿껌留덈떎 ???몄뒪?댁뒪 (long-lived 罹먯떛 湲덉?)
L9:  *   - JWT??app_metadata.organization_id媛 ?먮룞?쇰줈 RLS???곸슜?? *     (013 留덉씠洹몃젅?댁뀡??custom_access_token_hook??二쇱엯)
L10:  */
L11: 
L12: import { createServerClient, type CookieOptions } from '@supabase/ssr';
L13: import type { SupabaseClient } from '@supabase/supabase-js';
L14: import { cookies } from 'next/headers';
L15: import type { Database } from '@/types/database';
L16: import { env } from '@/lib/env';
L17: 
L18: /**
L19:  * setAll 肄쒕갚??留ㅺ컻蹂???????@supabase/ssr 0.5???몃씪???뺥깭? ?쇱튂.
L20:  */
L21: type CookieToSet = { name: string; value: string; options?: CookieOptions };
L22: 
L23: /**
L24:  * Stage 28-a: factory??schema generic??'app'?쇰줈 蹂寃?
L25:  *
L26:  * 諛곌꼍 / Gotcha #45 (Session 11?먯꽌 諛쒓껄):
L27:  *   @supabase/ssr 0.5.x ??createServerClient<Database, SchemaName, Schema> ?? *   諛섑솚 ??낆뿉??generic ?꾩튂媛 ?닿툔????SupabaseClient v2.x ??2踰덉㎏ generic ?
L28:  *   SchemaNameOrClientOptions (string | {PostgrestVersion}), 3踰덉㎏媛 ?ㅼ젣 SchemaName.
L29:  *   createServerClient 媛 SupabaseClient<Database, SchemaName, Schema> 濡?諛섑솚?섎㈃
L30:  *   3踰덉㎏ ?щ’??Schema 媛앹껜媛 ?ㅼ뼱媛踰꾨젮, ?대옒???대??먯꽌 Schema 怨꾩궛??never 濡??⑥뼱吏?
L31:  *   寃곌낵: caller ??.from("parties") 媛 row type = never.
L32:  *
L33:  * Workaround: SbClient 瑜?SupabaseClient<Database, 'app'> 濡?吏곸젒 ?좎뼵 (?⑥씪 generic).
L34:  *   ?대옒???대??먯꽌 SchemaName='app' default 媛 'app' ?쇰줈 ?由ш퀬, Schema 媛 Database['app']
L35:  *   濡??뺤긽 怨꾩궛. factory return ? unknown 寃쎌쑀 cast (?고????숈옉? ?숈씪).
L36:  *
L37:  * - app schema: parties / communications / email_* / contacts / org_members / ...
L38:  * - public: RPC functions only
L39:  * - ?ㅻⅨ schema (ai / audit / urm) ?묎렐? caller 媛 .schema('xxx') 紐낆떆
L40:  */
L41: export type SbClient = SupabaseClient<Database, 'app'>;
L42: 
L43: /**
L44:  * Server Component?먯꽌 ?ъ슜. ?쎄린 ?꾩슜 沅뚯옣(荑좏궎 set??layout/page ?몃??먯꽌???숈옉 ????.
L45:  * Server Action쨌Route Handler?먯꽌???먯쑀濡?쾶 set 媛??
L46:  */
L47: export async function createSupabaseServerClient(): Promise<SbClient> {
L48:   const cookieStore = await cookies();
L49: 
L50:   // ssr ??generic ?닿툔???댁뒋 (??二쇱꽍 李몄“) ?뚮Ц??cast 1??
L51:   // ?고??꾩? ?숈씪?섍쾶 'app' schema 濡??숈옉.
L52:   const client = createServerClient<Database, 'app'>(
L53:     env.NEXT_PUBLIC_SUPABASE_URL,
L54:     env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
L55:     {
L56:       cookies: {
L57:         getAll() {
L58:           return cookieStore.getAll();
L59:         },
L60:         setAll(cookiesToSet: CookieToSet[]) {

```

### 2c. RPC calls that look like "current org" helpers

(no current-org RPC helpers found)

## 3. Files still referencing removed tables

### `org_members`

Total: 4 matches

```ts
--- src\lib\actions\email-compose.ts L186
    const { data: member } = await supabase
>     .from("org_members")
      .select("organization_id")

--- src\lib\actions\email-compose.ts L392
    const { data: member } = await supabase
>     .from("org_members")
      .select("organization_id")

--- src\lib\actions\email-compose.ts L455
    const { data: member } = await supabase
>     .from("org_members")
      .select("organization_id")

--- src\lib\supabase\server.ts L39
   *
>  * - app schema: parties / communications / email_* / contacts / org_members / ...
   * - public: RPC functions only

```

### `party_contacts`

Total: 1 matches

```ts
--- src\lib\actions\email-compose.ts L68
      const { data: primary } = await supabase
>       .from("party_contacts")
        .select("contact_id")

```
