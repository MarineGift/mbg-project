# Phase 7-b Step 1-c output
Generated: 2026-05-25 17:24:44

Goal: confirm whether each candidate table EXISTS in database.ts.
If yes --- show its Row block so we can decide ALTER vs no-op.
If no --- DROP+RECREATE is truly needed.

## 1. Candidate tables --- existence and columns

### `org_members`

**Status: NOT FOUND in database.ts**

Action: DROP+CREATE (or first-time CREATE) is required.

### `party_contacts`

**Status: NOT FOUND in database.ts**

Action: DROP+CREATE (or first-time CREATE) is required.

### `email_signatures`

**Status: NOT FOUND in database.ts**

Action: DROP+CREATE (or first-time CREATE) is required.

### `email_whitelist`

**Status: FOUND at L2741 (Row at L2742)**

```ts
L2742:         Row: {
L2743:           created_at: string
L2744:           created_by: string | null
L2745:           id: string
L2746:           is_active: boolean
L2747:           kind: string
L2748:           notes: string | null
L2749:           organization_id: string
L2750:           pattern: string
L2751:         }
```

### `email_templates`

**Status: FOUND at L2437 (Row at L2438)**

```ts
L2438:         Row: {
L2439:           body_html: string | null
L2440:           body_plain: string
L2441:           category: string | null
L2442:           created_at: string
L2443:           created_by: string | null
L2444:           id: string
L2445:           is_active: boolean
L2446:           module: string | null
L2447:           name: string
L2448:           organization_id: string
L2449:           subject: string
L2450:           updated_at: string
L2451:         }
```

### `email_tracking`

**Status: FOUND at L2490 (Row at L2491)**

```ts
L2491:         Row: {
L2492:           click_count: number
L2493:           communication_id: string | null
L2494:           contact_id: string | null
L2495:           created_at: string
L2496:           draft_id: string | null
L2497:           first_opened_at: string | null
L2498:           id: string
L2499:           open_count: number
L2500:           open_token: string
L2501:           org_id: string
L2502:           party_id: string | null
L2503:           sent_at: string
L2504:           sent_to: string
L2505:           subject: string | null
L2506:         }
```

### `email_tracking_events`

**Status: FOUND at L2661 (Row at L2662)**

```ts
L2662:         Row: {
L2663:           created_at: string
L2664:           event_type: string
L2665:           id: string
L2666:           ip: string | null
L2667:           link_id: string | null
L2668:           tracking_id: string
L2669:           url: string | null
L2670:           user_agent: string | null
L2671:         }
```

### `email_sequence_sends`

**Status: FOUND at L2286 (Row at L2287)**

```ts
L2287:         Row: {
L2288:           communication_id: string | null
L2289:           enrollment_id: string
L2290:           id: string
L2291:           organization_id: string
L2292:           sent_at: string
L2293:           status: Database["app"]["Enums"]["send_status"]
L2294:           step_id: string
L2295:           step_order: number
L2296:         }
```

### `organizations`

**Status: FOUND at L4868 (Row at L4869)**

```ts
L4869:         Row: {
L4870:           allowed_modules: Database["app"]["Enums"]["module_type"][]
L4871:           country_code: string | null
L4872:           created_at: string
L4873:           default_currency: string
L4874:           default_language: string
L4875:           default_timezone: string
L4876:           deleted_at: string | null
L4877:           domain: string | null
L4878:           id: string
L4879:           logo_url: string | null
L4880:           name: string
L4881:           plan: string
L4882:           plan_expires_at: string | null
L4883:           settings: Json
L4884:           slug: string
L4885:           updated_at: string
L4886:         }
```

### `drafts`

**Status: FOUND at L233 (Row at L234)**

```ts
L234:         Row: {
L235:           agent_id: string
L236:           ai_generated: boolean
L237:           auto_send_blocked_reasons: string[]
L238:           auto_send_eligible: boolean
L239:           auto_send_evaluation_log: Json
L240:           auto_send_rule_id: string | null
L241:           body_html: string | null
L242:           body_plain: string
L243:           classification_category: string | null
L244:           classifier_run_id: string | null
L245:           confidence_score: number | null
L246:           contact_id: string | null
L247:           created_at: string
L248:           drafter_run_id: string | null
L249:           edit_distance: number | null
L250:           engagement_id: string | null
L251:           expired_handled: boolean
L252:           expires_at: string
L253:           final_body_plain: string | null
L254:           final_subject: string | null
L255:           id: string
L256:           inbound_communication_id: string | null
L257:           language: string
L258:           module: Database["app"]["Enums"]["module_type"] | null
L259:           organization_id: string
L260:           party_id: string | null
L261:           rationale: string | null
L262:           requires_human_approval: boolean
L263:           review_notes: string | null
L264:           reviewed_at: string | null
L265:           reviewed_by_user_id: string | null
L266:           risk_flags: string[]
L267:           run_id: string | null
L268:           sent_communication_id: string | null
L269:           status: Database["ai"]["Enums"]["draft_status"]
L270:           subject: string | null
L271:           updated_at: string
L272:         }
```

### `attachments`

**Status: FOUND at L611 (Row at L612)**

```ts
L612:         Row: {
L613:           content_hash_sha256: string | null
L614:           deleted_at: string | null
L615:           description: string | null
L616:           entity_id: string
L617:           entity_type: string
L618:           expires_at: string | null
L619:           file_name: string
L620:           file_size_bytes: number
L621:           id: string
L622:           is_inline: boolean
L623:           is_quarantined: boolean
L624:           mime_type: string
L625:           organization_id: string
L626:           storage_bucket: string | null
L627:           storage_path: string
L628:           storage_provider: string
L629:           uploaded_at: string
L630:           uploaded_by: string | null
L631:           virus_scan_status: string | null
L632:         }
```


## 2. Summary

| Table | Status | DB location | Action |
|---|---|---|---|
| `org_members` | absent | --- | CREATE |
| `party_contacts` | absent | --- | CREATE |
| `email_signatures` | absent | --- | CREATE |
| `email_whitelist` | present | L2741 | ALTER or no-op |
| `email_templates` | present | L2437 | ALTER or no-op |
| `email_tracking` | present | L2490 | ALTER or no-op |
| `email_tracking_events` | present | L2661 | ALTER or no-op |
| `email_sequence_sends` | present | L2286 | ALTER or no-op |
| `organizations` | present | L4868 | ALTER or no-op |
| `drafts` | present | L233 | ALTER or no-op |
| `attachments` | present | L611 | ALTER or no-op |

## 3. sequence-processor.ts function signature

Where does the `e` (enrollment-like) object come from? Probe the file head.

### Imports and exported function signatures
```ts
L1: // src/lib/utils/sequence-processor.ts (v7 ??Phase 22a)
L2: // ============================================================
L3: // Phase 22a ??Updated sequence processor with proper threading
L4: // Changes vs v5:
L5: //   - Generates RFC-compliant Message-ID for each outbound
L6: //   - Sets thread_id = message_id (new threads)
L7: //   - Sets occurred_at = NOW()
L8: //   - Sets from_address / from_name explicitly
L9: //   - Sets to_addresses[] correctly
L10: //   - Sets template_id (from sequence step)
L11: //   - Sets ai_generated = false
L12: //   - Passes Message-ID header to nodemailer (so replies match)
L13: //   - Adds List-Unsubscribe headers (RFC 8058)
L14: //   - Calls classifyInboundEmail not needed here (inbound only)
L15: // ============================================================
L16: import { createSupabaseServerClient } from "@/lib/supabase/server";
L17: import { rpc } from "@/lib/rpc/typed-rpc";
L18: import nodemailer from "nodemailer";
L19: import { renderMergeFields } from "@/lib/utils/merge-fields";
L20: 
L21: const FROM_NAME = process.env.TABS_MAILER_FROM_NAME || "URM";
L22: 
L23: interface DueEnrollment {
L24:   enrollment_id: string;
L25:   organization_id: string;
L26:   party_id: string;
L27:   contact_id: string | null;
L28:   sequence_id: string;
L29:   step_id: string;
L30:   step_order: number;
L31:   step_subject: string;
L32:   step_body: string;
L33:   step_body_html: string | null;
L34:   step_template_id: string | null;
L35:   contact_email: string | null;
L36:   contact_given_name: string | null;
L37:   contact_family_name: string | null;
L38:   party_name: string;
L39: }
L40: 
L41: export async function processSequence(): Promise<{
L42:   processed: number;
L43:   sent: number;
L44:   failed: number;
L45:   skipped: number;
L46: }> {
L47:   const supabase = await createSupabaseServerClient();
L48: 
L49:   // Get due enrollments
L50:   const { data: due, error: dueErr } = await rpc(supabase, "get_due_enrollments");
L51:   if (dueErr || !due) {
L52:     console.error("[processSequence] get_due_enrollments error", dueErr);
L53:     return { processed: 0, sent: 0, failed: 0, skipped: 0 };
L54:   }
L55: 
L56:   const enrollments = (due as DueEnrollment[]) || [];
L57:   let sent = 0,
L58:     failed = 0,
L59:     skipped = 0;
L60: 
L61:   const fromAddress = process.env.TABS_MAILER_USERNAME!;
L62:   const transporter = nodemailer.createTransport({
L63:     host: process.env.TABS_MAILER_HOST!,
L64:     port: Number(process.env.TABS_MAILER_PORT || 587),
L65:     secure: false,
L66:     auth: {
L67:       user: process.env.TABS_MAILER_USERNAME!,
L68:       pass: process.env.TABS_MAILER_PASSWORD!,
L69:     },
L70:   });
L71: 
L72:   for (const e of enrollments) {
L73:     try {
L74:       if (!e.contact_email) {
L75:         await rpc(supabase, "advance_enrollment", {
L76:           p_enrollment_id: e.enrollment_id,
L77:           p_status: "skipped_no_email",
L78:         });
L79:         skipped++;
L80:         continue;
L81:       }
L82: 
L83:       // Render merge fields
L84:       const ctx = {
L85:         contact: {
L86:           given_name: e.contact_given_name || "",
L87:           family_name: e.contact_family_name || "",
L88:           email: e.contact_email,
L89:         },
L90:         party: { name: e.party_name },
L91:       };
L92:       const subjectResult = renderMergeFields(e.step_subject || "", ctx);
L93:       const bodyResult = renderMergeFields(e.step_body || "", ctx);
L94:       const subject = unwrapMerge(subjectResult);
L95:       const bodyPlain = unwrapMerge(bodyResult);
L96:       const bodyHtml = e.step_body_html
L97:         ? unwrapMerge(renderMergeFields(e.step_body_html, ctx))
L98:         : plainToHtml(bodyPlain);
L99: 
L100:       // Generate communication id + Message-ID
L101:       const commId = crypto.randomUUID();
L102:       const messageId = `<${commId}.${Date.now()}@marinebiogroup.com>`;
L103:       const occurredAt = new Date().toISOString();
L104: 
L105:       // Add tracking pixel
L106:       const trackedHtml = injectTrackingPixel(bodyHtml, commId);
L107: 
L108:       // Insert communications row (with full threading fields)
L109:       const { error: insErr } = await supabase
L110:         .schema("app")
L111:         .from("communications")
L112:         .insert({
L113:           id: commId,
L114:           organization_id: e.organization_id,
L115:           party_id: e.party_id,
L116:           contact_id: e.contact_id,
L117:           channel: "email",
L118:           direction: "outbound",
L119:           message_id: messageId,
L120:           in_reply_to: null,
```

## 4. RPC calls anywhere mentioning sequence/enrollment

```
- src\lib\queries\email-sequences.ts L11: rpc("list_sequences")
- src\lib\queries\email-sequences.ts L19: rpc("get_sequence_with_steps")
- src\lib\queries\email-sequences.ts L27: rpc("get_party_enrollments")
```
