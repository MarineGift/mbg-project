# app schema reference — 정본

> **생성**: 2026-07-14 · `information_schema.columns` 전수 덤프 (table_schema='app')
> **목적**: 컬럼 추측으로 인한 42703 재발 방지. SQL/TS 작성 전 여기서 컬럼명을 확인한다.
> **갱신**: 스키마 변경 시 PART D의 재생성 쿼리를 다시 돌려 이 파일을 교체할 것.

테이블 118개 · 뷰 8개

---

## PART A — 자주 틀리는 컬럼 (실제 사고 기록)

| 틀린 추측 | 실제 | 발생 |
|---|---|---|
| `contacts.title` | **`contacts.title_text`** | 2026-07-14, 42703 |
| `communications.body_text` | **`communications.body_plain`** (+ `body_html`, `body_summary`) | 2026-07-14, 42703 |
| `application_form_fields.field_label` / `char_limit` / `sort_order` | **`label`** / **`max_length`** / **`seq`** | 이전 세션 |
| `plant_supply_links` | **`party_supply_links`** (`mill_party_id` + `filler_party_id`) — plant_supply_links는 sql/에 있으나 DB 미적용(42P01) | 이전 세션 |

### 조용한 함정 (에러 안 나고 결과만 틀림)

- **`email_sequence_enrollments.recipient_email`** — enrollment가 **자체 이메일 컬럼**을 가진다. `contacts.email`만 검사하는 프리플라이트는 오판한다. 워커의 실제 해석 순서를 확인하고 그것과 일치시킬 것.
- **`communications.template_id`가 NULL인 발송** — bulk-mail의 `already_sent` dedup은 template_id 키라서 NULL이면 매칭이 성립하지 않는다 → 수동/애드혹 발송은 dedup을 통째로 우회한다.
- **`answer_library.created_by`** — NOT NULL인데 **default 없음** (SQL Editor에서 `auth.uid()`는 null). INSERT 시 기존 행에서 복사: `(SELECT created_by FROM app.answer_library WHERE ... LIMIT 1)`
- **`answer_library`에 UNIQUE(org, answer_key) 없음** (migration_025 파일엔 있으나 미적용) → `ON CONFLICT` 대신 `NOT EXISTS` 가드
- **`v_email_do_not_send`에 `organization_id` 없음** → org 필터 걸면 42703. org 안전성은 후보 집합이 이미 org 필터된 것으로 담보한다.
- **enum(USER-DEFINED) 컬럼** — 타입명이 불확실하면 `col::text = 'value'`로 비교. 확실할 때만 `::app.enrollment_status` 캐스트.

### `created_by` 규칙 (SaaS 표준)

엔티티 테이블은 `created_by uuid default auth.uid()` + `created_at`/`updated_at`를 가진다. **조인/링크, 이력, 룩업/참조, 로그/파생, 1:1 상세 테이블에는 붙이지 않는다.**

---

## PART B — 테이블

### `app._bak_pmpt_20260606` (6)

```
mill_party_id uuid
paper_type_id uuid
organization_id uuid
is_primary boolean
source text
created_at timestamp with time zone
```

### `app.account_scores` (12)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
party_id uuid NOT NULL
score numeric NOT NULL DEFAULT 0
tier text NOT NULL DEFAULT 'C'::text
recency_pts numeric NOT NULL DEFAULT 0
frequency_pts numeric NOT NULL DEFAULT 0
meeting_pts numeric NOT NULL DEFAULT 0
deal_pts numeric NOT NULL DEFAULT 0
fit_pts numeric NOT NULL DEFAULT 0
factors jsonb NOT NULL DEFAULT '{}'::jsonb
computed_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.answer_library` (13)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
answer_key text NOT NULL
title text NOT NULL
body_en text
body_ko text
disclosure_level text NOT NULL DEFAULT 'public'::text
tags ARRAY NOT NULL DEFAULT '{}'::text[]
created_by uuid NOT NULL DEFAULT auth.uid()
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
variant text NOT NULL DEFAULT 'medium'::text
target_length integer
```

### `app.application_field_answers` (9)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
field_id uuid NOT NULL
answer_id uuid
final_text text
char_count integer
is_copied boolean NOT NULL DEFAULT false
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.application_form_fields` (15)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
form_id uuid NOT NULL
seq integer NOT NULL DEFAULT 0
label text NOT NULL
field_type text NOT NULL DEFAULT 'textarea'::text
max_length integer
is_required boolean NOT NULL DEFAULT false
help_text text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
selector text
selector_type text NOT NULL DEFAULT 'css'::text
input_kind text NOT NULL DEFAULT 'fill'::text
canonical_key text
```

### `app.application_forms` (20)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
party_id uuid NOT NULL
form_url text NOT NULL
form_type text NOT NULL DEFAULT 'application'::text
cycle_label text
opens_at date
deadline date
status text NOT NULL DEFAULT 'not_started'::text
submitted_at timestamp with time zone
decision_at timestamp with time zone
outcome text
notes text
created_by uuid NOT NULL DEFAULT auth.uid()
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
submission_method text NOT NULL DEFAULT 'web_form'::text
submit_email text
attachments ARRAY NOT NULL DEFAULT '{}'::text[]
login_required boolean NOT NULL DEFAULT false
```

### `app.attachments` (21)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
entity_type text NOT NULL
entity_id uuid NOT NULL
file_name text NOT NULL
file_size_bytes bigint NOT NULL
mime_type text NOT NULL
storage_provider text NOT NULL DEFAULT 'supabase'::text
storage_bucket text
storage_path text NOT NULL
content_hash_sha256 text
is_inline boolean NOT NULL DEFAULT false
is_quarantined boolean NOT NULL DEFAULT false
virus_scan_status text
description text
uploaded_by uuid
uploaded_at timestamp with time zone NOT NULL DEFAULT now()
expires_at timestamp with time zone
deleted_at timestamp with time zone
drive_file_id text
created_by uuid DEFAULT auth.uid()
```

### `app.calendar_connections` (22)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
user_id uuid NOT NULL
provider USER-DEFINED NOT NULL
account_email text NOT NULL
account_name text
access_token bytea NOT NULL
refresh_token bytea
token_type text DEFAULT 'Bearer'::text
expires_at timestamp with time zone
scopes ARRAY NOT NULL DEFAULT '{}'::text[]
sync_token text
delta_link text
last_sync_at timestamp with time zone
last_sync_status USER-DEFINED DEFAULT 'pending'::app.calendar_sync_status
last_error text
sync_failures integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
is_primary boolean NOT NULL DEFAULT false
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.calendar_events` (36)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
user_id uuid NOT NULL
connection_id uuid
source USER-DEFINED NOT NULL
external_id text
external_etag text
title text NOT NULL DEFAULT '(No title)'::text
description text
location text
meeting_url text
start_at timestamp with time zone NOT NULL
end_at timestamp with time zone NOT NULL
timezone text NOT NULL DEFAULT 'Asia/Seoul'::text
is_all_day boolean NOT NULL DEFAULT false
recurrence_rule text
recurring_event_id text
is_recurrence_instance boolean NOT NULL DEFAULT false
attendees jsonb NOT NULL DEFAULT '[]'::jsonb
organizer_email text
organizer_name text
status USER-DEFINED NOT NULL DEFAULT 'confirmed'::app.event_status
visibility text DEFAULT 'default'::text
party_id uuid
engagement_id uuid
auto_matched boolean NOT NULL DEFAULT false
match_confidence numeric
external_created_at timestamp with time zone
external_modified_at timestamp with time zone
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
meeting_id uuid
color text
reminders jsonb NOT NULL DEFAULT '[]'::jsonb
transparency text NOT NULL DEFAULT 'opaque'::text
created_by uuid DEFAULT auth.uid()
```

### `app.calendar_sync_log` (11)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
user_id uuid
connection_id uuid
event_id uuid
operation USER-DEFINED NOT NULL
status USER-DEFINED NOT NULL DEFAULT 'pending'::app.calendar_sync_status
details jsonb NOT NULL DEFAULT '{}'::jsonb
error_message text
duration_ms integer
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.campaign_folders` (6)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
campaign_id uuid NOT NULL
name text NOT NULL
drive_folder_id text NOT NULL
sort_order integer NOT NULL DEFAULT 0
created_by uuid DEFAULT auth.uid()
```

### `app.campaign_forecast` (6)

```
campaign_id uuid
organization_id uuid
name text
deal_count bigint
total_value numeric
weighted_forecast numeric
```

### `app.campaign_materials` (10)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
campaign_id uuid NOT NULL
section text NOT NULL
item_key text NOT NULL
label text NOT NULL
detail text
status text NOT NULL DEFAULT 'not_started'::text
sort_order integer NOT NULL DEFAULT 0
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.campaigns` (12)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
name text NOT NULL
campaign_type text
description text
status text NOT NULL DEFAULT 'active'::text
start_date date
end_date date
color text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.closed_deals` (13)

```
id uuid
organization_id uuid
name text
amount numeric
party_id uuid
campaign_id uuid
stage_id uuid
stage_name text
outcome text
close_reason text
closed_at date
created_at timestamp with time zone
cycle_days integer
```

### `app.communications` (53)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
party_id uuid
contact_id uuid
engagement_id uuid
party_type text
channel USER-DEFINED NOT NULL
direction USER-DEFINED NOT NULL
message_id text
in_reply_to text
thread_id text
from_address text
from_name text
to_addresses ARRAY NOT NULL DEFAULT '{}'::text[]
cc_addresses ARRAY NOT NULL DEFAULT '{}'::text[]
bcc_addresses ARRAY NOT NULL DEFAULT '{}'::text[]
reply_to_address text
subject text
body_html text
body_plain text
body_summary text
language_detected text
status text NOT NULL DEFAULT 'received'::text
occurred_at timestamp with time zone NOT NULL DEFAULT now()
sent_at timestamp with time zone
delivered_at timestamp with time zone
received_at timestamp with time zone
opened_at timestamp with time zone
clicked_at timestamp with time zone
replied_at timestamp with time zone
bounced_at timestamp with time zone
bounce_reason text
ai_classification jsonb
ai_draft_id uuid
ai_generated boolean NOT NULL DEFAULT false
template_id uuid
template_variables jsonb NOT NULL DEFAULT '{}'::jsonb
external_data jsonb NOT NULL DEFAULT '{}'::jsonb
sent_by_user_id uuid
is_starred boolean NOT NULL DEFAULT false
is_important boolean NOT NULL DEFAULT false
notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
deleted_at timestamp with time zone
ai_processing_status text NOT NULL DEFAULT 'pending'::text
read_at timestamp with time zone
error_message text
party_type_id smallint
deal_id uuid
mail_account_id uuid
```

### `app.consultations` (34)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
party_id uuid
contact_id uuid
engagement_id uuid
party_type text
channel USER-DEFINED NOT NULL
source_communication_id uuid
title text
content_raw text NOT NULL
content_processed text
language text
attachments_meta jsonb NOT NULL DEFAULT '[]'::jsonb
consultation_type text
priority USER-DEFINED NOT NULL DEFAULT 'medium'::app.priority_level
urgency text
ai_processing_status text NOT NULL DEFAULT 'pending'::text
ai_processing_started_at timestamp with time zone
ai_processing_completed_at timestamp with time zone
pii_masked boolean NOT NULL DEFAULT false
pii_categories_detected ARRAY NOT NULL DEFAULT '{}'::text[]
received_at timestamp with time zone NOT NULL DEFAULT now()
notes text
tags ARRAY NOT NULL DEFAULT '{}'::text[]
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
deleted_at timestamp with time zone
ai_processing_error_message text
ai_processing_error_class text
ai_processing_failed_at timestamp with time zone
ai_processing_retryable boolean
party_type_id smallint
```

### `app.contact_emails` (10)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
contact_id uuid NOT NULL
email text NOT NULL
label text
is_primary boolean NOT NULL DEFAULT false
is_verified boolean NOT NULL DEFAULT false
source text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.contact_profiles` (14)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
contact_id uuid NOT NULL
organization_id uuid NOT NULL
coverage_region text
location_text text
board_roles text
mbg_fit_rating text
mbg_fit_note text
entry_channel text
verified_at date
verify_source text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.contact_types` (10)

```
id smallint NOT NULL
code text NOT NULL
display_name_en text NOT NULL
display_name_ko text NOT NULL
display_name_ja text
description text
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.contacts` (34)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
party_id uuid NOT NULL
contact_type_id smallint NOT NULL
full_name text
given_name text
family_name text
email text
email_secondary text
phone_e164 text
phone_mobile text
linkedin_url text
twitter_handle text
title_text text
department text
role_category text
seniority_level text
is_decision_maker boolean NOT NULL DEFAULT false
is_primary boolean NOT NULL DEFAULT false
is_active boolean NOT NULL DEFAULT true
background text
education text
focus_areas ARRAY
joined_at date
left_at date
last_contacted_at timestamp with time zone
notes text
source text
source_external_id text
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
organization_id uuid NOT NULL
created_by uuid DEFAULT auth.uid()
```

### `app.contacts_history` (17)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
contact_id uuid NOT NULL
firm_party_id uuid NOT NULL
started_at date
ended_at date
title_text text
role_category text
seniority_level text
department text
notes text
module_data jsonb DEFAULT '{}'::jsonb
created_at timestamp with time zone DEFAULT now()
created_by uuid
updated_at timestamp with time zone DEFAULT now()
updated_by uuid
deleted_at timestamp with time zone
organization_id uuid NOT NULL DEFAULT 'b25de8f2-1020-482f-9012-183f63883169'::uuid
```

### `app.countries` (3)

```
code text NOT NULL
name_en text NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.deal_aging` (10)

```
id uuid
organization_id uuid
stage_id uuid
stage_name text
amount numeric
last_touch timestamp with time zone
days_in_stage integer
days_since_touch integer
is_closed boolean
is_stale boolean
```

### `app.deal_backers` (22)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
deal_id uuid NOT NULL
party_id uuid
contact_id uuid
reward_tier_id uuid
pledge_amount numeric NOT NULL
currency text NOT NULL DEFAULT 'USD'::text
status text NOT NULL DEFAULT 'pledged'::text
is_anonymous boolean NOT NULL DEFAULT false
display_name text
note text
pledged_at timestamp with time zone NOT NULL DEFAULT now()
collected_at timestamp with time zone
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
country_code text
pledge_currency text
email text
external_backer_id text
reward_status text
created_by uuid DEFAULT auth.uid()
```

### `app.deal_checklists` (16)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
deal_id uuid NOT NULL
title text NOT NULL
is_complete boolean DEFAULT false
completed_at timestamp with time zone
completed_by uuid
sort_order integer DEFAULT 0
notes text
extra_data jsonb DEFAULT '{}'::jsonb
created_at timestamp with time zone DEFAULT now()
created_by uuid
updated_at timestamp with time zone DEFAULT now()
updated_by uuid
deleted_at timestamp with time zone
organization_id uuid
stage_id uuid
```

### `app.deal_close_reasons` (7)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
outcome text NOT NULL
label text NOT NULL
sort_order integer NOT NULL DEFAULT 0
active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.deal_forecast` (12)

```
id uuid
organization_id uuid
name text
campaign_id uuid
stage_id uuid
start_date date
end_date date
amount numeric
effective_probability integer
forecast_value numeric
is_won boolean
is_lost boolean
```

### `app.deal_participation` (7)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
party_id uuid NOT NULL
pipeline_id uuid NOT NULL
deal_id uuid NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.deal_parties` (11)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
deal_id uuid NOT NULL
party_id uuid NOT NULL
role text NOT NULL DEFAULT 'primary'::text
commitment_amount numeric
currency text NOT NULL DEFAULT 'USD'::text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
updated_by uuid
```

### `app.deal_stage_history` (10)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
deal_id uuid NOT NULL
from_stage_id uuid
to_stage_id uuid NOT NULL
changed_at timestamp with time zone NOT NULL DEFAULT now()
changed_by uuid
notes text
extra_data jsonb DEFAULT '{}'::jsonb
created_at timestamp with time zone DEFAULT now()
organization_id uuid
```

### `app.deals` (33)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
party_id uuid NOT NULL
primary_contact_id uuid
pipeline_id uuid NOT NULL
current_stage_id uuid NOT NULL
deal_name text NOT NULL
description text
status text NOT NULL DEFAULT 'active'::text
probability_pct integer
value_amount numeric
value_currency text NOT NULL DEFAULT 'USD'::text
expected_close_date date
actual_close_date date
won_lost_reason text
owner_user_id uuid
priority text NOT NULL DEFAULT 'medium'::text
source text
source_external_id text
notes text
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
last_activity_at timestamp with time zone
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
created_by uuid
updated_by uuid
organization_id uuid
campaign_id uuid NOT NULL
start_date date
end_date date
stage_entered_at timestamp with time zone
next_step text
next_step_date date
```

### `app.email_blocklist` (9)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
pattern text NOT NULL
kind text NOT NULL DEFAULT 'address'::text
reason text
notes text
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
```

### `app.email_send_outcomes` (14)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid
party_id uuid
recipient_email text NOT NULL
sequence_id uuid
step_order integer
outcome text NOT NULL
reason text
evidence_ref text
next_action text DEFAULT 'none'::text
resend_not_before date
source text DEFAULT 'manual'::text
occurred_at timestamp with time zone NOT NULL DEFAULT now()
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.email_sequence_enrollments` (17)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
sequence_id uuid NOT NULL
party_id uuid
contact_id uuid
enrolled_by uuid
enrolled_at timestamp with time zone NOT NULL DEFAULT now()
status USER-DEFINED NOT NULL DEFAULT 'active'::app.enrollment_status
next_step_order integer NOT NULL DEFAULT 0
next_send_at timestamp with time zone
completed_at timestamp with time zone
cancelled_at timestamp with time zone
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
engagement_id uuid
recipient_email text
created_by uuid DEFAULT auth.uid()
```

### `app.email_sequence_sends` (11)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
enrollment_id uuid NOT NULL
step_id uuid NOT NULL
step_order integer NOT NULL
communication_id uuid
sent_at timestamp with time zone NOT NULL DEFAULT now()
status USER-DEFINED NOT NULL DEFAULT 'sent'::app.send_status
organization_id uuid NOT NULL
bounce_reason text
delivered_at timestamp with time zone
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.email_sequence_steps` (10)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
sequence_id uuid NOT NULL
step_order integer NOT NULL
day_offset integer NOT NULL DEFAULT 0
subject text NOT NULL
body_plain text NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
organization_id uuid NOT NULL
created_by uuid DEFAULT auth.uid()
```

### `app.email_sequences` (12)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
name text NOT NULL
description text
status USER-DEFINED NOT NULL DEFAULT 'active'::app.email_sequence_status
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
from_account_id uuid
created_by uuid
updated_by uuid
quiet_hours jsonb
start_at timestamp with time zone
```

### `app.email_signatures` (8)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
name text NOT NULL
html_content text NOT NULL
is_default boolean NOT NULL DEFAULT false
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.email_templates` (13)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
name text NOT NULL
category text
subject text NOT NULL
body_plain text NOT NULL
body_html text
party_type text
is_active boolean NOT NULL DEFAULT true
created_by uuid
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
stage_code text
```

### `app.email_tracking` (14)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
draft_id uuid
party_id uuid
contact_id uuid
subject text
sent_to text NOT NULL DEFAULT ''::text
open_token text NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'::text)
sent_at timestamp with time zone NOT NULL DEFAULT now()
first_opened_at timestamp with time zone
open_count integer NOT NULL DEFAULT 0
click_count integer NOT NULL DEFAULT 0
created_at timestamp with time zone NOT NULL DEFAULT now()
communication_id uuid
```

### `app.email_tracking_events` (8)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
tracking_id uuid NOT NULL
link_id uuid
event_type text NOT NULL
url text
ip text
user_agent text
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.email_tracking_links` (5)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
tracking_id uuid NOT NULL
token text NOT NULL DEFAULT encode(gen_random_bytes(12), 'hex'::text)
original_url text NOT NULL
click_count integer NOT NULL DEFAULT 0
```

### `app.email_whitelist` (8)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
pattern text NOT NULL
kind text NOT NULL
notes text
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
```

### `app.engagement_attendees` (10)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
engagement_id uuid NOT NULL
contact_id uuid NOT NULL
role text NOT NULL DEFAULT 'participant'::text
response text
attended boolean
notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
organization_id uuid
```

### `app.engagement_documents` (16)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
engagement_id uuid NOT NULL
file_name text NOT NULL
mime_type text
file_size_bytes bigint
storage_path text NOT NULL
storage_provider text DEFAULT 'supabase'::text
description text
document_kind text
uploaded_by_user_id uuid
uploaded_at timestamp with time zone NOT NULL DEFAULT now()
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
organization_id uuid
created_by uuid DEFAULT auth.uid()
```

### `app.engagement_email_details` (16)

```
engagement_id uuid NOT NULL
from_address text NOT NULL
to_addresses ARRAY NOT NULL DEFAULT '{}'::text[]
cc_addresses ARRAY NOT NULL DEFAULT '{}'::text[]
bcc_addresses ARRAY NOT NULL DEFAULT '{}'::text[]
subject text NOT NULL
body_html text
message_id text
thread_id text
in_reply_to text
has_attachments boolean NOT NULL DEFAULT false
spam_score numeric
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
source_communication_id uuid
organization_id uuid
```

### `app.engagement_meeting_details` (16)

```
engagement_id uuid NOT NULL
location text
virtual_url text
meeting_platform text
scheduled_start_at timestamp with time zone
scheduled_end_at timestamp with time zone
actual_started_at timestamp with time zone
actual_ended_at timestamp with time zone
recording_url text
transcript_url text
agenda text
meeting_kind text
external_calendar_id text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
organization_id uuid
```

### `app.engagement_participants` (15)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
engagement_id uuid NOT NULL
contact_id uuid
person_party_id uuid
user_id uuid
email text
name text
role USER-DEFINED NOT NULL DEFAULT 'required'::app.attendee_role
is_internal boolean NOT NULL DEFAULT false
notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
updated_by uuid
```

### `app.engagement_type_registry` (15)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
party_kind USER-DEFINED NOT NULL
engagement_kind text NOT NULL
label_ko text NOT NULL
label_en text NOT NULL
label_ja text
description text
is_default_for_party_type boolean NOT NULL DEFAULT false
display_order integer NOT NULL DEFAULT 0
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
```

### `app.engagement_types` (10)

```
id smallint NOT NULL
code text NOT NULL
display_name_en text NOT NULL
display_name_ko text NOT NULL
display_name_ja text
description text
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.engagements` (26)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
engagement_type_id smallint NOT NULL
deal_id uuid
party_id uuid
task_id uuid
title text NOT NULL
summary text
content text
occurred_at timestamp with time zone NOT NULL
duration_min integer
channel text
direction text
status text NOT NULL DEFAULT 'completed'::text
outcome text
next_steps text
sentiment text
recorded_by_user_id uuid
notes text
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
created_by uuid
updated_by uuid
stage_id_at_time uuid
organization_id uuid
```

### `app.entity_types` (10)

```
id smallint NOT NULL
code text NOT NULL
display_name_en text NOT NULL
display_name_ko text NOT NULL
display_name_ja text
description text
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.filler_supplier_profile` (18)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
party_id uuid NOT NULL
supplier_type text
market_role text
supply_model text
onsite_pcc_evidence text
evidence_level text
industry_source text NOT NULL DEFAULT 'v11.4'::text
auto_promoted_at timestamp with time zone
notes text
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
deleted_at timestamp with time zone
organization_id uuid NOT NULL
mineral_class text
```

### `app.inbound_mailboxes` (21)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
address text NOT NULL
label text
imap_host text NOT NULL
imap_port integer NOT NULL DEFAULT 993
use_tls boolean NOT NULL DEFAULT true
password_encrypted bytea
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
display_name text
imap_username text
smtp_host text
smtp_port integer
smtp_use_tls boolean NOT NULL DEFAULT true
smtp_username text
smtp_password_encrypted bytea
smtp_auth_method text NOT NULL DEFAULT 'login'::text
is_default boolean NOT NULL DEFAULT false
created_by uuid DEFAULT auth.uid()
```

### `app.industry_tags` (7)

```
id smallint NOT NULL DEFAULT nextval('app.industry_tags_id_seq'::regclass)
code text NOT NULL
label text NOT NULL
category text
description text
sort_order smallint NOT NULL DEFAULT 0
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.interest_tag_aliases` (3)

```
alias text NOT NULL
canonical_code text NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.interest_tags` (7)

```
id bigint NOT NULL
code text NOT NULL
label_en text NOT NULL
label_ko text NOT NULL
sort_order integer NOT NULL DEFAULT 100
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.investment_stages` (7)

```
id smallint NOT NULL
code text NOT NULL
label_en text NOT NULL
label_ko text NOT NULL
label_ja text NOT NULL
stage_group text
sort_order smallint NOT NULL DEFAULT 0
```

### `app.investor_interest_tags` (4)

```
investor_profile_id uuid NOT NULL
interest_tag_id bigint NOT NULL
organization_id uuid NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.investor_portfolio_companies` (19)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
investor_party_id uuid NOT NULL
portfolio_company_name text NOT NULL
portfolio_company_name_normalized text
portfolio_company_website text
portfolio_company_country text
investment_year integer
investment_stage text
investment_amount_usd numeric
is_lead boolean NOT NULL DEFAULT false
is_active boolean NOT NULL DEFAULT true
notes text
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_at timestamp with time zone NOT NULL DEFAULT now()
updated_by uuid
deleted_at timestamp with time zone
organization_id uuid NOT NULL
```

### `app.investor_profile` (18)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
party_id uuid NOT NULL
fund_name text
fund_size_usd numeric
fund_vintage_year integer
ticket_min_usd numeric
ticket_max_usd numeric
sector_focus ARRAY NOT NULL DEFAULT '{}'::text[]
is_lead_investor boolean NOT NULL DEFAULT false
is_strategic boolean NOT NULL DEFAULT false
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
aum_usd numeric
organization_id uuid NOT NULL
investor_type_id smallint
priority text DEFAULT 'medium'::text
```

### `app.investor_sector_focus` (4)

```
investor_profile_id uuid NOT NULL
sector_id smallint NOT NULL
organization_id uuid NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.investor_stage_focus` (4)

```
investor_profile_id uuid NOT NULL
stage_id smallint NOT NULL
organization_id uuid NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.investor_types` (6)

```
id smallint NOT NULL
code text NOT NULL
display_name text
category text
sort_order integer
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.lead_scores` (12)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
party_id uuid NOT NULL
score integer NOT NULL DEFAULT 0
factors jsonb NOT NULL DEFAULT '{}'::jsonb
confidence numeric NOT NULL DEFAULT 0.5
computed_at timestamp with time zone NOT NULL DEFAULT now()
computed_by text NOT NULL DEFAULT 'system'::text
valid_until timestamp with time zone
notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.mail_merge_jobs` (33)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
name text NOT NULL
description text
template_id uuid NOT NULL
template_version_id uuid
ab_test_id uuid
recipient_filter jsonb NOT NULL DEFAULT '{}'::jsonb
recipient_party_ids ARRAY NOT NULL DEFAULT '{}'::uuid[]
recipient_contact_ids ARRAY NOT NULL DEFAULT '{}'::uuid[]
estimated_recipient_count integer
from_address text NOT NULL
from_name text
reply_to_address text
scheduled_at timestamp with time zone
rate_limit_per_hour integer NOT NULL DEFAULT 100
rate_limit_per_minute integer NOT NULL DEFAULT 5
quiet_hours jsonb NOT NULL DEFAULT '{"end": "08:00", "start": "22:00", "timezone": "Asia/Seoul", "weekends_blocked": true}'::jsonb
tabs_campaign_id text
tabs_campaign_status text
tabs_campaign_synced_at timestamp with time zone
status text NOT NULL DEFAULT 'draft'::text
progress jsonb NOT NULL DEFAULT '{"sent": 0, "failed": 0, "opened": 0, "bounced": 0, "clicked": 0, "replied": 0}'::jsonb
started_at timestamp with time zone
completed_at timestamp with time zone
error_message text
requires_legal_approval boolean NOT NULL DEFAULT false
legal_approved_at timestamp with time zone
legal_approved_by uuid
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
```

### `app.mail_run_recipients` (13)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
run_id uuid NOT NULL
party_id uuid NOT NULL
contact_id uuid
email text NOT NULL
status text NOT NULL DEFAULT 'pending'::text
communication_id uuid
error text
attempts integer NOT NULL DEFAULT 0
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
sent_at timestamp with time zone
```

### `app.mail_runs` (24)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
template_id uuid NOT NULL
template_subject text NOT NULL DEFAULT ''::text
template_body text NOT NULL DEFAULT ''::text
mail_account_id uuid NOT NULL
recipient_mode text NOT NULL DEFAULT 'primary'::text
bypass_whitelist boolean NOT NULL DEFAULT false
rate_per_minute integer NOT NULL DEFAULT 30
concurrency integer NOT NULL DEFAULT 4
source_kind text
source_ref text
status text NOT NULL DEFAULT 'queued'::text
total_count integer NOT NULL DEFAULT 0
sent_count integer NOT NULL DEFAULT 0
failed_count integer NOT NULL DEFAULT 0
blocked_count integer NOT NULL DEFAULT 0
notes text
created_by uuid DEFAULT auth.uid()
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
started_at timestamp with time zone
completed_at timestamp with time zone
scheduled_at timestamp with time zone
```

### `app.mailcarrier_state` (6)

```
organization_id uuid NOT NULL
kind text NOT NULL
username text NOT NULL
last_processed_uid bigint NOT NULL DEFAULT 0
uid_validity bigint
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.meeting_attendees` (13)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
meeting_id uuid NOT NULL
contact_id uuid
email text NOT NULL
name text
role USER-DEFINED NOT NULL DEFAULT 'required'::app.attendee_role
response USER-DEFINED NOT NULL DEFAULT 'no_response'::app.attendee_response
is_internal boolean NOT NULL DEFAULT false
user_id uuid
notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
person_party_id uuid
```

### `app.meeting_modes` (4)

```
code text NOT NULL
label text NOT NULL
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
```

### `app.meeting_types` (4)

```
code text NOT NULL
label text NOT NULL
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
```

### `app.meetings` (31)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
user_id uuid NOT NULL
party_id uuid NOT NULL
engagement_id uuid
title text NOT NULL
agenda text
notes text
ai_summary text
action_items jsonb NOT NULL DEFAULT '[]'::jsonb
meeting_type text DEFAULT 'discovery'::text
meeting_mode text DEFAULT 'video_call'::text
occurred_at timestamp with time zone NOT NULL
duration_min integer NOT NULL DEFAULT 30
actual_started_at timestamp with time zone
actual_ended_at timestamp with time zone
location text
meeting_url text
status USER-DEFINED NOT NULL DEFAULT 'scheduled'::app.meeting_status
calendar_event_id uuid
follow_up_task_ids ARRAY NOT NULL DEFAULT '{}'::uuid[]
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
outcome text
next_steps text
scheduled_at timestamp with time zone
channel USER-DEFINED
stage_id uuid
deleted_at timestamp with time zone
```

### `app.organizations` (17)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
name text NOT NULL
slug text NOT NULL
logo_url text
domain text
country_code text
default_language text NOT NULL DEFAULT 'ko'::text
default_timezone text NOT NULL DEFAULT 'Asia/Seoul'::text
default_currency text NOT NULL DEFAULT 'USD'::text
allowed_party_types ARRAY NOT NULL
plan text NOT NULL DEFAULT 'free'::text
plan_expires_at timestamp with time zone
settings jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
created_by uuid DEFAULT auth.uid()
```

### `app.paper_mill_paper_types` (6)

```
mill_party_id uuid NOT NULL
paper_type_id uuid NOT NULL
organization_id uuid NOT NULL
is_primary boolean NOT NULL DEFAULT false
source text
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.paper_mill_profile` (16)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
party_id uuid NOT NULL
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
main_product_category text
main_products text
headquarters text
filler_use_intensity text
europe_mills_footprint text
evidence_level text
industry_source text
auto_promoted_at timestamp with time zone
organization_id uuid NOT NULL
created_by uuid DEFAULT auth.uid()
```

### `app.paper_types` (11)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
code text NOT NULL
category text NOT NULL
label_en text NOT NULL
label_ko text NOT NULL
label_ja text NOT NULL
filler_relevance text
sort_order integer NOT NULL DEFAULT 100
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
parent_id uuid
```

### `app.parties` (35)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
party_type_id smallint NOT NULL
party_name text NOT NULL
country_code text
region text
city text
domain_normalized text
website text
email text
phone_e164 text
lei_code text
tax_id text
linkedin_url text
founded_year integer
employee_count integer
annual_revenue_usd numeric
status text NOT NULL DEFAULT 'active'::text
source text
source_external_id text
owner_user_id uuid
created_by uuid
updated_by uuid
notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
entity_type_id smallint NOT NULL
organization_id uuid NOT NULL
interest_tags jsonb NOT NULL DEFAULT '[]'::jsonb
industry_tag_id smallint
intro_ko text
intro_en text
street_address text
preferred_contact_method text
contact_form_url text
```

### `app.partner_seniority_meta` (13)

```
code USER-DEFINED NOT NULL
display_name_ko text NOT NULL
display_name_en text NOT NULL
display_name_ja text
description_en text
is_decision_maker_default boolean NOT NULL DEFAULT false
outreach_score_weight smallint NOT NULL DEFAULT 0
sort_order smallint NOT NULL DEFAULT 999
icon_emoji text
is_active boolean NOT NULL DEFAULT true
notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.party_profiles` (22)

```
party_id uuid NOT NULL
organization_id uuid NOT NULL DEFAULT 'b25de8f2-1020-482f-9012-183f63883169'::uuid
entity_kind text
hq_location text
geographies ARRAY
focus_areas ARRAY
stage_focus text
equity_model text
check_size text
relevant_programs ARRAY
corporate_partners ARRAY
application_cycle text
website text
mbg_fit_rating text
mbg_fit_notes text
summary text
sources ARRAY
source_tag text DEFAULT 'program_enrich_2026Q2'::text
verified boolean DEFAULT false
enriched_at timestamp with time zone DEFAULT now()
updated_at timestamp with time zone DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.party_supply_links` (15)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
filler_party_id uuid NOT NULL
mill_party_id uuid NOT NULL
link_type text
confidence text
active_since date
active_until date
volume_estimate text
notes text
extra_data jsonb DEFAULT '{}'::jsonb
created_at timestamp with time zone DEFAULT now()
updated_at timestamp with time zone DEFAULT now()
deleted_at timestamp with time zone
organization_id uuid NOT NULL
product_grade text
```

### `app.party_types` (10)

```
id smallint NOT NULL
code text NOT NULL
display_name_en text NOT NULL
display_name_ko text NOT NULL
display_name_ja text
description text
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.permissions` (3)

```
resource text NOT NULL
action text NOT NULL
label text
```

### `app.pipeline_funnel` (7)

```
organization_id uuid
stage_id uuid
stage_name text
sort_order integer
deal_count bigint
total_value numeric
weighted_value numeric
```

### `app.pipeline_summary` (8)

```
organization_id uuid
open_count bigint
won_count bigint
lost_count bigint
open_value numeric
avg_won_value numeric
win_rate_pct numeric
avg_cycle_days numeric
```

### `app.pipelines` (12)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
code text NOT NULL
name text NOT NULL
description text
is_default boolean NOT NULL DEFAULT false
is_active boolean NOT NULL DEFAULT true
sort_order integer NOT NULL DEFAULT 0
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
organization_id uuid NOT NULL
```

### `app.reminder_log` (8)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
user_id uuid NOT NULL
digest_date date NOT NULL
kind text NOT NULL DEFAULT 'daily_digest'::text
item_count integer NOT NULL DEFAULT 0
communication_id uuid
sent_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.response_strategies` (30)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
consultation_id uuid
engagement_id uuid
party_id uuid
party_type text
agent_id uuid
run_id uuid
ai_generated boolean NOT NULL DEFAULT true
situation_analysis text NOT NULL
key_signals ARRAY NOT NULL DEFAULT '{}'::text[]
recommended_approach text NOT NULL
key_messages ARRAY NOT NULL DEFAULT '{}'::text[]
risks_to_avoid ARRAY NOT NULL DEFAULT '{}'::text[]
questions_to_ask_internally ARRAY NOT NULL DEFAULT '{}'::text[]
confidence_score numeric
requires_human_review boolean NOT NULL DEFAULT true
requires_legal_review boolean NOT NULL DEFAULT false
requires_finance_review boolean NOT NULL DEFAULT false
status USER-DEFINED NOT NULL DEFAULT 'draft'::app.strategy_status
reviewed_by_user_id uuid
reviewed_at timestamp with time zone
review_notes text
raw_ai_output jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
deleted_at timestamp with time zone
party_type_id smallint
```

### `app.reward_tiers` (15)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
deal_id uuid NOT NULL
name text NOT NULL
description text
min_amount numeric NOT NULL
currency text NOT NULL DEFAULT 'USD'::text
limit_qty integer
claimed_qty integer NOT NULL DEFAULT 0
estimated_delivery date
sort_order integer
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.role_permissions` (4)

```
role_id uuid NOT NULL
resource text NOT NULL
action text NOT NULL
scope USER-DEFINED NOT NULL DEFAULT 'all'::app.perm_scope
```

### `app.roles` (8)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
code text NOT NULL
name text NOT NULL
description text
is_system boolean NOT NULL DEFAULT false
created_at timestamp with time zone DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.saved_views` (19)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
user_id uuid NOT NULL
organization_id uuid NOT NULL
name text NOT NULL
entity_type text NOT NULL
party_type text
filter_params jsonb NOT NULL DEFAULT '{}'::jsonb
sort_by text
is_pinned boolean NOT NULL DEFAULT false
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
description text
icon text
color text
visible_columns ARRAY NOT NULL DEFAULT '{}'::text[]
is_shared boolean NOT NULL DEFAULT false
use_count integer NOT NULL DEFAULT 0
last_used_at timestamp with time zone
created_by uuid DEFAULT auth.uid()
```

### `app.sector_aliases` (3)

```
alias text NOT NULL
canonical_code text NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.sector_focus_dropped` (3)

```
investor_profile_id uuid NOT NULL
dropped_value text NOT NULL
dropped_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.sectors` (6)

```
id smallint NOT NULL
code text NOT NULL
label_en text NOT NULL
label_ko text
sort_order smallint NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
```

### `app.slack_integrations` (11)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
slack_team_id text
slack_team_name text
webhook_url text
default_channel text
enabled boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
updated_by uuid
```

### `app.slack_notes` (10)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
body text NOT NULL
slack_user_id text
slack_user_name text
slack_team_id text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
updated_by uuid
```

### `app.stage_checklist_templates` (8)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
stage_id uuid NOT NULL
title text NOT NULL
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.stage_task_templates` (12)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
stage_id uuid NOT NULL
checklist_template_id uuid
title text NOT NULL
description text
default_priority text NOT NULL DEFAULT 'medium'::text
due_in_days integer NOT NULL DEFAULT 3
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.stages` (19)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
pipeline_id uuid NOT NULL
code text NOT NULL
name text NOT NULL
description text
sort_order integer NOT NULL DEFAULT 0
default_probability_pct integer NOT NULL DEFAULT 0
is_won boolean NOT NULL DEFAULT false
is_lost boolean NOT NULL DEFAULT false
is_terminal boolean NOT NULL DEFAULT false
color_hex text
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
organization_id uuid NOT NULL
created_by uuid DEFAULT auth.uid()
auto_on_outbound boolean NOT NULL DEFAULT false
auto_on_inbound boolean NOT NULL DEFAULT false
auto_on_meeting boolean NOT NULL DEFAULT false
```

### `app.strategy_actions` (21)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
strategy_id uuid NOT NULL
title text NOT NULL
description text
action_type USER-DEFINED NOT NULL
suggested_due_at timestamp with time zone
suggested_due_in_hours integer
suggested_due_in_days integer
suggested_owner_role text
depends_on_action_id uuid
sort_order integer NOT NULL DEFAULT 0
priority USER-DEFINED NOT NULL DEFAULT 'medium'::app.priority_level
status USER-DEFINED NOT NULL DEFAULT 'todo'::app.task_status
linked_task_id uuid
rationale text
completion_notes text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
```

### `app.strategy_outcomes` (20)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
strategy_id uuid NOT NULL
action_id uuid
was_successful boolean NOT NULL
success_metrics jsonb NOT NULL DEFAULT '{}'::jsonb
measured_at timestamp with time zone NOT NULL DEFAULT now()
measurement_method text
actual_outcome text
deviation_from_predicted text
lessons_learned text
engagement_advanced_stage boolean NOT NULL DEFAULT false
engagement_value_change_usd numeric
suitable_for_few_shot boolean NOT NULL DEFAULT false
promoted_to_few_shot_at timestamp with time zone
promoted_to_brand_voice_id uuid
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
```

### `app.tasks` (24)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
deal_id uuid NOT NULL
assigned_to_contact_id uuid
assigned_to_user_id uuid
title text NOT NULL
description text
status text NOT NULL DEFAULT 'pending'::text
priority text NOT NULL DEFAULT 'medium'::text
due_at timestamp with time zone
started_at timestamp with time zone
completed_at timestamp with time zone
estimated_minutes integer
actual_minutes integer
notes text
extra_data jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
created_by uuid
updated_by uuid
checklist_id uuid
organization_id uuid NOT NULL DEFAULT 'b25de8f2-1020-482f-9012-183f63883169'::uuid
stage_id uuid
start_at timestamp with time zone
```

### `app.team_members` (6)

```
team_id uuid NOT NULL
user_id uuid NOT NULL
organization_id uuid NOT NULL
role_in_team text NOT NULL DEFAULT 'member'::text
joined_at timestamp with time zone NOT NULL DEFAULT now()
left_at timestamp with time zone
```

### `app.teams` (13)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
name text NOT NULL
slug text NOT NULL
description text
parent_team_id uuid
focus_party_types ARRAY NOT NULL
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
deleted_at timestamp with time zone
```

### `app.template_ab_tests` (24)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
name text NOT NULL
description text
hypothesis text
variant_a_template_id uuid NOT NULL
variant_b_template_id uuid NOT NULL
variant_a_pct integer NOT NULL DEFAULT 50
primary_metric text NOT NULL DEFAULT 'reply_rate'::text
minimum_sample_size integer NOT NULL DEFAULT 100
started_at timestamp with time zone
ended_at timestamp with time zone
target_end_at timestamp with time zone
status text NOT NULL DEFAULT 'draft'::text
variant_a_sent integer NOT NULL DEFAULT 0
variant_b_sent integer NOT NULL DEFAULT 0
variant_a_metric numeric
variant_b_metric numeric
winning_variant text
confidence_level numeric
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
```

### `app.template_categories` (16)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
parent_id uuid
code text NOT NULL
name text NOT NULL
description text
applicable_party_types ARRAY NOT NULL
icon text
color_hex text
sort_order integer NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT true
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
deleted_at timestamp with time zone
```

### `app.template_variables` (18)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
variable_path text NOT NULL
display_name text NOT NULL
description text
data_type text NOT NULL
source_entity text NOT NULL
source_field text
default_value text
fallback_template text
is_pii boolean NOT NULL DEFAULT false
is_required boolean NOT NULL DEFAULT false
is_active boolean NOT NULL DEFAULT true
sample_values jsonb NOT NULL DEFAULT '[]'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
updated_by uuid
```

### `app.template_versions` (17)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL
template_id uuid NOT NULL
version_number integer NOT NULL
subject_template text NOT NULL
body_template text NOT NULL
body_html_template text
preheader text
required_variables ARRAY NOT NULL DEFAULT '{}'::text[]
change_summary text
change_reason text
diff_from_previous jsonb
is_published boolean NOT NULL DEFAULT false
published_at timestamp with time zone
published_by uuid
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
```

### `app.todo_boards` (9)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
name text NOT NULL
kind text NOT NULL DEFAULT 'todo'::text
description text
position double precision NOT NULL DEFAULT 0
created_by uuid DEFAULT auth.uid()
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `app.todo_dependencies` (5)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
item_id uuid NOT NULL
depends_on_item_id uuid NOT NULL
type text NOT NULL DEFAULT 'finish_to_start'::text
```

### `app.todo_groups` (7)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
board_id uuid NOT NULL
name text NOT NULL
color text
position double precision NOT NULL DEFAULT 0
created_by uuid DEFAULT auth.uid()
```

### `app.todo_items` (24)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
board_id uuid NOT NULL
group_id uuid
parent_item_id uuid
title text NOT NULL
description text
status text NOT NULL DEFAULT 'todo'::text
priority text
assignee_user_id uuid
start_date date
due_date date
position double precision NOT NULL DEFAULT 0
party_id uuid
contact_id uuid
communication_id uuid
custom jsonb NOT NULL DEFAULT '{}'::jsonb
archived_at timestamp with time zone
created_by uuid DEFAULT auth.uid()
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
recurrence text
recurrence_ends date
recurrence_parent_id uuid
```

### `app.todo_status_options` (8)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
board_id uuid NOT NULL
key text NOT NULL
label text NOT NULL
color text
position double precision NOT NULL DEFAULT 0
is_done boolean NOT NULL DEFAULT false
```

### `app.todo_updates` (9)

```
id uuid NOT NULL DEFAULT gen_random_uuid()
organization_id uuid NOT NULL DEFAULT app.current_organization_id()
item_id uuid NOT NULL
author_user_id uuid DEFAULT auth.uid()
kind text NOT NULL DEFAULT 'comment'::text
body text
meta jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid DEFAULT auth.uid()
```

### `app.user_roles` (3)

```
user_id uuid NOT NULL
role_id uuid NOT NULL
organization_id uuid NOT NULL
```

### `app.users` (24)

```
id uuid NOT NULL
organization_id uuid NOT NULL
email text NOT NULL
full_name text NOT NULL
display_name text
avatar_url text
phone text
job_title text
department text
preferred_language text NOT NULL DEFAULT 'ko'::text
timezone text NOT NULL DEFAULT 'Asia/Seoul'::text
is_active boolean NOT NULL DEFAULT true
is_owner boolean NOT NULL DEFAULT false
sending_email text
sending_signature text
last_seen_at timestamp with time zone
settings jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
deleted_at timestamp with time zone
email_personal text
email_role text
email_shared text
created_by uuid DEFAULT auth.uid()
```

---

## PART C — 뷰

### `app.investor_directory_tags_v` (8)

```
party_id uuid
organization_id uuid
investor_profile_id uuid
interest_tags ARRAY
interest_tags_ko ARRAY
tags_display text
tags_sort_key text
tag_count integer
```

### `app.v_account_scores` (14)

```
party_id uuid
party_name text
party_type text
country_code text
score numeric
tier text
fit_pts numeric
recency_pts numeric
frequency_pts numeric
meeting_pts numeric
deal_pts numeric
factors jsonb
computed_at timestamp with time zone
organization_id uuid
```

### `app.v_application_field_status` (30)

```
form_id uuid
organization_id uuid
party_id uuid
party_name text
form_url text
form_status text
deadline date
field_id uuid
seq integer
label text
field_type text
max_length integer
is_required boolean
answer_id uuid
answer_key text
disclosure_level text
final_text text
char_count integer
is_copied boolean
field_state text
submission_method text
submit_email text
login_required boolean
attachments ARRAY
selector text
selector_type text
input_kind text
form_type text
canonical_key text
answer_variant text
```

### `app.v_email_do_not_send` (5)

```
email_lower text
party_id uuid
last_event_at timestamp with time zone
outcomes text
is_follow_up boolean
```

### `app.v_filler_classes` (7)

```
supplier_id uuid
party_name text
country_code text
mineral_class text
supply_model text
evidence_level text
organization_id uuid
```

### `app.v_investor_stages` (8)

```
investor_id uuid
party_name text
country_code text
stage_code text
label_ko text
label_en text
label_ja text
organization_id uuid
```

### `app.v_investor_types` (8)

```
party_id uuid
party_name text
region text
city text
type_code text
type_name text
investor_category text
source text
```

### `app.v_paper_mill_types` (14)

```
mill_id uuid
party_name text
country_code text
city text
filler_use_intensity text
paper_type_id uuid
type_code text
category text
label_ko text
label_en text
label_ja text
filler_relevance text
is_primary boolean
organization_id uuid
```

---

## PART D — 이 파일 재생성

Supabase SQL Editor에서 아래를 두 번 실행(에디터 100행 제한 회피) 후 CSV Export:

```sql
-- 1편
SELECT table_name, count(*) AS n_cols,
       string_agg(column_name || ' ' || data_type
         || CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END
         || CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default ELSE '' END,
         ' | ' ORDER BY ordinal_position) AS columns
FROM information_schema.columns
WHERE table_schema = 'app'
GROUP BY table_name ORDER BY table_name;
```

```sql
-- 2편 (1편 마지막 table_name으로 커서 이동)
SELECT table_name, count(*) AS n_cols,
       string_agg(column_name || ' ' || data_type
         || CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END
         || CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default ELSE '' END,
         ' | ' ORDER BY ordinal_position) AS columns
FROM information_schema.columns
WHERE table_schema = 'app' AND table_name > 'stage_checklist_templates'
GROUP BY table_name ORDER BY table_name;
```

> 이 참조본은 **컬럼명·타입·NULL·default만** 담는다. FK/제약/RLS는 포함하지 않는다.
> generated types(`src/types/...`)는 누락 컬럼이 있으므로(`preferred_contact_method`, `contact_form_url` 등) 신뢰하지 말 것 — DB가 정본이다.
