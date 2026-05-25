# Phase 7-b Step 1 output
Generated: 2026-05-25 17:15:35

Files scanned: 7
- src\lib\actions\email-compose.ts
- src\lib\actions\email-sequences.ts
- src\lib\actions\email-whitelist.ts
- src\lib\queries\email-signatures.ts
- src\lib\queries\email-tracking.ts
- src\lib\queries\communications.ts
- src\lib\utils\sequence-processor.ts

## 1. Tables referenced (.from)

### src\lib\actions\email-compose.ts
- `communications`
- `contacts`
- `email_signatures`
- `email_templates`
- `email_whitelist`
- `email-attachments`
- `org_members`
- `parties`
- `party_contacts`

### src\lib\queries\email-signatures.ts
- `email_signatures`

### src\lib\queries\email-tracking.ts
- `email_tracking`
- `email_tracking_events`

### src\lib\queries\communications.ts
- `communications`

### src\lib\utils\sequence-processor.ts
- `communications`
- `email_sequence_sends`

### Union of all tables touched
- `communications`
- `contacts`
- `email_sequence_sends`
- `email_signatures`
- `email_templates`
- `email_tracking`
- `email_tracking_events`
- `email_whitelist`
- `email-attachments`
- `org_members`
- `parties`
- `party_contacts`

## 2. Insert / Update / Upsert payloads (with context)

### src\lib\actions\email-compose.ts
```ts
// L281  (.insert({)
      organization_id: orgId,
      party_id: payload.partyId,
      contact_id: payload.contactId ?? null,
      direction: "outbound",
      channel: "email",
      subject: finalSubject,
      body_html: finalBody,
      from_address: process.env.SMTP_USER,
      to_address: payload.to,
      message_id: smtpMessageId,
      thread_id: payload.threadId ?? smtpMessageId,
      in_reply_to: payload.replyToMessageId ?? null,

// L402  (.update({ is_default: false }))
      .eq("organization_id", member.organization_id)
      .eq("is_default", true);
  }

  if (input.id) {
    const { error } = await supabase
      .from("email_signatures")
      .update({
        name: input.name,
        html_content: input.htmlContent,
        is_default: input.isDefault,
      })

// L410  (.update({)
        name: input.name,
        html_content: input.htmlContent,
        is_default: input.isDefault,
      })

// L419  (const { error } = await supabase.from("email_signatures").insert({)
      organization_id: member.organization_id,
      name: input.name,
      html_content: input.htmlContent,
      is_default: input.isDefault,
    });

```

### src\lib\queries\email-signatures.ts
```ts
// L36  (.from('email_signatures').upsert(sig, { onConflict: 'id' }).select().single();)
  if (error) throw error;
  return data;
}

export async function deleteSignature(id: string) {
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from('email_signatures').delete().eq('id', id);
  if (error) throw error;
}

export async function setDefaultSignature(id: string, orgId: string) {
  const supabase = await createSupabaseServerClient();

// L50  (.update({ is_default: false }).eq('organization_id', orgId).eq('is_default', true);)
  const { error } = await supabase.from('email_signatures')
    .update({ is_default: true }).eq('id', id);
  if (error) throw error;
}

// L52  (.update({ is_default: true }).eq('id', id);)
  if (error) throw error;
}

```

### src\lib\queries\communications.ts
```ts
// L154  (.update({ read_at: new Date().toISOString() } as any))
      .eq('id', id);
  } catch (_) {
    // Silently ignore  read_at column may not exist until SQL migration runs
  }
}

//  Phase 22b: getUnreadCount 
export async function getUnreadCount(): Promise<number> {
  try {
    const supabase = await createSupabaseServerClient();
    const { count } = await supabase
      .schema('app')

```

### src\lib\utils\sequence-processor.ts
```ts
// L112  (.insert({)
          id: commId,
          organization_id: e.organization_id,
          party_id: e.party_id,
          contact_id: e.contact_id,
          channel: "email",
          direction: "outbound",
          message_id: messageId,
          in_reply_to: null,
          thread_id: messageId,  // new thread
          from_address: fromAddress,
          from_name: FROM_NAME,
          to_addresses: [e.contact_email],

// L185  (.update({)
              status: "failed",
              bounce_reason: msg,
              updated_at: new Date().toISOString(),
            })

// L205  (.update({)
          status: "sent",
          sent_at: sentAt,
          delivered_at: sentAt,
          updated_at: sentAt,
        })

// L217  (.insert({)
          enrollment_id: e.enrollment_id,
          step_id: e.step_id,
          communication_id: commId,
          sent_at: sentAt,
          status: "sent",
        });

```

## 3. Filter columns (FK / index candidates)

### src\lib\actions\email-compose.ts
- `eq('id')`
- `eq('is_default')`
- `eq('is_primary')`
- `eq('organization_id')`
- `eq('party_id')`
- `eq('user_id')`

### src\lib\queries\email-signatures.ts
- `eq('id')`
- `eq('is_default')`
- `eq('organization_id')`

### src\lib\queries\email-tracking.ts
- `eq('communication_id')`
- `eq('draft_id')`
- `eq('party_id')`
- `eq('tracking_id')`

### src\lib\queries\communications.ts
- `eq('direction')`
- `eq('id')`
- `is('deleted_at')`
- `is('read_at')`

### src\lib\utils\sequence-processor.ts
- `eq('id')`

## 4. Explicit select / order

### src\lib\actions\email-compose.ts
**select:**
```ts
L50: name, country_code, website
L69: contact_id
L79: given_name, family_name, email, title, department, phone
L113: html_content
L187: organization_id
L199: id
L215: body_html, subject
L298: id
L320: subject, body_html, body_plain, from_address, to_address, sent_at
L331: given_name, family_name
L393: organization_id
L456: organization_id
L463: id, name, html_content, is_default
```
**order:**
- `is_default`

### src\lib\queries\email-signatures.ts
**select:**
```ts
L17: *
L26: *
```
**order:**
- `is_default`

### src\lib\queries\email-tracking.ts
**select:**
```ts
L26: *
L43: *
L60: *
L75: *
```
**order:**
- `created_at`
- `sent_at`

### src\lib\queries\communications.ts
**select:**
```ts
L168: id
```

## 5. Type references (Tables<...>, TablesInsert<...>, etc.)

## 6. rpc() calls

### src\lib\actions\email-whitelist.ts
- L7: `list_email_whitelist`
- L8: `get_unregistered_party_domains`
- L9: `add_email_whitelist`
- L10: `add_email_whitelist`
- L11: `toggle_email_whitelist`
- L12: `delete_email_whitelist`

### src\lib\queries\email-tracking.ts
- L133: `get_tracking_for_drafts`

### src\lib\queries\communications.ts
- L72: `get_thread_context`
- L87: `list_templates_for_compose`
