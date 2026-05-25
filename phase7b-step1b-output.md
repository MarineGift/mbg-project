# Phase 7-b Step 1-b output
Generated: 2026-05-25 17:21:48

## 1. Sequence parent tables (email_sequences / enrollments / steps)

Looking for any `.from("name")` or `Tables<"name">` references whose
name matches the sequence family across the whole src/ tree.

(no references found --- sequence enrollment/step lookups may live elsewhere)

## 2. email-attachments (verify hyphen vs underscore)

### src\components\email\compose-email-dialog.tsx (L194)
```ts
      const path = `${props.partyId}/${Date.now()}-${item.file.name}`;
      const { error } = await supabase.storage
>         .from("email-attachments")
        .upload(path, item.file, { upsert: false });

```

### src\lib\actions\email-compose.ts (L132)
```ts

  for (const storagePath of paths) {
>     // storagePath 형식: "email-attachments/{orgId}/{filename}"
    const { data, error } = await supabase.storage
      .from("email-attachments")
```

### src\lib\actions\email-compose.ts (L134)
```ts
    // storagePath 형식: "email-attachments/{orgId}/{filename}"
    const { data, error } = await supabase.storage
>       .from("email-attachments")
      .download(storagePath);

```

### src\lib\actions\upload-attachment.ts (L24)
```ts

  const { error } = await supabase.storage
>     .from('email-attachments')
    .upload(path, buffer, { contentType: file.type || 'application/octet-stream', upsert: false });
  if (error) throw new Error('업로드 실패: ' + error.message);
```

### src\lib\actions\upload-attachment.ts (L33)
```ts
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.storage
>     .from('email-attachments').createSignedUrl(path, 3600);
  if (error) throw new Error('URL 생성 실패: ' + error.message);
  return data.signedUrl;
```

### src\lib\actions\upload-attachment.ts (L40)
```ts
export async function deleteAttachment(path: string) {
  const supabase = await createSupabaseServerClient();
>   await supabase.storage.from('email-attachments').remove([path]);
}
```

## 3. Current `app.communications` Row type (from database.ts)

Found `communications: {` at L1205. Dumping the Row block:

```ts
L1206:         Row: {
L1207:           ai_classification: Json | null
L1208:           ai_draft_id: string | null
L1209:           ai_generated: boolean
L1210:           ai_processing_status: string
L1211:           bcc_addresses: string[]
L1212:           body_html: string | null
L1213:           body_plain: string | null
L1214:           body_summary: string | null
L1215:           bounce_reason: string | null
L1216:           bounced_at: string | null
L1217:           cc_addresses: string[]
L1218:           channel: Database["app"]["Enums"]["engagement_channel"]
L1219:           clicked_at: string | null
L1220:           contact_id: string | null
L1221:           created_at: string
L1222:           created_by: string | null
L1223:           deleted_at: string | null
L1224:           delivered_at: string | null
L1225:           direction: Database["app"]["Enums"]["direction_type"]
L1226:           engagement_id: string | null
L1227:           external_data: Json
L1228:           from_address: string | null
L1229:           from_name: string | null
L1230:           id: string
L1231:           in_reply_to: string | null
L1232:           is_important: boolean
L1233:           is_starred: boolean
L1234:           language_detected: string | null
L1235:           message_id: string | null
L1236:           module: Database["app"]["Enums"]["module_type"] | null
L1237:           notes: string | null
L1238:           occurred_at: string
L1239:           opened_at: string | null
L1240:           organization_id: string
L1241:           party_id: string | null
L1242:           read_at: string | null
L1243:           received_at: string | null
L1244:           replied_at: string | null
L1245:           reply_to_address: string | null
L1246:           sent_at: string | null
L1247:           sent_by_user_id: string | null
L1248:           status: string
L1249:           subject: string | null
L1250:           template_id: string | null
L1251:           template_variables: Json
L1252:           thread_id: string | null
L1253:           to_addresses: string[]
L1254:           updated_at: string
L1255:           updated_by: string | null
L1256:         }
```

## 4. `industry` schema in database.ts

(zero matches --- `industry` schema is completely absent from database.ts)

This is almost certainly the source of the 560-line augmentation gap:
the live DB has an `industry` schema (~3,200 rows of paper-filler data)
but the regen flags omitted it.

Fix at Step 3 regen by using:
    supabase gen types typescript --linked --schema 'public,app,urm,industry'

## 5. All `.from("...")` calls in src/lib (broader scan)

Union of every table touched anywhere under src/lib/.

Distinct tables: 29

```
- agents
- attachments
- auto_send_rules
- brand_voice
- calendar_connections
- calendar_events
- communications
- contacts
- drafts
- email_sequence_sends
- email_signatures
- email_templates
- email_tracking
- email_tracking_events
- email_whitelist
- email-attachments
- filler_suppliers
- mail_merge_jobs
- mailcarrier_state
- org_members
- organizations
- paper_companies
- paper_mills
- parties
- party_contacts
- pipeline_definitions
- pipeline_stages
- runs
- supplier_mill_linkages
```