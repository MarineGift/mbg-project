# 'filler' string literal grep 寃곌낵

- **?앹꽦 ?쒓컖**: 2026-05-26 02:05:23
- **寃??踰붿쐞**: `src/**/*.{ts,tsx}`
- **寃???⑦꽩**: `'filler'`, `"filler"`, `iller ` (quote 濡??섎윭?몄씤 ?뺥솗??留ㅼ튂)
- **?쒖쇅**: ?앸퀎??(`fillerData`, `FillerSupplier` ??, 'filler_supplier'
- **珥??뚯씪**: 336
- **留ㅼ튂 ?뚯씪**: 31
- **留ㅼ튂 ?쇱씤 珥앺빀**: 8852

## ?뚯씪蹂?留ㅼ튂 遺꾪룷

| Count | File |
|---:|---|
| 2510 | `src\types\database.ts` |
| 444 | `src\types\email.ts` |
| 419 | `src\__tests__\ai\claude-client.test.ts` |
| 402 | `src\__tests__\email\mailcarrier.test.ts` |
| 387 | `src\workers\consultation-worker.ts` |
| 384 | `src\__tests__\email\processor.test.ts` |
| 376 | `src\__tests__\email\header-parser.test.ts` |
| 372 | `src\__tests__\workers\consultation-worker.test.ts` |
| 330 | `src\__tests__\email\auto-send-gate.test.ts` |
| 304 | `src\workers\mail-merge-worker.ts` |
| 275 | `src\__tests__\step4\action-schemas.test.ts` |
| 261 | `src\workers\mailcarrier-worker.ts` |
| 233 | `src\__tests__\email\tabs-mailer.test.ts` |
| 169 | `src\__tests__\setup\supabase-mock.ts` |
| 162 | `src\__tests__\email\quiet-hours.test.ts` |
| 153 | `src\types\phase22a.ts` |
| 149 | `src\types\industry-link.ts` |
| 149 | `src\types\party-type.ts` |
| 147 | `src\types\draft-detail.ts` |
| 139 | `src\__tests__\step4\url-parsers.test.ts` |
| 130 | `src\workers\runtime.ts` |
| 128 | `src\types\engagement.ts` |
| 124 | `src\types\party-detail.ts` |
| 113 | `src\__tests__\step4\i18n-completeness.test.ts` |
| 112 | `src\types\inbox.ts` |
| 106 | `src\types\draft-queue.ts` |
| 91 | `src\workers\draft-expiry-worker.ts` |
| 91 | `src\types\phase21b.ts` |
| 80 | `src\types\task.ts` |
| 58 | `src\__tests__\setup\env-setup.ts` |
| 54 | `src\types\phase21.ts` |

## ?쇱씤蹂??곸꽭

### `src\types\database.ts`

**L10336**
```typescript
        | "filler"
```

**L10337**
```typescript
        | "filler_supplier"
```

**L10338**
```typescript
        | "government_grant"
```

**L10339**
```typescript
        | "buyer"
```

**L10340**
```typescript
      pipeline_stage_type:
```

**L10341**
```typescript
        | "lead"
```

**L10342**
```typescript
        | "qualified"
```

**L10343**
```typescript
        | "proposal"
```

**L10344**
```typescript
        | "negotiation"
```

**L10345**
```typescript
        | "won"
```

**L10346**
```typescript
        | "lost"
```

**L10347**
```typescript
      priority_level: "low" | "medium" | "high" | "urgent"
```

**L10348**
```typescript
      scraping_job_status:
```

**L10349**
```typescript
        | "queued"
```

**L10350**
```typescript
        | "running"
```

**L10351**
```typescript
        | "completed"
```

**L10352**
```typescript
        | "failed"
```

**L10353**
```typescript
        | "cancelled"
```

**L10354**
```typescript
        | "rate_limited"
```

**L10355**
```typescript
      scraping_source_type:
```

**L10356**
```typescript
        | "industry_directory"
```

**L10357**
```typescript
        | "public_disclosure"
```

**L10358**
```typescript
        | "company_website"
```

**L10359**
```typescript
        | "gleif_lei"
```

**L10360**
```typescript
        | "sec_edgar"
```

**L10361**
```typescript
        | "dart_kr"
```

**L10362**
```typescript
        | "press_release"
```

**L10363**
```typescript
        | "other"
```

**L10364**
```typescript
      send_status: "pending" | "sent" | "skipped" | "bounced" | "failed"
```

**L10365**
```typescript
      strategy_status: "draft" | "active" | "completed" | "abandoned"
```

**L10366**
```typescript
      strategy_type: "immediate" | "short_term" | "long_term"
```

**L10367**
```typescript
      supply_link_type: "potential" | "active" | "historical"
```

**L10368**
```typescript
      sync_operation:
```

**L10369**
```typescript
        | "pull"
```

**L10370**
```typescript
        | "push"
```

**L10371**
```typescript
        | "match_party"
```

**L10372**
```typescript
        | "promote"
```

**L10373**
```typescript
        | "conflict"
```

**L10374**
```typescript
        | "error"
```

**L10375**
```typescript
      task_status: "todo" | "in_progress" | "blocked" | "done" | "cancelled"
```

**L10376**
```typescript
      template_status: "draft" | "active" | "archived" | "deprecated"
```

**L10377**
```typescript
      tier_level: "tier_1" | "tier_2" | "tier_3" | "tier_4" | "tier_5"
```

**L10378**
```typescript
    }
```

**L10379**
```typescript
    CompositeTypes: {
```

**L10380**
```typescript
      [_ in never]: never
```

**L10381**
```typescript
    }
```

**L10382**
```typescript
  }
```

**L10383**
```typescript
  public: {
```

**L10384**
```typescript
    Tables: {
```

**L10385**
```typescript
      [_ in never]: never
```

**L10386**
```typescript
    }
```

**L10387**
```typescript
    Views: {
```

**L10388**
```typescript
      [_ in never]: never
```

**L10389**
```typescript
    }
```

**L10390**
```typescript
    Functions: {
```

**L10391**
```typescript
      add_email_whitelist: {
```

**L10392**
```typescript
        Args: {
```

**L10393**
```typescript
          p_kind: string
```

**L10394**
```typescript
          p_notes?: string
```

**L10395**
```typescript
          p_org_id: string
```

**L10396**
```typescript
          p_pattern: string
```

**L10397**
```typescript
        }
```

**L10398**
```typescript
        Returns: string
```

**L10399**
```typescript
      }
```

**L10400**
```typescript
      advance_enrollment: {
```

**L10401**
```typescript
        Args: {
```

**L10402**
```typescript
          p_communication_id: string
```

**L10403**
```typescript
          p_enrollment_id: string
```

**L10404**
```typescript
          p_is_last_step: boolean
```

**L10405**
```typescript
          p_status?: Database["app"]["Enums"]["send_status"]
```

**L10406**
```typescript
          p_step_id: string
```

**L10407**
```typescript
          p_step_order: number
```

**L10408**
```typescript
        }
```

**L10409**
```typescript
        Returns: undefined
```

**L10410**
```typescript
      }
```

**L10411**
```typescript
      archive_sequence: { Args: { p_sequence_id: string }; Returns: undefined }
```

**L10412**
```typescript
      bulk_enroll_filtered:
```

**L10413**
```typescript
        | {
```

**L10414**
```typescript
            Args: {
```

**L10415**
```typescript
              p_country_code?: string
```

**L10416**
```typescript
              p_dry_run?: boolean
```

**L10417**
```typescript
              p_enrolled_by?: string
```

**L10418**
```typescript
              p_module?: string
```

**L10419**
```typescript
              p_organization_id: string
```

**L10420**
```typescript
              p_sequence_id: string
```

**L10421**
```typescript
              p_status?: string
```

**L10422**
```typescript
              p_tiers?: string[]
```

**L10423**
```typescript
            }
```

**L10424**
```typescript
            Returns: {
```

**L10425**
```typescript
              enrolled_count: number
```

**L10426**
```typescript
              sample_names: string[]
```

**L10427**
```typescript
              skipped_already_enrolled: number
```

**L10428**
```typescript
              skipped_no_email: number
```

**L10429**
```typescript
              total_matching: number
```

**L10430**
```typescript
            }[]
```

**L10431**
```typescript
          }
```

**L10432**
```typescript
        | {
```

**L10433**
```typescript
            Args: {
```

**L10434**
```typescript
              p_country_code?: string
```

**L10435**
```typescript
              p_dry_run?: boolean
```

**L10436**
```typescript
              p_enrolled_by?: string
```

**L10437**
```typescript
              p_industry_tag?: string
```

**L10438**
```typescript
              p_module?: string
```

**L10439**
```typescript
              p_name_contains?: string
```

**L10440**
```typescript
              p_organization_id: string
```

**L10441**
```typescript
              p_sequence_id: string
```

**L10442**
```typescript
              p_status?: string
```

**L10443**
```typescript
              p_tiers?: string[]
```

**L10444**
```typescript
            }
```

**L10445**
```typescript
            Returns: {
```

**L10446**
```typescript
              enrolled_count: number
```

**L10447**
```typescript
              sample_names: string[]
```

**L10448**
```typescript
              skipped_already_enrolled: number
```

**L10449**
```typescript
              skipped_no_email: number
```

**L10450**
```typescript
              total_matching: number
```

**L10451**
```typescript
            }[]
```

**L10452**
```typescript
          }
```

**L10453**
```typescript
      cancel_enrollment: {
```

**L10454**
```typescript
        Args: { p_enrollment_id: string }
```

**L10455**
```typescript
        Returns: undefined
```

**L10456**
```typescript
      }
```

**L10457**
```typescript
      count_email_history: {
```

**L10458**
```typescript
        Args: { p_organization_id: string }
```

**L10459**
```typescript
        Returns: number
```

**L10460**
```typescript
      }
```

**L10461**
```typescript
      create_campaign_from_template:
```

**L10462**
```typescript
        | {
```

**L10463**
```typescript
            Args: {
```

**L10464**
```typescript
              p_campaign_name: string
```

**L10465**
```typescript
              p_country_code?: string
```

**L10466**
```typescript
              p_enrolled_by?: string
```

**L10467**
```typescript
              p_module?: string
```

**L10468**
```typescript
              p_organization_id: string
```

**L10469**
```typescript
              p_status?: string
```

**L10470**
```typescript
              p_template_id: string
```

**L10471**
```typescript
              p_tiers?: string[]
```

**L10472**
```typescript
            }
```

**L10473**
```typescript
            Returns: {
```

**L10474**
```typescript
              enrolled_count: number
```

**L10475**
```typescript
              sample_names: string[]
```

**L10476**
```typescript
              sequence_id: string
```

**L10477**
```typescript
              skipped_already_enrolled: number
```

**L10478**
```typescript
              skipped_no_email: number
```

**L10479**
```typescript
              total_matching: number
```

**L10480**
```typescript
            }[]
```

**L10481**
```typescript
          }
```

**L10482**
```typescript
        | {
```

**L10483**
```typescript
            Args: {
```

**L10484**
```typescript
              p_campaign_name: string
```

**L10485**
```typescript
              p_country_code?: string
```

**L10486**
```typescript
              p_enrolled_by?: string
```

**L10487**
```typescript
              p_industry_tag?: string
```

**L10488**
```typescript
              p_module?: string
```

**L10489**
```typescript
              p_name_contains?: string
```

**L10490**
```typescript
              p_organization_id: string
```

**L10491**
```typescript
              p_status?: string
```

**L10492**
```typescript
              p_template_id: string
```

**L10493**
```typescript
              p_tiers?: string[]
```

**L10494**
```typescript
            }
```

**L10495**
```typescript
            Returns: {
```

**L10496**
```typescript
              enrolled_count: number
```

**L10497**
```typescript
              sample_names: string[]
```

**L10498**
```typescript
              sequence_id: string
```

**L10499**
```typescript
              skipped_already_enrolled: number
```

**L10500**
```typescript
              skipped_no_email: number
```

**L10501**
```typescript
              total_matching: number
```

**L10502**
```typescript
            }[]
```

**L10503**
```typescript
          }
```

**L10504**
```typescript
      create_email_tracking: {
```

**L10505**
```typescript
        Args: {
```

**L10506**
```typescript
          p_communication_id?: string
```

**L10507**
```typescript
          p_contact_id?: string
```

**L10508**
```typescript
          p_draft_id?: string
```

**L10509**
```typescript
          p_links?: Json
```

**L10510**
```typescript
          p_org_id: string
```

**L10511**
```typescript
          p_party_id?: string
```

**L10512**
```typescript
          p_sent_to?: string
```

**L10513**
```typescript
          p_subject?: string
```

**L10514**
```typescript
        }
```

**L10515**
```typescript
        Returns: Json
```

**L10516**
```typescript
      }
```

**L10517**
```typescript
      create_sequence: {
```

**L10518**
```typescript
        Args: {
```

**L10519**
```typescript
          p_description: string
```

**L10520**
```typescript
          p_name: string
```

**L10521**
```typescript
          p_organization_id: string
```

**L10522**
```typescript
          p_steps: Json
```

**L10523**
```typescript
        }
```

**L10524**
```typescript
        Returns: string
```

**L10525**
```typescript
      }
```

**L10526**
```typescript
      custom_access_token_hook: { Args: { event: Json }; Returns: Json }
```

**L10527**
```typescript
      delete_email_whitelist: { Args: { p_id: string }; Returns: undefined }
```

**L10528**
```typescript
      enroll_in_sequence: {
```

**L10529**
```typescript
        Args: {
```

**L10530**
```typescript
          p_contact_id: string
```

**L10531**
```typescript
          p_enrolled_by: string
```

**L10532**
```typescript
          p_organization_id: string
```

**L10533**
```typescript
          p_party_id: string
```

**L10534**
```typescript
          p_sequence_id: string
```

**L10535**
```typescript
        }
```

**L10536**
```typescript
        Returns: string
```

**L10537**
```typescript
      }
```

**L10538**
```typescript
      get_communications_stats_per_party: {
```

**L10539**
```typescript
        Args: { p_party_id: string }
```

**L10540**
```typescript
        Returns: {
```

**L10541**
```typescript
          opened: number
```

**L10542**
```typescript
          received: number
```

**L10543**
```typescript
          replied: number
```

**L10544**
```typescript
          sent: number
```

**L10545**
```typescript
          threads: number
```

**L10546**
```typescript
          total: number
```

**L10547**
```typescript
        }[]
```

**L10548**
```typescript
      }
```

**L10549**
```typescript
      get_contact_communications_timeline: {
```

**L10550**
```typescript
        Args: { p_contact_id: string; p_limit?: number }
```

**L10551**
```typescript
        Returns: {
```

**L10552**
```typescript
          ai_classification: Json
```

**L10553**
```typescript
          ai_generated: boolean
```

**L10554**
```typescript
          body_html: string
```

**L10555**
```typescript
          body_plain: string
```

**L10556**
```typescript
          body_summary: string
```

**L10557**
```typescript
          clicked_at: string
```

**L10558**
```typescript
          direction: string
```

**L10559**
```typescript
          from_address: string
```

**L10560**
```typescript
          from_name: string
```

**L10561**
```typescript
          id: string
```

**L10562**
```typescript
          in_reply_to: string
```

**L10563**
```typescript
          is_starred: boolean
```

**L10564**
```typescript
          message_id: string
```

**L10565**
```typescript
          occurred_at: string
```

**L10566**
```typescript
          opened_at: string
```

**L10567**
```typescript
          received_at: string
```

**L10568**
```typescript
          replied_at: string
```

**L10569**
```typescript
          sent_at: string
```

**L10570**
```typescript
          status: string
```

**L10571**
```typescript
          subject: string
```

**L10572**
```typescript
          template_id: string
```

**L10573**
```typescript
          thread_id: string
```

**L10574**
```typescript
          thread_position: number
```

**L10575**
```typescript
          to_addresses: string[]
```

**L10576**
```typescript
        }[]
```

**L10577**
```typescript
      }
```

**L10578**
```typescript
      get_due_enrollments: {
```

**L10579**
```typescript
        Args: never
```

**L10580**
```typescript
        Returns: {
```

**L10581**
```typescript
          contact_id: string
```

**L10582**
```typescript
          enrolled_at: string
```

**L10583**
```typescript
          enrolled_by: string
```

**L10584**
```typescript
          enrollment_id: string
```

**L10585**
```typescript
          is_last_step: boolean
```

**L10586**
```typescript
          next_step_order: number
```

**L10587**
```typescript
          organization_id: string
```

**L10588**
```typescript
          party_id: string
```

**L10589**
```typescript
          sequence_id: string
```

**L10590**
```typescript
          step_body_text: string
```

**L10591**
```typescript
          step_day_offset: number
```

**L10592**
```typescript
          step_id: string
```

**L10593**
```typescript
          step_subject: string
```

**L10594**
```typescript
        }[]
```

**L10595**
```typescript
      }
```

**L10596**
```typescript
      get_email_history: {
```

**L10597**
```typescript
        Args: { p_limit?: number; p_offset?: number; p_organization_id: string }
```

**L10598**
```typescript
        Returns: {
```

**L10599**
```typescript
          click_count: number
```

**L10600**
```typescript
          communication_id: string
```

**L10601**
```typescript
          contact_email: string
```

**L10602**
```typescript
          contact_full_name: string
```

**L10603**
```typescript
          enrollment_id: string
```

**L10604**
```typescript
          first_opened_at: string
```

**L10605**
```typescript
          open_count: number
```

**L10606**
```typescript
          party_id: string
```

**L10607**
```typescript
          party_name: string
```

**L10608**
```typescript
          send_id: string
```

**L10609**
```typescript
          send_status: Database["app"]["Enums"]["send_status"]
```

**L10610**
```typescript
          sent_at: string
```

**L10611**
```typescript
          sequence_id: string
```

**L10612**
```typescript
          sequence_name: string
```

**L10613**
```typescript
          step_order: number
```

**L10614**
```typescript
        }[]
```

**L10615**
```typescript
      }
```

**L10616**
```typescript
      get_lead_scores_many: {
```

**L10617**
```typescript
        Args: { p_party_ids: string[] }
```

**L10618**
```typescript
        Returns: {
```

**L10619**
```typescript
          computed_at: string
```

**L10620**
```typescript
          factors: Json
```

**L10621**
```typescript
          party_id: string
```

**L10622**
```typescript
          score: number
```

**L10623**
```typescript
        }[]
```

**L10624**
```typescript
      }
```

**L10625**
```typescript
      get_party_communications_timeline: {
```

**L10626**
```typescript
        Args: { p_limit?: number; p_party_id: string }
```

**L10627**
```typescript
        Returns: {
```

**L10628**
```typescript
          ai_classification: Json
```

**L10629**
```typescript
          ai_generated: boolean
```

**L10630**
```typescript
          body_html: string
```

**L10631**
```typescript
          body_plain: string
```

**L10632**
```typescript
          body_summary: string
```

**L10633**
```typescript
          clicked_at: string
```

**L10634**
```typescript
          contact_email: string
```

**L10635**
```typescript
          contact_id: string
```

**L10636**
```typescript
          contact_name: string
```

**L10637**
```typescript
          direction: string
```

**L10638**
```typescript
          from_address: string
```

**L10639**
```typescript
          from_name: string
```

**L10640**
```typescript
          id: string
```

**L10641**
```typescript
          in_reply_to: string
```

**L10642**
```typescript
          is_starred: boolean
```

**L10643**
```typescript
          message_id: string
```

**L10644**
```typescript
          occurred_at: string
```

**L10645**
```typescript
          opened_at: string
```

**L10646**
```typescript
          received_at: string
```

**L10647**
```typescript
          replied_at: string
```

**L10648**
```typescript
          sent_at: string
```

**L10649**
```typescript
          status: string
```

**L10650**
```typescript
          subject: string
```

**L10651**
```typescript
          template_id: string
```

**L10652**
```typescript
          thread_id: string
```

**L10653**
```typescript
          thread_position: number
```

**L10654**
```typescript
          to_addresses: string[]
```

**L10655**
```typescript
        }[]
```

**L10656**
```typescript
      }
```

**L10657**
```typescript
      get_party_enrollments: {
```

**L10658**
```typescript
        Args: { p_party_id: string }
```

**L10659**
```typescript
        Returns: {
```

**L10660**
```typescript
          enrolled_at: string
```

**L10661**
```typescript
          id: string
```

**L10662**
```typescript
          next_send_at: string
```

**L10663**
```typescript
          next_step_order: number
```

**L10664**
```typescript
          sends_count: number
```

**L10665**
```typescript
          sequence_id: string
```

**L10666**
```typescript
          sequence_name: string
```

**L10667**
```typescript
          status: Database["app"]["Enums"]["enrollment_status"]
```

**L10668**
```typescript
          total_steps: number
```

**L10669**
```typescript
        }[]
```

**L10670**
```typescript
      }
```

**L10671**
```typescript
      get_sequence_with_steps: {
```

**L10672**
```typescript
        Args: { p_sequence_id: string }
```

**L10673**
```typescript
        Returns: Json
```

**L10674**
```typescript
      }
```

**L10675**
```typescript
      get_thread_context: {
```

**L10676**
```typescript
        Args: { p_communication_id: string }
```

**L10677**
```typescript
        Returns: Json
```

**L10678**
```typescript
      }
```

**L10679**
```typescript
      get_tracking_for_communications: {
```

**L10680**
```typescript
        Args: { p_communication_ids: string[] }
```

**L10681**
```typescript
        Returns: {
```

**L10682**
```typescript
          click_count: number
```

**L10683**
```typescript
          communication_id: string
```

**L10684**
```typescript
          first_opened_at: string
```

**L10685**
```typescript
          open_count: number
```

**L10686**
```typescript
          sent_at: string
```

**L10687**
```typescript
          tracking_id: string
```

**L10688**
```typescript
        }[]
```

**L10689**
```typescript
      }
```

**L10690**
```typescript
      get_tracking_for_drafts: {
```

**L10691**
```typescript
        Args: { p_draft_ids: string[] }
```

**L10692**
```typescript
        Returns: {
```

**L10693**
```typescript
          click_count: number
```

**L10694**
```typescript
          draft_id: string
```

**L10695**
```typescript
          first_opened_at: string
```

**L10696**
```typescript
          open_count: number
```

**L10697**
```typescript
          sent_at: string
```

**L10698**
```typescript
          tracking_id: string
```

**L10699**
```typescript
        }[]
```

**L10700**
```typescript
      }
```

**L10701**
```typescript
      get_unregistered_party_domains: {
```

**L10702**
```typescript
        Args: { p_org_id: string }
```

**L10703**
```typescript
        Returns: {
```

**L10704**
```typescript
          contact_count: number
```

**L10705**
```typescript
          domain: string
```

**L10706**
```typescript
          party_names: string
```

**L10707**
```typescript
        }[]
```

**L10708**
```typescript
      }
```

**L10709**
```typescript
      get_upcoming_meetings: {
```

**L10710**
```typescript
        Args: { p_days_ahead?: number; p_user_id?: string }
```

**L10711**
```typescript
        Returns: {
```

**L10712**
```typescript
          channel: Database["app"]["Enums"]["engagement_channel"]
```

**L10713**
```typescript
          duration_min: number
```

**L10714**
```typescript
          meeting_id: string
```

**L10715**
```typescript
          party_id: string
```

**L10716**
```typescript
          party_name: string
```

**L10717**
```typescript
          scheduled_at: string
```

**L10718**
```typescript
          status: Database["app"]["Enums"]["meeting_status"]
```

**L10719**
```typescript
          title: string
```

**L10720**
```typescript
        }[]
```

**L10721**
```typescript
      }
```

**L10722**
```typescript
      list_active_templates: {
```

**L10723**
```typescript
        Args: { p_org_id: string }
```

**L10724**
```typescript
        Returns: {
```

**L10725**
```typescript
          body_plain: string
```

**L10726**
```typescript
          category: string
```

**L10727**
```typescript
          id: string
```

**L10728**
```typescript
          module: string
```

**L10729**
```typescript
          name: string
```

**L10730**
```typescript
          subject: string
```

**L10731**
```typescript
        }[]
```

**L10732**
```typescript
      }
```

**L10733**
```typescript
      list_email_whitelist: {
```

**L10734**
```typescript
        Args: { p_org_id: string }
```

**L10735**
```typescript
        Returns: {
```

**L10736**
```typescript
          created_at: string
```

**L10737**
```typescript
          id: string
```

**L10738**
```typescript
          is_active: boolean
```

**L10739**
```typescript
          kind: string
```

**L10740**
```typescript
          notes: string
```

**L10741**
```typescript
          pattern: string
```

**L10742**
```typescript
        }[]
```

**L10743**
```typescript
      }
```

**L10744**
```typescript
      list_sequences: {
```

**L10745**
```typescript
        Args: { p_organization_id: string }
```

**L10746**
```typescript
        Returns: {
```

**L10747**
```typescript
          active_enrollments: number
```

**L10748**
```typescript
          created_at: string
```

**L10749**
```typescript
          description: string
```

**L10750**
```typescript
          id: string
```

**L10751**
```typescript
          name: string
```

**L10752**
```typescript
          status: Database["app"]["Enums"]["email_sequence_status"]
```

**L10753**
```typescript
          step_count: number
```

**L10754**
```typescript
          total_sends: number
```

**L10755**
```typescript
        }[]
```

**L10756**
```typescript
      }
```

**L10757**
```typescript
      list_templates_for_compose: {
```

**L10758**
```typescript
        Args: { p_module?: string; p_org_id: string }
```

**L10759**
```typescript
        Returns: {
```

**L10760**
```typescript
          body_html: string
```

**L10761**
```typescript
          body_plain: string
```

**L10762**
```typescript
          category: string
```

**L10763**
```typescript
          id: string
```

**L10764**
```typescript
          module: string
```

**L10765**
```typescript
          name: string
```

**L10766**
```typescript
          subject: string
```

**L10767**
```typescript
        }[]
```

**L10768**
```typescript
      }
```

**L10769**
```typescript
      preview_campaign_filter:
```

**L10770**
```typescript
        | {
```

**L10771**
```typescript
            Args: {
```

**L10772**
```typescript
              p_country_code?: string
```

**L10773**
```typescript
              p_module?: string
```

**L10774**
```typescript
              p_org_id: string
```

**L10775**
```typescript
              p_status?: string
```

**L10776**
```typescript
              p_tiers?: string[]
```

**L10777**
```typescript
            }
```

**L10778**
```typescript
            Returns: {
```

**L10779**
```typescript
              no_email: number
```

**L10780**
```typescript
              sample_names: string[]
```

**L10781**
```typescript
              total_matching: number
```

**L10782**
```typescript
              with_email: number
```

**L10783**
```typescript
            }[]
```

**L10784**
```typescript
          }
```

**L10785**
```typescript
        | {
```

**L10786**
```typescript
            Args: {
```

**L10787**
```typescript
              p_country_code?: string
```

**L10788**
```typescript
              p_industry_tag?: string
```

**L10789**
```typescript
              p_module?: string
```

**L10790**
```typescript
              p_name_contains?: string
```

**L10791**
```typescript
              p_org_id: string
```

**L10792**
```typescript
              p_status?: string
```

**L10793**
```typescript
              p_tiers?: string[]
```

**L10794**
```typescript
            }
```

**L10795**
```typescript
            Returns: {
```

**L10796**
```typescript
              no_email: number
```

**L10797**
```typescript
              sample_names: string[]
```

**L10798**
```typescript
              total_matching: number
```

**L10799**
```typescript
              with_email: number
```

**L10800**
```typescript
            }[]
```

**L10801**
```typescript
          }
```

**L10802**
```typescript
      record_email_click: {
```

**L10803**
```typescript
        Args: { p_ip?: string; p_token: string; p_ua?: string }
```

**L10804**
```typescript
        Returns: string
```

**L10805**
```typescript
      }
```

**L10806**
```typescript
      record_email_open: {
```

**L10807**
```typescript
        Args: { p_ip?: string; p_token: string; p_ua?: string }
```

**L10808**
```typescript
        Returns: undefined
```

**L10809**
```typescript
      }
```

**L10810**
```typescript
      save_manual_email: {
```

**L10811**
```typescript
        Args: {
```

**L10812**
```typescript
          p_ai_generated?: boolean
```

**L10813**
```typescript
          p_body_html: string
```

**L10814**
```typescript
          p_body_plain: string
```

**L10815**
```typescript
          p_contact_id: string
```

**L10816**
```typescript
          p_from_address: string
```

**L10817**
```typescript
          p_from_name: string
```

**L10818**
```typescript
          p_in_reply_to?: string
```

**L10819**
```typescript
          p_org_id: string
```

**L10820**
```typescript
          p_party_id: string
```

**L10821**
```typescript
          p_sent_by_user_id?: string
```

**L10822**
```typescript
          p_status?: string
```

**L10823**
```typescript
          p_subject: string
```

**L10824**
```typescript
          p_template_id?: string
```

**L10825**
```typescript
          p_to_addresses: string[]
```

**L10826**
```typescript
        }
```

**L10827**
```typescript
        Returns: string
```

**L10828**
```typescript
      }
```

**L10829**
```typescript
      show_limit: { Args: never; Returns: number }
```

**L10830**
```typescript
      show_trgm: { Args: { "": string }; Returns: string[] }
```

**L10831**
```typescript
      toggle_email_whitelist: {
```

**L10832**
```typescript
        Args: { p_active: boolean; p_id: string }
```

**L10833**
```typescript
        Returns: undefined
```

**L10834**
```typescript
      }
```

**L10835**
```typescript
      unaccent: { Args: { "": string }; Returns: string }
```

**L10836**
```typescript
      update_sequence: {
```

**L10837**
```typescript
        Args: {
```

**L10838**
```typescript
          p_description: string
```

**L10839**
```typescript
          p_name: string
```

**L10840**
```typescript
          p_sequence_id: string
```

**L10841**
```typescript
          p_steps: Json
```

**L10842**
```typescript
        }
```

**L10843**
```typescript
        Returns: undefined
```

**L10844**
```typescript
      }
```

**L10845**
```typescript
    }
```

**L10846**
```typescript
    Enums: {
```

**L10847**
```typescript
      tier_role: "HQ" | "Regional" | "Country" | "Plant"
```

**L10848**
```typescript
    }
```

**L10849**
```typescript
    CompositeTypes: {
```

**L10850**
```typescript
      [_ in never]: never
```

**L10851**
```typescript
    }
```

**L10852**
```typescript
  }
```

**L10853**
```typescript
  urm: {
```

**L10854**
```typescript
    Tables: {
```

**L10855**
```typescript
      contact_types: {
```

**L10856**
```typescript
        Row: {
```

**L10857**
```typescript
          code: string
```

**L10858**
```typescript
          created_at: string
```

**L10859**
```typescript
          description: string | null
```

**L10860**
```typescript
          display_name_en: string
```

**L10861**
```typescript
          display_name_ja: string | null
```

**L10862**
```typescript
          display_name_ko: string
```

**L10863**
```typescript
          id: number
```

**L10864**
```typescript
          is_active: boolean
```

**L10865**
```typescript
          sort_order: number
```

**L10866**
```typescript
          updated_at: string
```

**L10867**
```typescript
        }
```

**L10868**
```typescript
        Insert: {
```

**L10869**
```typescript
          code: string
```

**L10870**
```typescript
          created_at?: string
```

**L10871**
```typescript
          description?: string | null
```

**L10872**
```typescript
          display_name_en: string
```

**L10873**
```typescript
          display_name_ja?: string | null
```

**L10874**
```typescript
          display_name_ko: string
```

**L10875**
```typescript
          id: number
```

**L10876**
```typescript
          is_active?: boolean
```

**L10877**
```typescript
          sort_order?: number
```

**L10878**
```typescript
          updated_at?: string
```

**L10879**
```typescript
        }
```

**L10880**
```typescript
        Update: {
```

**L10881**
```typescript
          code?: string
```

**L10882**
```typescript
          created_at?: string
```

**L10883**
```typescript
          description?: string | null
```

**L10884**
```typescript
          display_name_en?: string
```

**L10885**
```typescript
          display_name_ja?: string | null
```

**L10886**
```typescript
          display_name_ko?: string
```

**L10887**
```typescript
          id?: number
```

**L10888**
```typescript
          is_active?: boolean
```

**L10889**
```typescript
          sort_order?: number
```

**L10890**
```typescript
          updated_at?: string
```

**L10891**
```typescript
        }
```

**L10892**
```typescript
        Relationships: []
```

**L10893**
```typescript
      }
```

**L10894**
```typescript
      contacts: {
```

**L10895**
```typescript
        Row: {
```

**L10896**
```typescript
          background: string | null
```

**L10897**
```typescript
          contact_type_id: number
```

**L10898**
```typescript
          created_at: string
```

**L10899**
```typescript
          deleted_at: string | null
```

**L10900**
```typescript
          department: string | null
```

**L10901**
```typescript
          education: string | null
```

**L10902**
```typescript
          email: string | null
```

**L10903**
```typescript
          email_secondary: string | null
```

**L10904**
```typescript
          family_name: string | null
```

**L10905**
```typescript
          firm_party_id: string
```

**L10906**
```typescript
          focus_areas: string[] | null
```

**L10907**
```typescript
          full_name: string | null
```

**L10908**
```typescript
          given_name: string | null
```

**L10909**
```typescript
          id: string
```

**L10910**
```typescript
          is_active: boolean
```

**L10911**
```typescript
          is_decision_maker: boolean
```

**L10912**
```typescript
          is_primary: boolean
```

**L10913**
```typescript
          joined_at: string | null
```

**L10914**
```typescript
          last_contacted_at: string | null
```

**L10915**
```typescript
          left_at: string | null
```

**L10916**
```typescript
          linkedin_url: string | null
```

**L10917**
```typescript
          module_data: Json
```

**L10918**
```typescript
          notes: string | null
```

**L10919**
```typescript
          phone_e164: string | null
```

**L10920**
```typescript
          phone_mobile: string | null
```

**L10921**
```typescript
          role_category: string | null
```

**L10922**
```typescript
          seniority_level: string | null
```

**L10923**
```typescript
          source: string | null
```

**L10924**
```typescript
          source_external_id: string | null
```

**L10925**
```typescript
          title_text: string | null
```

**L10926**
```typescript
          twitter_handle: string | null
```

**L10927**
```typescript
          updated_at: string
```

**L10928**
```typescript
        }
```

**L10929**
```typescript
        Insert: {
```

**L10930**
```typescript
          background?: string | null
```

**L10931**
```typescript
          contact_type_id: number
```

**L10932**
```typescript
          created_at?: string
```

**L10933**
```typescript
          deleted_at?: string | null
```

**L10934**
```typescript
          department?: string | null
```

**L10935**
```typescript
          education?: string | null
```

**L10936**
```typescript
          email?: string | null
```

**L10937**
```typescript
          email_secondary?: string | null
```

**L10938**
```typescript
          family_name?: string | null
```

**L10939**
```typescript
          firm_party_id: string
```

**L10940**
```typescript
          focus_areas?: string[] | null
```

**L10941**
```typescript
          full_name?: string | null
```

**L10942**
```typescript
          given_name?: string | null
```

**L10943**
```typescript
          id: string
```

**L10944**
```typescript
          is_active?: boolean
```

**L10945**
```typescript
          is_decision_maker?: boolean
```

**L10946**
```typescript
          is_primary?: boolean
```

**L10947**
```typescript
          joined_at?: string | null
```

**L10948**
```typescript
          last_contacted_at?: string | null
```

**L10949**
```typescript
          left_at?: string | null
```

**L10950**
```typescript
          linkedin_url?: string | null
```

**L10951**
```typescript
          module_data?: Json
```

**L10952**
```typescript
          notes?: string | null
```

**L10953**
```typescript
          phone_e164?: string | null
```

**L10954**
```typescript
          phone_mobile?: string | null
```

**L10955**
```typescript
          role_category?: string | null
```

**L10956**
```typescript
          seniority_level?: string | null
```

**L10957**
```typescript
          source?: string | null
```

**L10958**
```typescript
          source_external_id?: string | null
```

**L10959**
```typescript
          title_text?: string | null
```

**L10960**
```typescript
          twitter_handle?: string | null
```

**L10961**
```typescript
          updated_at?: string
```

**L10962**
```typescript
        }
```

**L10963**
```typescript
        Update: {
```

**L10964**
```typescript
          background?: string | null
```

**L10965**
```typescript
          contact_type_id?: number
```

**L10966**
```typescript
          created_at?: string
```

**L10967**
```typescript
          deleted_at?: string | null
```

**L10968**
```typescript
          department?: string | null
```

**L10969**
```typescript
          education?: string | null
```

**L10970**
```typescript
          email?: string | null
```

**L10971**
```typescript
          email_secondary?: string | null
```

**L10972**
```typescript
          family_name?: string | null
```

**L10973**
```typescript
          firm_party_id?: string
```

**L10974**
```typescript
          focus_areas?: string[] | null
```

**L10975**
```typescript
          full_name?: string | null
```

**L10976**
```typescript
          given_name?: string | null
```

**L10977**
```typescript
          id?: string
```

**L10978**
```typescript
          is_active?: boolean
```

**L10979**
```typescript
          is_decision_maker?: boolean
```

**L10980**
```typescript
          is_primary?: boolean
```

**L10981**
```typescript
          joined_at?: string | null
```

**L10982**
```typescript
          last_contacted_at?: string | null
```

**L10983**
```typescript
          left_at?: string | null
```

**L10984**
```typescript
          linkedin_url?: string | null
```

**L10985**
```typescript
          module_data?: Json
```

**L10986**
```typescript
          notes?: string | null
```

**L10987**
```typescript
          phone_e164?: string | null
```

**L10988**
```typescript
          phone_mobile?: string | null
```

**L10989**
```typescript
          role_category?: string | null
```

**L10990**
```typescript
          seniority_level?: string | null
```

**L10991**
```typescript
          source?: string | null
```

**L10992**
```typescript
          source_external_id?: string | null
```

**L10993**
```typescript
          title_text?: string | null
```

**L10994**
```typescript
          twitter_handle?: string | null
```

**L10995**
```typescript
          updated_at?: string
```

**L10996**
```typescript
        }
```

**L10997**
```typescript
        Relationships: [
```

**L10998**
```typescript
          {
```

**L10999**
```typescript
            foreignKeyName: "contacts_contact_type_id_fkey"
```

**L11000**
```typescript
            columns: ["contact_type_id"]
```

**L11001**
```typescript
            isOneToOne: false
```

**L11002**
```typescript
            referencedRelation: "contact_types"
```

**L11003**
```typescript
            referencedColumns: ["id"]
```

**L11004**
```typescript
          },
```

**L11005**
```typescript
          {
```

**L11006**
```typescript
            foreignKeyName: "contacts_firm_party_id_fkey"
```

**L11007**
```typescript
            columns: ["firm_party_id"]
```

**L11008**
```typescript
            isOneToOne: false
```

**L11009**
```typescript
            referencedRelation: "parties"
```

**L11010**
```typescript
            referencedColumns: ["id"]
```

**L11011**
```typescript
          },
```

**L11012**
```typescript
        ]
```

**L11013**
```typescript
      }
```

**L11014**
```typescript
      contacts_history: {
```

**L11015**
```typescript
        Row: {
```

**L11016**
```typescript
          contact_id: string
```

**L11017**
```typescript
          created_at: string | null
```

**L11018**
```typescript
          created_by: string | null
```

**L11019**
```typescript
          deleted_at: string | null
```

**L11020**
```typescript
          department: string | null
```

**L11021**
```typescript
          ended_at: string | null
```

**L11022**
```typescript
          firm_party_id: string
```

**L11023**
```typescript
          id: string
```

**L11024**
```typescript
          module_data: Json | null
```

**L11025**
```typescript
          notes: string | null
```

**L11026**
```typescript
          role_category: string | null
```

**L11027**
```typescript
          seniority_level: string | null
```

**L11028**
```typescript
          started_at: string | null
```

**L11029**
```typescript
          title_text: string | null
```

**L11030**
```typescript
          updated_at: string | null
```

**L11031**
```typescript
          updated_by: string | null
```

**L11032**
```typescript
        }
```

**L11033**
```typescript
        Insert: {
```

**L11034**
```typescript
          contact_id: string
```

**L11035**
```typescript
          created_at?: string | null
```

**L11036**
```typescript
          created_by?: string | null
```

**L11037**
```typescript
          deleted_at?: string | null
```

**L11038**
```typescript
          department?: string | null
```

**L11039**
```typescript
          ended_at?: string | null
```

**L11040**
```typescript
          firm_party_id: string
```

**L11041**
```typescript
          id?: string
```

**L11042**
```typescript
          module_data?: Json | null
```

**L11043**
```typescript
          notes?: string | null
```

**L11044**
```typescript
          role_category?: string | null
```

**L11045**
```typescript
          seniority_level?: string | null
```

**L11046**
```typescript
          started_at?: string | null
```

**L11047**
```typescript
          title_text?: string | null
```

**L11048**
```typescript
          updated_at?: string | null
```

**L11049**
```typescript
          updated_by?: string | null
```

**L11050**
```typescript
        }
```

**L11051**
```typescript
        Update: {
```

**L11052**
```typescript
          contact_id?: string
```

**L11053**
```typescript
          created_at?: string | null
```

**L11054**
```typescript
          created_by?: string | null
```

**L11055**
```typescript
          deleted_at?: string | null
```

**L11056**
```typescript
          department?: string | null
```

**L11057**
```typescript
          ended_at?: string | null
```

**L11058**
```typescript
          firm_party_id?: string
```

**L11059**
```typescript
          id?: string
```

**L11060**
```typescript
          module_data?: Json | null
```

**L11061**
```typescript
          notes?: string | null
```

**L11062**
```typescript
          role_category?: string | null
```

**L11063**
```typescript
          seniority_level?: string | null
```

**L11064**
```typescript
          started_at?: string | null
```

**L11065**
```typescript
          title_text?: string | null
```

**L11066**
```typescript
          updated_at?: string | null
```

**L11067**
```typescript
          updated_by?: string | null
```

**L11068**
```typescript
        }
```

**L11069**
```typescript
        Relationships: [
```

**L11070**
```typescript
          {
```

**L11071**
```typescript
            foreignKeyName: "contacts_history_contact_id_fkey"
```

**L11072**
```typescript
            columns: ["contact_id"]
```

**L11073**
```typescript
            isOneToOne: false
```

**L11074**
```typescript
            referencedRelation: "contacts"
```

**L11075**
```typescript
            referencedColumns: ["id"]
```

**L11076**
```typescript
          },
```

**L11077**
```typescript
          {
```

**L11078**
```typescript
            foreignKeyName: "contacts_history_firm_party_id_fkey"
```

**L11079**
```typescript
            columns: ["firm_party_id"]
```

**L11080**
```typescript
            isOneToOne: false
```

**L11081**
```typescript
            referencedRelation: "parties"
```

**L11082**
```typescript
            referencedColumns: ["id"]
```

**L11083**
```typescript
          },
```

**L11084**
```typescript
        ]
```

**L11085**
```typescript
      }
```

**L11086**
```typescript
      deal_checklists: {
```

**L11087**
```typescript
        Row: {
```

**L11088**
```typescript
          completed_at: string | null
```

**L11089**
```typescript
          completed_by: string | null
```

**L11090**
```typescript
          created_at: string | null
```

**L11091**
```typescript
          created_by: string | null
```

**L11092**
```typescript
          deal_id: string
```

**L11093**
```typescript
          deleted_at: string | null
```

**L11094**
```typescript
          id: string
```

**L11095**
```typescript
          is_complete: boolean | null
```

**L11096**
```typescript
          module_data: Json | null
```

**L11097**
```typescript
          notes: string | null
```

**L11098**
```typescript
          sort_order: number | null
```

**L11099**
```typescript
          title: string
```

**L11100**
```typescript
          updated_at: string | null
```

**L11101**
```typescript
          updated_by: string | null
```

**L11102**
```typescript
        }
```

**L11103**
```typescript
        Insert: {
```

**L11104**
```typescript
          completed_at?: string | null
```

**L11105**
```typescript
          completed_by?: string | null
```

**L11106**
```typescript
          created_at?: string | null
```

**L11107**
```typescript
          created_by?: string | null
```

**L11108**
```typescript
          deal_id: string
```

**L11109**
```typescript
          deleted_at?: string | null
```

**L11110**
```typescript
          id?: string
```

**L11111**
```typescript
          is_complete?: boolean | null
```

**L11112**
```typescript
          module_data?: Json | null
```

**L11113**
```typescript
          notes?: string | null
```

**L11114**
```typescript
          sort_order?: number | null
```

**L11115**
```typescript
          title: string
```

**L11116**
```typescript
          updated_at?: string | null
```

**L11117**
```typescript
          updated_by?: string | null
```

**L11118**
```typescript
        }
```

**L11119**
```typescript
        Update: {
```

**L11120**
```typescript
          completed_at?: string | null
```

**L11121**
```typescript
          completed_by?: string | null
```

**L11122**
```typescript
          created_at?: string | null
```

**L11123**
```typescript
          created_by?: string | null
```

**L11124**
```typescript
          deal_id?: string
```

**L11125**
```typescript
          deleted_at?: string | null
```

**L11126**
```typescript
          id?: string
```

**L11127**
```typescript
          is_complete?: boolean | null
```

**L11128**
```typescript
          module_data?: Json | null
```

**L11129**
```typescript
          notes?: string | null
```

**L11130**
```typescript
          sort_order?: number | null
```

**L11131**
```typescript
          title?: string
```

**L11132**
```typescript
          updated_at?: string | null
```

**L11133**
```typescript
          updated_by?: string | null
```

**L11134**
```typescript
        }
```

**L11135**
```typescript
        Relationships: [
```

**L11136**
```typescript
          {
```

**L11137**
```typescript
            foreignKeyName: "deal_checklists_deal_id_fkey"
```

**L11138**
```typescript
            columns: ["deal_id"]
```

**L11139**
```typescript
            isOneToOne: false
```

**L11140**
```typescript
            referencedRelation: "deals"
```

**L11141**
```typescript
            referencedColumns: ["id"]
```

**L11142**
```typescript
          },
```

**L11143**
```typescript
        ]
```

**L11144**
```typescript
      }
```

**L11145**
```typescript
      deal_stage_history: {
```

**L11146**
```typescript
        Row: {
```

**L11147**
```typescript
          changed_at: string
```

**L11148**
```typescript
          changed_by: string | null
```

**L11149**
```typescript
          created_at: string | null
```

**L11150**
```typescript
          deal_id: string
```

**L11151**
```typescript
          from_stage_id: string | null
```

**L11152**
```typescript
          id: string
```

**L11153**
```typescript
          module_data: Json | null
```

**L11154**
```typescript
          notes: string | null
```

**L11155**
```typescript
          to_stage_id: string
```

**L11156**
```typescript
        }
```

**L11157**
```typescript
        Insert: {
```

**L11158**
```typescript
          changed_at?: string
```

**L11159**
```typescript
          changed_by?: string | null
```

**L11160**
```typescript
          created_at?: string | null
```

**L11161**
```typescript
          deal_id: string
```

**L11162**
```typescript
          from_stage_id?: string | null
```

**L11163**
```typescript
          id?: string
```

**L11164**
```typescript
          module_data?: Json | null
```

**L11165**
```typescript
          notes?: string | null
```

**L11166**
```typescript
          to_stage_id: string
```

**L11167**
```typescript
        }
```

**L11168**
```typescript
        Update: {
```

**L11169**
```typescript
          changed_at?: string
```

**L11170**
```typescript
          changed_by?: string | null
```

**L11171**
```typescript
          created_at?: string | null
```

**L11172**
```typescript
          deal_id?: string
```

**L11173**
```typescript
          from_stage_id?: string | null
```

**L11174**
```typescript
          id?: string
```

**L11175**
```typescript
          module_data?: Json | null
```

**L11176**
```typescript
          notes?: string | null
```

**L11177**
```typescript
          to_stage_id?: string
```

**L11178**
```typescript
        }
```

**L11179**
```typescript
        Relationships: [
```

**L11180**
```typescript
          {
```

**L11181**
```typescript
            foreignKeyName: "deal_stage_history_deal_id_fkey"
```

**L11182**
```typescript
            columns: ["deal_id"]
```

**L11183**
```typescript
            isOneToOne: false
```

**L11184**
```typescript
            referencedRelation: "deals"
```

**L11185**
```typescript
            referencedColumns: ["id"]
```

**L11186**
```typescript
          },
```

**L11187**
```typescript
          {
```

**L11188**
```typescript
            foreignKeyName: "deal_stage_history_from_stage_id_fkey"
```

**L11189**
```typescript
            columns: ["from_stage_id"]
```

**L11190**
```typescript
            isOneToOne: false
```

**L11191**
```typescript
            referencedRelation: "stages"
```

**L11192**
```typescript
            referencedColumns: ["id"]
```

**L11193**
```typescript
          },
```

**L11194**
```typescript
          {
```

**L11195**
```typescript
            foreignKeyName: "deal_stage_history_to_stage_id_fkey"
```

**L11196**
```typescript
            columns: ["to_stage_id"]
```

**L11197**
```typescript
            isOneToOne: false
```

**L11198**
```typescript
            referencedRelation: "stages"
```

**L11199**
```typescript
            referencedColumns: ["id"]
```

**L11200**
```typescript
          },
```

**L11201**
```typescript
        ]
```

**L11202**
```typescript
      }
```

**L11203**
```typescript
      deals: {
```

**L11204**
```typescript
        Row: {
```

**L11205**
```typescript
          actual_close_date: string | null
```

**L11206**
```typescript
          created_at: string
```

**L11207**
```typescript
          created_by: string | null
```

**L11208**
```typescript
          current_stage_id: string
```

**L11209**
```typescript
          deal_name: string
```

**L11210**
```typescript
          deleted_at: string | null
```

**L11211**
```typescript
          description: string | null
```

**L11212**
```typescript
          expected_close_date: string | null
```

**L11213**
```typescript
          id: string
```

**L11214**
```typescript
          last_activity_at: string | null
```

**L11215**
```typescript
          module_data: Json
```

**L11216**
```typescript
          notes: string | null
```

**L11217**
```typescript
          owner_user_id: string | null
```

**L11218**
```typescript
          party_id: string
```

**L11219**
```typescript
          pipeline_id: string
```

**L11220**
```typescript
          primary_contact_id: string | null
```

**L11221**
```typescript
          priority: string
```

**L11222**
```typescript
          probability_pct: number | null
```

**L11223**
```typescript
          source: string | null
```

**L11224**
```typescript
          source_external_id: string | null
```

**L11225**
```typescript
          status: string
```

**L11226**
```typescript
          updated_at: string
```

**L11227**
```typescript
          updated_by: string | null
```

**L11228**
```typescript
          value_amount: number | null
```

**L11229**
```typescript
          value_currency: string
```

**L11230**
```typescript
          won_lost_reason: string | null
```

**L11231**
```typescript
        }
```

**L11232**
```typescript
        Insert: {
```

**L11233**
```typescript
          actual_close_date?: string | null
```

**L11234**
```typescript
          created_at?: string
```

**L11235**
```typescript
          created_by?: string | null
```

**L11236**
```typescript
          current_stage_id: string
```

**L11237**
```typescript
          deal_name: string
```

**L11238**
```typescript
          deleted_at?: string | null
```

**L11239**
```typescript
          description?: string | null
```

**L11240**
```typescript
          expected_close_date?: string | null
```

**L11241**
```typescript
          id?: string
```

**L11242**
```typescript
          last_activity_at?: string | null
```

**L11243**
```typescript
          module_data?: Json
```

**L11244**
```typescript
          notes?: string | null
```

**L11245**
```typescript
          owner_user_id?: string | null
```

**L11246**
```typescript
          party_id: string
```

**L11247**
```typescript
          pipeline_id: string
```

**L11248**
```typescript
          primary_contact_id?: string | null
```

**L11249**
```typescript
          priority?: string
```

**L11250**
```typescript
          probability_pct?: number | null
```

**L11251**
```typescript
          source?: string | null
```

**L11252**
```typescript
          source_external_id?: string | null
```

**L11253**
```typescript
          status?: string
```

**L11254**
```typescript
          updated_at?: string
```

**L11255**
```typescript
          updated_by?: string | null
```

**L11256**
```typescript
          value_amount?: number | null
```

**L11257**
```typescript
          value_currency?: string
```

**L11258**
```typescript
          won_lost_reason?: string | null
```

**L11259**
```typescript
        }
```

**L11260**
```typescript
        Update: {
```

**L11261**
```typescript
          actual_close_date?: string | null
```

**L11262**
```typescript
          created_at?: string
```

**L11263**
```typescript
          created_by?: string | null
```

**L11264**
```typescript
          current_stage_id?: string
```

**L11265**
```typescript
          deal_name?: string
```

**L11266**
```typescript
          deleted_at?: string | null
```

**L11267**
```typescript
          description?: string | null
```

**L11268**
```typescript
          expected_close_date?: string | null
```

**L11269**
```typescript
          id?: string
```

**L11270**
```typescript
          last_activity_at?: string | null
```

**L11271**
```typescript
          module_data?: Json
```

**L11272**
```typescript
          notes?: string | null
```

**L11273**
```typescript
          owner_user_id?: string | null
```

**L11274**
```typescript
          party_id?: string
```

**L11275**
```typescript
          pipeline_id?: string
```

**L11276**
```typescript
          primary_contact_id?: string | null
```

**L11277**
```typescript
          priority?: string
```

**L11278**
```typescript
          probability_pct?: number | null
```

**L11279**
```typescript
          source?: string | null
```

**L11280**
```typescript
          source_external_id?: string | null
```

**L11281**
```typescript
          status?: string
```

**L11282**
```typescript
          updated_at?: string
```

**L11283**
```typescript
          updated_by?: string | null
```

**L11284**
```typescript
          value_amount?: number | null
```

**L11285**
```typescript
          value_currency?: string
```

**L11286**
```typescript
          won_lost_reason?: string | null
```

**L11287**
```typescript
        }
```

**L11288**
```typescript
        Relationships: [
```

**L11289**
```typescript
          {
```

**L11290**
```typescript
            foreignKeyName: "deals_current_stage_id_fkey"
```

**L11291**
```typescript
            columns: ["current_stage_id"]
```

**L11292**
```typescript
            isOneToOne: false
```

**L11293**
```typescript
            referencedRelation: "stages"
```

**L11294**
```typescript
            referencedColumns: ["id"]
```

**L11295**
```typescript
          },
```

**L11296**
```typescript
          {
```

**L11297**
```typescript
            foreignKeyName: "deals_party_id_fkey"
```

**L11298**
```typescript
            columns: ["party_id"]
```

**L11299**
```typescript
            isOneToOne: false
```

**L11300**
```typescript
            referencedRelation: "parties"
```

**L11301**
```typescript
            referencedColumns: ["id"]
```

**L11302**
```typescript
          },
```

**L11303**
```typescript
          {
```

**L11304**
```typescript
            foreignKeyName: "deals_pipeline_id_fkey"
```

**L11305**
```typescript
            columns: ["pipeline_id"]
```

**L11306**
```typescript
            isOneToOne: false
```

**L11307**
```typescript
            referencedRelation: "pipelines"
```

**L11308**
```typescript
            referencedColumns: ["id"]
```

**L11309**
```typescript
          },
```

**L11310**
```typescript
        ]
```

**L11311**
```typescript
      }
```

**L11312**
```typescript
      engagement_attendees: {
```

**L11313**
```typescript
        Row: {
```

**L11314**
```typescript
          attended: boolean | null
```

**L11315**
```typescript
          contact_id: string
```

**L11316**
```typescript
          created_at: string
```

**L11317**
```typescript
          engagement_id: string
```

**L11318**
```typescript
          id: string
```

**L11319**
```typescript
          notes: string | null
```

**L11320**
```typescript
          response: string | null
```

**L11321**
```typescript
          role: string
```

**L11322**
```typescript
          updated_at: string
```

**L11323**
```typescript
        }
```

**L11324**
```typescript
        Insert: {
```

**L11325**
```typescript
          attended?: boolean | null
```

**L11326**
```typescript
          contact_id: string
```

**L11327**
```typescript
          created_at?: string
```

**L11328**
```typescript
          engagement_id: string
```

**L11329**
```typescript
          id?: string
```

**L11330**
```typescript
          notes?: string | null
```

**L11331**
```typescript
          response?: string | null
```

**L11332**
```typescript
          role?: string
```

**L11333**
```typescript
          updated_at?: string
```

**L11334**
```typescript
        }
```

**L11335**
```typescript
        Update: {
```

**L11336**
```typescript
          attended?: boolean | null
```

**L11337**
```typescript
          contact_id?: string
```

**L11338**
```typescript
          created_at?: string
```

**L11339**
```typescript
          engagement_id?: string
```

**L11340**
```typescript
          id?: string
```

**L11341**
```typescript
          notes?: string | null
```

**L11342**
```typescript
          response?: string | null
```

**L11343**
```typescript
          role?: string
```

**L11344**
```typescript
          updated_at?: string
```

**L11345**
```typescript
        }
```

**L11346**
```typescript
        Relationships: [
```

**L11347**
```typescript
          {
```

**L11348**
```typescript
            foreignKeyName: "engagement_attendees_engagement_id_fkey"
```

**L11349**
```typescript
            columns: ["engagement_id"]
```

**L11350**
```typescript
            isOneToOne: false
```

**L11351**
```typescript
            referencedRelation: "engagements"
```

**L11352**
```typescript
            referencedColumns: ["id"]
```

**L11353**
```typescript
          },
```

**L11354**
```typescript
        ]
```

**L11355**
```typescript
      }
```

**L11356**
```typescript
      engagement_documents: {
```

**L11357**
```typescript
        Row: {
```

**L11358**
```typescript
          created_at: string
```

**L11359**
```typescript
          deleted_at: string | null
```

**L11360**
```typescript
          description: string | null
```

**L11361**
```typescript
          document_kind: string | null
```

**L11362**
```typescript
          engagement_id: string
```

**L11363**
```typescript
          file_name: string
```

**L11364**
```typescript
          file_size_bytes: number | null
```

**L11365**
```typescript
          id: string
```

**L11366**
```typescript
          mime_type: string | null
```

**L11367**
```typescript
          storage_path: string
```

**L11368**
```typescript
          storage_provider: string | null
```

**L11369**
```typescript
          updated_at: string
```

**L11370**
```typescript
          uploaded_at: string
```

**L11371**
```typescript
          uploaded_by_user_id: string | null
```

**L11372**
```typescript
        }
```

**L11373**
```typescript
        Insert: {
```

**L11374**
```typescript
          created_at?: string
```

**L11375**
```typescript
          deleted_at?: string | null
```

**L11376**
```typescript
          description?: string | null
```

**L11377**
```typescript
          document_kind?: string | null
```

**L11378**
```typescript
          engagement_id: string
```

**L11379**
```typescript
          file_name: string
```

**L11380**
```typescript
          file_size_bytes?: number | null
```

**L11381**
```typescript
          id?: string
```

**L11382**
```typescript
          mime_type?: string | null
```

**L11383**
```typescript
          storage_path: string
```

**L11384**
```typescript
          storage_provider?: string | null
```

**L11385**
```typescript
          updated_at?: string
```

**L11386**
```typescript
          uploaded_at?: string
```

**L11387**
```typescript
          uploaded_by_user_id?: string | null
```

**L11388**
```typescript
        }
```

**L11389**
```typescript
        Update: {
```

**L11390**
```typescript
          created_at?: string
```

**L11391**
```typescript
          deleted_at?: string | null
```

**L11392**
```typescript
          description?: string | null
```

**L11393**
```typescript
          document_kind?: string | null
```

**L11394**
```typescript
          engagement_id?: string
```

**L11395**
```typescript
          file_name?: string
```

**L11396**
```typescript
          file_size_bytes?: number | null
```

**L11397**
```typescript
          id?: string
```

**L11398**
```typescript
          mime_type?: string | null
```

**L11399**
```typescript
          storage_path?: string
```

**L11400**
```typescript
          storage_provider?: string | null
```

**L11401**
```typescript
          updated_at?: string
```

**L11402**
```typescript
          uploaded_at?: string
```

**L11403**
```typescript
          uploaded_by_user_id?: string | null
```

**L11404**
```typescript
        }
```

**L11405**
```typescript
        Relationships: [
```

**L11406**
```typescript
          {
```

**L11407**
```typescript
            foreignKeyName: "engagement_documents_engagement_id_fkey"
```

**L11408**
```typescript
            columns: ["engagement_id"]
```

**L11409**
```typescript
            isOneToOne: false
```

**L11410**
```typescript
            referencedRelation: "engagements"
```

**L11411**
```typescript
            referencedColumns: ["id"]
```

**L11412**
```typescript
          },
```

**L11413**
```typescript
        ]
```

**L11414**
```typescript
      }
```

**L11415**
```typescript
      engagement_email_details: {
```

**L11416**
```typescript
        Row: {
```

**L11417**
```typescript
          bcc_addresses: string[]
```

**L11418**
```typescript
          body_html: string | null
```

**L11419**
```typescript
          cc_addresses: string[]
```

**L11420**
```typescript
          created_at: string
```

**L11421**
```typescript
          engagement_id: string
```

**L11422**
```typescript
          from_address: string
```

**L11423**
```typescript
          has_attachments: boolean
```

**L11424**
```typescript
          in_reply_to: string | null
```

**L11425**
```typescript
          message_id: string | null
```

**L11426**
```typescript
          spam_score: number | null
```

**L11427**
```typescript
          subject: string
```

**L11428**
```typescript
          thread_id: string | null
```

**L11429**
```typescript
          to_addresses: string[]
```

**L11430**
```typescript
          updated_at: string
```

**L11431**
```typescript
        }
```

**L11432**
```typescript
        Insert: {
```

**L11433**
```typescript
          bcc_addresses?: string[]
```

**L11434**
```typescript
          body_html?: string | null
```

**L11435**
```typescript
          cc_addresses?: string[]
```

**L11436**
```typescript
          created_at?: string
```

**L11437**
```typescript
          engagement_id: string
```

**L11438**
```typescript
          from_address: string
```

**L11439**
```typescript
          has_attachments?: boolean
```

**L11440**
```typescript
          in_reply_to?: string | null
```

**L11441**
```typescript
          message_id?: string | null
```

**L11442**
```typescript
          spam_score?: number | null
```

**L11443**
```typescript
          subject: string
```

**L11444**
```typescript
          thread_id?: string | null
```

**L11445**
```typescript
          to_addresses?: string[]
```

**L11446**
```typescript
          updated_at?: string
```

**L11447**
```typescript
        }
```

**L11448**
```typescript
        Update: {
```

**L11449**
```typescript
          bcc_addresses?: string[]
```

**L11450**
```typescript
          body_html?: string | null
```

**L11451**
```typescript
          cc_addresses?: string[]
```

**L11452**
```typescript
          created_at?: string
```

**L11453**
```typescript
          engagement_id?: string
```

**L11454**
```typescript
          from_address?: string
```

**L11455**
```typescript
          has_attachments?: boolean
```

**L11456**
```typescript
          in_reply_to?: string | null
```

**L11457**
```typescript
          message_id?: string | null
```

**L11458**
```typescript
          spam_score?: number | null
```

**L11459**
```typescript
          subject?: string
```

**L11460**
```typescript
          thread_id?: string | null
```

**L11461**
```typescript
          to_addresses?: string[]
```

**L11462**
```typescript
          updated_at?: string
```

**L11463**
```typescript
        }
```

**L11464**
```typescript
        Relationships: [
```

**L11465**
```typescript
          {
```

**L11466**
```typescript
            foreignKeyName: "engagement_email_details_engagement_id_fkey"
```

**L11467**
```typescript
            columns: ["engagement_id"]
```

**L11468**
```typescript
            isOneToOne: true
```

**L11469**
```typescript
            referencedRelation: "engagements"
```

**L11470**
```typescript
            referencedColumns: ["id"]
```

**L11471**
```typescript
          },
```

**L11472**
```typescript
        ]
```

**L11473**
```typescript
      }
```

**L11474**
```typescript
      engagement_meeting_details: {
```

**L11475**
```typescript
        Row: {
```

**L11476**
```typescript
          actual_ended_at: string | null
```

**L11477**
```typescript
          actual_started_at: string | null
```

**L11478**
```typescript
          agenda: string | null
```

**L11479**
```typescript
          created_at: string
```

**L11480**
```typescript
          engagement_id: string
```

**L11481**
```typescript
          external_calendar_id: string | null
```

**L11482**
```typescript
          location: string | null
```

**L11483**
```typescript
          meeting_kind: string | null
```

**L11484**
```typescript
          meeting_platform: string | null
```

**L11485**
```typescript
          recording_url: string | null
```

**L11486**
```typescript
          scheduled_end_at: string | null
```

**L11487**
```typescript
          scheduled_start_at: string | null
```

**L11488**
```typescript
          transcript_url: string | null
```

**L11489**
```typescript
          updated_at: string
```

**L11490**
```typescript
          virtual_url: string | null
```

**L11491**
```typescript
        }
```

**L11492**
```typescript
        Insert: {
```

**L11493**
```typescript
          actual_ended_at?: string | null
```

**L11494**
```typescript
          actual_started_at?: string | null
```

**L11495**
```typescript
          agenda?: string | null
```

**L11496**
```typescript
          created_at?: string
```

**L11497**
```typescript
          engagement_id: string
```

**L11498**
```typescript
          external_calendar_id?: string | null
```

**L11499**
```typescript
          location?: string | null
```

**L11500**
```typescript
          meeting_kind?: string | null
```

**L11501**
```typescript
          meeting_platform?: string | null
```

**L11502**
```typescript
          recording_url?: string | null
```

**L11503**
```typescript
          scheduled_end_at?: string | null
```

**L11504**
```typescript
          scheduled_start_at?: string | null
```

**L11505**
```typescript
          transcript_url?: string | null
```

**L11506**
```typescript
          updated_at?: string
```

**L11507**
```typescript
          virtual_url?: string | null
```

**L11508**
```typescript
        }
```

**L11509**
```typescript
        Update: {
```

**L11510**
```typescript
          actual_ended_at?: string | null
```

**L11511**
```typescript
          actual_started_at?: string | null
```

**L11512**
```typescript
          agenda?: string | null
```

**L11513**
```typescript
          created_at?: string
```

**L11514**
```typescript
          engagement_id?: string
```

**L11515**
```typescript
          external_calendar_id?: string | null
```

**L11516**
```typescript
          location?: string | null
```

**L11517**
```typescript
          meeting_kind?: string | null
```

**L11518**
```typescript
          meeting_platform?: string | null
```

**L11519**
```typescript
          recording_url?: string | null
```

**L11520**
```typescript
          scheduled_end_at?: string | null
```

**L11521**
```typescript
          scheduled_start_at?: string | null
```

**L11522**
```typescript
          transcript_url?: string | null
```

**L11523**
```typescript
          updated_at?: string
```

**L11524**
```typescript
          virtual_url?: string | null
```

**L11525**
```typescript
        }
```

**L11526**
```typescript
        Relationships: [
```

**L11527**
```typescript
          {
```

**L11528**
```typescript
            foreignKeyName: "engagement_meeting_details_engagement_id_fkey"
```

**L11529**
```typescript
            columns: ["engagement_id"]
```

**L11530**
```typescript
            isOneToOne: true
```

**L11531**
```typescript
            referencedRelation: "engagements"
```

**L11532**
```typescript
            referencedColumns: ["id"]
```

**L11533**
```typescript
          },
```

**L11534**
```typescript
        ]
```

**L11535**
```typescript
      }
```

**L11536**
```typescript
      engagement_types: {
```

**L11537**
```typescript
        Row: {
```

**L11538**
```typescript
          code: string
```

**L11539**
```typescript
          created_at: string
```

**L11540**
```typescript
          description: string | null
```

**L11541**
```typescript
          display_name_en: string
```

**L11542**
```typescript
          display_name_ja: string | null
```

**L11543**
```typescript
          display_name_ko: string
```

**L11544**
```typescript
          id: number
```

**L11545**
```typescript
          is_active: boolean
```

**L11546**
```typescript
          sort_order: number
```

**L11547**
```typescript
          updated_at: string
```

**L11548**
```typescript
        }
```

**L11549**
```typescript
        Insert: {
```

**L11550**
```typescript
          code: string
```

**L11551**
```typescript
          created_at?: string
```

**L11552**
```typescript
          description?: string | null
```

**L11553**
```typescript
          display_name_en: string
```

**L11554**
```typescript
          display_name_ja?: string | null
```

**L11555**
```typescript
          display_name_ko: string
```

**L11556**
```typescript
          id: number
```

**L11557**
```typescript
          is_active?: boolean
```

**L11558**
```typescript
          sort_order?: number
```

**L11559**
```typescript
          updated_at?: string
```

**L11560**
```typescript
        }
```

**L11561**
```typescript
        Update: {
```

**L11562**
```typescript
          code?: string
```

**L11563**
```typescript
          created_at?: string
```

**L11564**
```typescript
          description?: string | null
```

**L11565**
```typescript
          display_name_en?: string
```

**L11566**
```typescript
          display_name_ja?: string | null
```

**L11567**
```typescript
          display_name_ko?: string
```

**L11568**
```typescript
          id?: number
```

**L11569**
```typescript
          is_active?: boolean
```

**L11570**
```typescript
          sort_order?: number
```

**L11571**
```typescript
          updated_at?: string
```

**L11572**
```typescript
        }
```

**L11573**
```typescript
        Relationships: []
```

**L11574**
```typescript
      }
```

**L11575**
```typescript
      engagements: {
```

**L11576**
```typescript
        Row: {
```

**L11577**
```typescript
          channel: string | null
```

**L11578**
```typescript
          content: string | null
```

**L11579**
```typescript
          created_at: string
```

**L11580**
```typescript
          created_by: string | null
```

**L11581**
```typescript
          deal_id: string | null
```

**L11582**
```typescript
          deleted_at: string | null
```

**L11583**
```typescript
          direction: string | null
```

**L11584**
```typescript
          duration_min: number | null
```

**L11585**
```typescript
          engagement_type_id: number
```

**L11586**
```typescript
          id: string
```

**L11587**
```typescript
          module_data: Json
```

**L11588**
```typescript
          next_steps: string | null
```

**L11589**
```typescript
          notes: string | null
```

**L11590**
```typescript
          occurred_at: string
```

**L11591**
```typescript
          outcome: string | null
```

**L11592**
```typescript
          party_id: string | null
```

**L11593**
```typescript
          recorded_by_user_id: string | null
```

**L11594**
```typescript
          sentiment: string | null
```

**L11595**
```typescript
          status: string
```

**L11596**
```typescript
          summary: string | null
```

**L11597**
```typescript
          task_id: string | null
```

**L11598**
```typescript
          title: string
```

**L11599**
```typescript
          updated_at: string
```

**L11600**
```typescript
          updated_by: string | null
```

**L11601**
```typescript
        }
```

**L11602**
```typescript
        Insert: {
```

**L11603**
```typescript
          channel?: string | null
```

**L11604**
```typescript
          content?: string | null
```

**L11605**
```typescript
          created_at?: string
```

**L11606**
```typescript
          created_by?: string | null
```

**L11607**
```typescript
          deal_id?: string | null
```

**L11608**
```typescript
          deleted_at?: string | null
```

**L11609**
```typescript
          direction?: string | null
```

**L11610**
```typescript
          duration_min?: number | null
```

**L11611**
```typescript
          engagement_type_id: number
```

**L11612**
```typescript
          id?: string
```

**L11613**
```typescript
          module_data?: Json
```

**L11614**
```typescript
          next_steps?: string | null
```

**L11615**
```typescript
          notes?: string | null
```

**L11616**
```typescript
          occurred_at: string
```

**L11617**
```typescript
          outcome?: string | null
```

**L11618**
```typescript
          party_id?: string | null
```

**L11619**
```typescript
          recorded_by_user_id?: string | null
```

**L11620**
```typescript
          sentiment?: string | null
```

**L11621**
```typescript
          status?: string
```

**L11622**
```typescript
          summary?: string | null
```

**L11623**
```typescript
          task_id?: string | null
```

**L11624**
```typescript
          title: string
```

**L11625**
```typescript
          updated_at?: string
```

**L11626**
```typescript
          updated_by?: string | null
```

**L11627**
```typescript
        }
```

**L11628**
```typescript
        Update: {
```

**L11629**
```typescript
          channel?: string | null
```

**L11630**
```typescript
          content?: string | null
```

**L11631**
```typescript
          created_at?: string
```

**L11632**
```typescript
          created_by?: string | null
```

**L11633**
```typescript
          deal_id?: string | null
```

**L11634**
```typescript
          deleted_at?: string | null
```

**L11635**
```typescript
          direction?: string | null
```

**L11636**
```typescript
          duration_min?: number | null
```

**L11637**
```typescript
          engagement_type_id?: number
```

**L11638**
```typescript
          id?: string
```

**L11639**
```typescript
          module_data?: Json
```

**L11640**
```typescript
          next_steps?: string | null
```

**L11641**
```typescript
          notes?: string | null
```

**L11642**
```typescript
          occurred_at?: string
```

**L11643**
```typescript
          outcome?: string | null
```

**L11644**
```typescript
          party_id?: string | null
```

**L11645**
```typescript
          recorded_by_user_id?: string | null
```

**L11646**
```typescript
          sentiment?: string | null
```

**L11647**
```typescript
          status?: string
```

**L11648**
```typescript
          summary?: string | null
```

**L11649**
```typescript
          task_id?: string | null
```

**L11650**
```typescript
          title?: string
```

**L11651**
```typescript
          updated_at?: string
```

**L11652**
```typescript
          updated_by?: string | null
```

**L11653**
```typescript
        }
```

**L11654**
```typescript
        Relationships: [
```

**L11655**
```typescript
          {
```

**L11656**
```typescript
            foreignKeyName: "engagements_deal_id_fkey"
```

**L11657**
```typescript
            columns: ["deal_id"]
```

**L11658**
```typescript
            isOneToOne: false
```

**L11659**
```typescript
            referencedRelation: "deals"
```

**L11660**
```typescript
            referencedColumns: ["id"]
```

**L11661**
```typescript
          },
```

**L11662**
```typescript
          {
```

**L11663**
```typescript
            foreignKeyName: "engagements_engagement_type_id_fkey"
```

**L11664**
```typescript
            columns: ["engagement_type_id"]
```

**L11665**
```typescript
            isOneToOne: false
```

**L11666**
```typescript
            referencedRelation: "engagement_types"
```

**L11667**
```typescript
            referencedColumns: ["id"]
```

**L11668**
```typescript
          },
```

**L11669**
```typescript
          {
```

**L11670**
```typescript
            foreignKeyName: "engagements_party_id_fkey"
```

**L11671**
```typescript
            columns: ["party_id"]
```

**L11672**
```typescript
            isOneToOne: false
```

**L11673**
```typescript
            referencedRelation: "parties"
```

**L11674**
```typescript
            referencedColumns: ["id"]
```

**L11675**
```typescript
          },
```

**L11676**
```typescript
          {
```

**L11677**
```typescript
            foreignKeyName: "engagements_task_id_fkey"
```

**L11678**
```typescript
            columns: ["task_id"]
```

**L11679**
```typescript
            isOneToOne: false
```

**L11680**
```typescript
            referencedRelation: "tasks"
```

**L11681**
```typescript
            referencedColumns: ["id"]
```

**L11682**
```typescript
          },
```

**L11683**
```typescript
        ]
```

**L11684**
```typescript
      }
```

**L11685**
```typescript
      entity_types: {
```

**L11686**
```typescript
        Row: {
```

**L11687**
```typescript
          code: string
```

**L11688**
```typescript
          created_at: string
```

**L11689**
```typescript
          description: string | null
```

**L11690**
```typescript
          display_name_en: string
```

**L11691**
```typescript
          display_name_ja: string | null
```

**L11692**
```typescript
          display_name_ko: string
```

**L11693**
```typescript
          id: number
```

**L11694**
```typescript
          is_active: boolean
```

**L11695**
```typescript
          sort_order: number
```

**L11696**
```typescript
          updated_at: string
```

**L11697**
```typescript
        }
```

**L11698**
```typescript
        Insert: {
```

**L11699**
```typescript
          code: string
```

**L11700**
```typescript
          created_at?: string
```

**L11701**
```typescript
          description?: string | null
```

**L11702**
```typescript
          display_name_en: string
```

**L11703**
```typescript
          display_name_ja?: string | null
```

**L11704**
```typescript
          display_name_ko: string
```

**L11705**
```typescript
          id: number
```

**L11706**
```typescript
          is_active?: boolean
```

**L11707**
```typescript
          sort_order?: number
```

**L11708**
```typescript
          updated_at?: string
```

**L11709**
```typescript
        }
```

**L11710**
```typescript
        Update: {
```

**L11711**
```typescript
          code?: string
```

**L11712**
```typescript
          created_at?: string
```

**L11713**
```typescript
          description?: string | null
```

**L11714**
```typescript
          display_name_en?: string
```

**L11715**
```typescript
          display_name_ja?: string | null
```

**L11716**
```typescript
          display_name_ko?: string
```

**L11717**
```typescript
          id?: number
```

**L11718**
```typescript
          is_active?: boolean
```

**L11719**
```typescript
          sort_order?: number
```

**L11720**
```typescript
          updated_at?: string
```

**L11721**
```typescript
        }
```

**L11722**
```typescript
        Relationships: []
```

**L11723**
```typescript
      }
```

**L11724**
```typescript
      filler_supplier_profile: {
```

**L11725**
```typescript
        Row: {
```

**L11726**
```typescript
          auto_promoted_at: string | null
```

**L11727**
```typescript
          created_at: string
```

**L11728**
```typescript
          created_by: string | null
```

**L11729**
```typescript
          deleted_at: string | null
```

**L11730**
```typescript
          evidence_level: string | null
```

**L11731**
```typescript
          id: string
```

**L11732**
```typescript
          industry_source: string
```

**L11733**
```typescript
          market_role: string | null
```

**L11734**
```typescript
          module_data: Json
```

**L11735**
```typescript
          notes: string | null
```

**L11736**
```typescript
          onsite_pcc_evidence: string | null
```

**L11737**
```typescript
          party_id: string
```

**L11738**
```typescript
          supplier_type: string | null
```

**L11739**
```typescript
          supply_model: string | null
```

**L11740**
```typescript
          updated_at: string
```

**L11741**
```typescript
          updated_by: string | null
```

**L11742**
```typescript
        }
```

**L11743**
```typescript
        Insert: {
```

**L11744**
```typescript
          auto_promoted_at?: string | null
```

**L11745**
```typescript
          created_at?: string
```

**L11746**
```typescript
          created_by?: string | null
```

**L11747**
```typescript
          deleted_at?: string | null
```

**L11748**
```typescript
          evidence_level?: string | null
```

**L11749**
```typescript
          id?: string
```

**L11750**
```typescript
          industry_source?: string
```

**L11751**
```typescript
          market_role?: string | null
```

**L11752**
```typescript
          module_data?: Json
```

**L11753**
```typescript
          notes?: string | null
```

**L11754**
```typescript
          onsite_pcc_evidence?: string | null
```

**L11755**
```typescript
          party_id: string
```

**L11756**
```typescript
          supplier_type?: string | null
```

**L11757**
```typescript
          supply_model?: string | null
```

**L11758**
```typescript
          updated_at?: string
```

**L11759**
```typescript
          updated_by?: string | null
```

**L11760**
```typescript
        }
```

**L11761**
```typescript
        Update: {
```

**L11762**
```typescript
          auto_promoted_at?: string | null
```

**L11763**
```typescript
          created_at?: string
```

**L11764**
```typescript
          created_by?: string | null
```

**L11765**
```typescript
          deleted_at?: string | null
```

**L11766**
```typescript
          evidence_level?: string | null
```

**L11767**
```typescript
          id?: string
```

**L11768**
```typescript
          industry_source?: string
```

**L11769**
```typescript
          market_role?: string | null
```

**L11770**
```typescript
          module_data?: Json
```

**L11771**
```typescript
          notes?: string | null
```

**L11772**
```typescript
          onsite_pcc_evidence?: string | null
```

**L11773**
```typescript
          party_id?: string
```

**L11774**
```typescript
          supplier_type?: string | null
```

**L11775**
```typescript
          supply_model?: string | null
```

**L11776**
```typescript
          updated_at?: string
```

**L11777**
```typescript
          updated_by?: string | null
```

**L11778**
```typescript
        }
```

**L11779**
```typescript
        Relationships: [
```

**L11780**
```typescript
          {
```

**L11781**
```typescript
            foreignKeyName: "urm_filler_supplier_profile_party_id_fkey"
```

**L11782**
```typescript
            columns: ["party_id"]
```

**L11783**
```typescript
            isOneToOne: true
```

**L11784**
```typescript
            referencedRelation: "parties"
```

**L11785**
```typescript
            referencedColumns: ["id"]
```

**L11786**
```typescript
          },
```

**L11787**
```typescript
        ]
```

**L11788**
```typescript
      }
```

**L11789**
```typescript
      investor_portfolio_companies: {
```

**L11790**
```typescript
        Row: {
```

**L11791**
```typescript
          created_at: string
```

**L11792**
```typescript
          created_by: string | null
```

**L11793**
```typescript
          deleted_at: string | null
```

**L11794**
```typescript
          id: string
```

**L11795**
```typescript
          investment_amount_usd: number | null
```

**L11796**
```typescript
          investment_stage: string | null
```

**L11797**
```typescript
          investment_year: number | null
```

**L11798**
```typescript
          investor_party_id: string
```

**L11799**
```typescript
          is_active: boolean
```

**L11800**
```typescript
          is_lead: boolean
```

**L11801**
```typescript
          module_data: Json
```

**L11802**
```typescript
          notes: string | null
```

**L11803**
```typescript
          portfolio_company_country: string | null
```

**L11804**
```typescript
          portfolio_company_name: string
```

**L11805**
```typescript
          portfolio_company_name_normalized: string | null
```

**L11806**
```typescript
          portfolio_company_website: string | null
```

**L11807**
```typescript
          updated_at: string
```

**L11808**
```typescript
          updated_by: string | null
```

**L11809**
```typescript
        }
```

**L11810**
```typescript
        Insert: {
```

**L11811**
```typescript
          created_at?: string
```

**L11812**
```typescript
          created_by?: string | null
```

**L11813**
```typescript
          deleted_at?: string | null
```

**L11814**
```typescript
          id?: string
```

**L11815**
```typescript
          investment_amount_usd?: number | null
```

**L11816**
```typescript
          investment_stage?: string | null
```

**L11817**
```typescript
          investment_year?: number | null
```

**L11818**
```typescript
          investor_party_id: string
```

**L11819**
```typescript
          is_active?: boolean
```

**L11820**
```typescript
          is_lead?: boolean
```

**L11821**
```typescript
          module_data?: Json
```

**L11822**
```typescript
          notes?: string | null
```

**L11823**
```typescript
          portfolio_company_country?: string | null
```

**L11824**
```typescript
          portfolio_company_name: string
```

**L11825**
```typescript
          portfolio_company_name_normalized?: string | null
```

**L11826**
```typescript
          portfolio_company_website?: string | null
```

**L11827**
```typescript
          updated_at?: string
```

**L11828**
```typescript
          updated_by?: string | null
```

**L11829**
```typescript
        }
```

**L11830**
```typescript
        Update: {
```

**L11831**
```typescript
          created_at?: string
```

**L11832**
```typescript
          created_by?: string | null
```

**L11833**
```typescript
          deleted_at?: string | null
```

**L11834**
```typescript
          id?: string
```

**L11835**
```typescript
          investment_amount_usd?: number | null
```

**L11836**
```typescript
          investment_stage?: string | null
```

**L11837**
```typescript
          investment_year?: number | null
```

**L11838**
```typescript
          investor_party_id?: string
```

**L11839**
```typescript
          is_active?: boolean
```

**L11840**
```typescript
          is_lead?: boolean
```

**L11841**
```typescript
          module_data?: Json
```

**L11842**
```typescript
          notes?: string | null
```

**L11843**
```typescript
          portfolio_company_country?: string | null
```

**L11844**
```typescript
          portfolio_company_name?: string
```

**L11845**
```typescript
          portfolio_company_name_normalized?: string | null
```

**L11846**
```typescript
          portfolio_company_website?: string | null
```

**L11847**
```typescript
          updated_at?: string
```

**L11848**
```typescript
          updated_by?: string | null
```

**L11849**
```typescript
        }
```

**L11850**
```typescript
        Relationships: [
```

**L11851**
```typescript
          {
```

**L11852**
```typescript
            foreignKeyName: "investor_portfolio_companies_investor_party_id_fkey"
```

**L11853**
```typescript
            columns: ["investor_party_id"]
```

**L11854**
```typescript
            isOneToOne: false
```

**L11855**
```typescript
            referencedRelation: "parties"
```

**L11856**
```typescript
            referencedColumns: ["id"]
```

**L11857**
```typescript
          },
```

**L11858**
```typescript
        ]
```

**L11859**
```typescript
      }
```

**L11860**
```typescript
      investor_profile: {
```

**L11861**
```typescript
        Row: {
```

**L11862**
```typescript
          aum_usd: number | null
```

**L11863**
```typescript
          created_at: string
```

**L11864**
```typescript
          created_by: string | null
```

**L11865**
```typescript
          fund_name: string | null
```

**L11866**
```typescript
          fund_size_usd: number | null
```

**L11867**
```typescript
          fund_vintage_year: number | null
```

**L11868**
```typescript
          geographic_focus: string[]
```

**L11869**
```typescript
          id: string
```

**L11870**
```typescript
          investment_stages: string[]
```

**L11871**
```typescript
          is_lead_investor: boolean
```

**L11872**
```typescript
          is_strategic: boolean
```

**L11873**
```typescript
          party_id: string
```

**L11874**
```typescript
          sector_focus: string[]
```

**L11875**
```typescript
          subtype: Database["app"]["Enums"]["investor_subtype"] | null
```

**L11876**
```typescript
          ticket_max_usd: number | null
```

**L11877**
```typescript
          ticket_min_usd: number | null
```

**L11878**
```typescript
          updated_at: string
```

**L11879**
```typescript
          updated_by: string | null
```

**L11880**
```typescript
        }
```

**L11881**
```typescript
        Insert: {
```

**L11882**
```typescript
          aum_usd?: number | null
```

**L11883**
```typescript
          created_at?: string
```

**L11884**
```typescript
          created_by?: string | null
```

**L11885**
```typescript
          fund_name?: string | null
```

**L11886**
```typescript
          fund_size_usd?: number | null
```

**L11887**
```typescript
          fund_vintage_year?: number | null
```

**L11888**
```typescript
          geographic_focus?: string[]
```

**L11889**
```typescript
          id?: string
```

**L11890**
```typescript
          investment_stages?: string[]
```

**L11891**
```typescript
          is_lead_investor?: boolean
```

**L11892**
```typescript
          is_strategic?: boolean
```

**L11893**
```typescript
          party_id: string
```

**L11894**
```typescript
          sector_focus?: string[]
```

**L11895**
```typescript
          subtype?: Database["app"]["Enums"]["investor_subtype"] | null
```

**L11896**
```typescript
          ticket_max_usd?: number | null
```

**L11897**
```typescript
          ticket_min_usd?: number | null
```

**L11898**
```typescript
          updated_at?: string
```

**L11899**
```typescript
          updated_by?: string | null
```

**L11900**
```typescript
        }
```

**L11901**
```typescript
        Update: {
```

**L11902**
```typescript
          aum_usd?: number | null
```

**L11903**
```typescript
          created_at?: string
```

**L11904**
```typescript
          created_by?: string | null
```

**L11905**
```typescript
          fund_name?: string | null
```

**L11906**
```typescript
          fund_size_usd?: number | null
```

**L11907**
```typescript
          fund_vintage_year?: number | null
```

**L11908**
```typescript
          geographic_focus?: string[]
```

**L11909**
```typescript
          id?: string
```

**L11910**
```typescript
          investment_stages?: string[]
```

**L11911**
```typescript
          is_lead_investor?: boolean
```

**L11912**
```typescript
          is_strategic?: boolean
```

**L11913**
```typescript
          party_id?: string
```

**L11914**
```typescript
          sector_focus?: string[]
```

**L11915**
```typescript
          subtype?: Database["app"]["Enums"]["investor_subtype"] | null
```

**L11916**
```typescript
          ticket_max_usd?: number | null
```

**L11917**
```typescript
          ticket_min_usd?: number | null
```

**L11918**
```typescript
          updated_at?: string
```

**L11919**
```typescript
          updated_by?: string | null
```

**L11920**
```typescript
        }
```

**L11921**
```typescript
        Relationships: [
```

**L11922**
```typescript
          {
```

**L11923**
```typescript
            foreignKeyName: "urm_investor_profile_party_id_fkey"
```

**L11924**
```typescript
            columns: ["party_id"]
```

**L11925**
```typescript
            isOneToOne: true
```

**L11926**
```typescript
            referencedRelation: "parties"
```

**L11927**
```typescript
            referencedColumns: ["id"]
```

**L11928**
```typescript
          },
```

**L11929**
```typescript
        ]
```

**L11930**
```typescript
      }
```

**L11931**
```typescript
      paper_mill_profile: {
```

**L11932**
```typescript
        Row: {
```

**L11933**
```typescript
          auto_promoted_at: string | null
```

**L11934**
```typescript
          created_at: string
```

**L11935**
```typescript
          deleted_at: string | null
```

**L11936**
```typescript
          europe_mills_footprint: string | null
```

**L11937**
```typescript
          evidence_level: string | null
```

**L11938**
```typescript
          filler_use_intensity: string | null
```

**L11939**
```typescript
          headquarters: string | null
```

**L11940**
```typescript
          id: string
```

**L11941**
```typescript
          industry_source: string | null
```

**L11942**
```typescript
          main_product_category: string | null
```

**L11943**
```typescript
          main_products: string | null
```

**L11944**
```typescript
          module_data: Json
```

**L11945**
```typescript
          party_id: string
```

**L11946**
```typescript
          updated_at: string
```

**L11947**
```typescript
        }
```

**L11948**
```typescript
        Insert: {
```

**L11949**
```typescript
          auto_promoted_at?: string | null
```

**L11950**
```typescript
          created_at?: string
```

**L11951**
```typescript
          deleted_at?: string | null
```

**L11952**
```typescript
          europe_mills_footprint?: string | null
```

**L11953**
```typescript
          evidence_level?: string | null
```

**L11954**
```typescript
          filler_use_intensity?: string | null
```

**L11955**
```typescript
          headquarters?: string | null
```

**L11956**
```typescript
          id?: string
```

**L11957**
```typescript
          industry_source?: string | null
```

**L11958**
```typescript
          main_product_category?: string | null
```

**L11959**
```typescript
          main_products?: string | null
```

**L11960**
```typescript
          module_data?: Json
```

**L11961**
```typescript
          party_id: string
```

**L11962**
```typescript
          updated_at?: string
```

**L11963**
```typescript
        }
```

**L11964**
```typescript
        Update: {
```

**L11965**
```typescript
          auto_promoted_at?: string | null
```

**L11966**
```typescript
          created_at?: string
```

**L11967**
```typescript
          deleted_at?: string | null
```

**L11968**
```typescript
          europe_mills_footprint?: string | null
```

**L11969**
```typescript
          evidence_level?: string | null
```

**L11970**
```typescript
          filler_use_intensity?: string | null
```

**L11971**
```typescript
          headquarters?: string | null
```

**L11972**
```typescript
          id?: string
```

**L11973**
```typescript
          industry_source?: string | null
```

**L11974**
```typescript
          main_product_category?: string | null
```

**L11975**
```typescript
          main_products?: string | null
```

**L11976**
```typescript
          module_data?: Json
```

**L11977**
```typescript
          party_id?: string
```

**L11978**
```typescript
          updated_at?: string
```

**L11979**
```typescript
        }
```

**L11980**
```typescript
        Relationships: [
```

**L11981**
```typescript
          {
```

**L11982**
```typescript
            foreignKeyName: "urm_paper_mill_profile_party_id_fkey"
```

**L11983**
```typescript
            columns: ["party_id"]
```

**L11984**
```typescript
            isOneToOne: true
```

**L11985**
```typescript
            referencedRelation: "parties"
```

**L11986**
```typescript
            referencedColumns: ["id"]
```

**L11987**
```typescript
          },
```

**L11988**
```typescript
        ]
```

**L11989**
```typescript
      }
```

**L11990**
```typescript
      parties: {
```

**L11991**
```typescript
        Row: {
```

**L11992**
```typescript
          address: string | null
```

**L11993**
```typescript
          annual_revenue_usd: number | null
```

**L11994**
```typescript
          city: string | null
```

**L11995**
```typescript
          country_code: string | null
```

**L11996**
```typescript
          created_at: string
```

**L11997**
```typescript
          created_by: string | null
```

**L11998**
```typescript
          deleted_at: string | null
```

**L11999**
```typescript
          domain_normalized: string | null
```

**L12000**
```typescript
          email: string | null
```

**L12001**
```typescript
          employee_count: number | null
```

**L12002**
```typescript
          entity_type_id: number
```

**L12003**
```typescript
          founded_year: number | null
```

**L12004**
```typescript
          id: string
```

**L12005**
```typescript
          lei_code: string | null
```

**L12006**
```typescript
          linkedin_url: string | null
```

**L12007**
```typescript
          notes: string | null
```

**L12008**
```typescript
          owner_user_id: string | null
```

**L12009**
```typescript
          party_name: string
```

**L12010**
```typescript
          party_type_id: number
```

**L12011**
```typescript
          phone_e164: string | null
```

**L12012**
```typescript
          region: string | null
```

**L12013**
```typescript
          source: string | null
```

**L12014**
```typescript
          source_external_id: string | null
```

**L12015**
```typescript
          status: string
```

**L12016**
```typescript
          tax_id: string | null
```

**L12017**
```typescript
          updated_at: string
```

**L12018**
```typescript
          updated_by: string | null
```

**L12019**
```typescript
          website: string | null
```

**L12020**
```typescript
        }
```

**L12021**
```typescript
        Insert: {
```

**L12022**
```typescript
          address?: string | null
```

**L12023**
```typescript
          annual_revenue_usd?: number | null
```

**L12024**
```typescript
          city?: string | null
```

**L12025**
```typescript
          country_code?: string | null
```

**L12026**
```typescript
          created_at?: string
```

**L12027**
```typescript
          created_by?: string | null
```

**L12028**
```typescript
          deleted_at?: string | null
```

**L12029**
```typescript
          domain_normalized?: string | null
```

**L12030**
```typescript
          email?: string | null
```

**L12031**
```typescript
          employee_count?: number | null
```

**L12032**
```typescript
          entity_type_id: number
```

**L12033**
```typescript
          founded_year?: number | null
```

**L12034**
```typescript
          id?: string
```

**L12035**
```typescript
          lei_code?: string | null
```

**L12036**
```typescript
          linkedin_url?: string | null
```

**L12037**
```typescript
          notes?: string | null
```

**L12038**
```typescript
          owner_user_id?: string | null
```

**L12039**
```typescript
          party_name: string
```

**L12040**
```typescript
          party_type_id: number
```

**L12041**
```typescript
          phone_e164?: string | null
```

**L12042**
```typescript
          region?: string | null
```

**L12043**
```typescript
          source?: string | null
```

**L12044**
```typescript
          source_external_id?: string | null
```

**L12045**
```typescript
          status?: string
```

**L12046**
```typescript
          tax_id?: string | null
```

**L12047**
```typescript
          updated_at?: string
```

**L12048**
```typescript
          updated_by?: string | null
```

**L12049**
```typescript
          website?: string | null
```

**L12050**
```typescript
        }
```

**L12051**
```typescript
        Update: {
```

**L12052**
```typescript
          address?: string | null
```

**L12053**
```typescript
          annual_revenue_usd?: number | null
```

**L12054**
```typescript
          city?: string | null
```

**L12055**
```typescript
          country_code?: string | null
```

**L12056**
```typescript
          created_at?: string
```

**L12057**
```typescript
          created_by?: string | null
```

**L12058**
```typescript
          deleted_at?: string | null
```

**L12059**
```typescript
          domain_normalized?: string | null
```

**L12060**
```typescript
          email?: string | null
```

**L12061**
```typescript
          employee_count?: number | null
```

**L12062**
```typescript
          entity_type_id?: number
```

**L12063**
```typescript
          founded_year?: number | null
```

**L12064**
```typescript
          id?: string
```

**L12065**
```typescript
          lei_code?: string | null
```

**L12066**
```typescript
          linkedin_url?: string | null
```

**L12067**
```typescript
          notes?: string | null
```

**L12068**
```typescript
          owner_user_id?: string | null
```

**L12069**
```typescript
          party_name?: string
```

**L12070**
```typescript
          party_type_id?: number
```

**L12071**
```typescript
          phone_e164?: string | null
```

**L12072**
```typescript
          region?: string | null
```

**L12073**
```typescript
          source?: string | null
```

**L12074**
```typescript
          source_external_id?: string | null
```

**L12075**
```typescript
          status?: string
```

**L12076**
```typescript
          tax_id?: string | null
```

**L12077**
```typescript
          updated_at?: string
```

**L12078**
```typescript
          updated_by?: string | null
```

**L12079**
```typescript
          website?: string | null
```

**L12080**
```typescript
        }
```

**L12081**
```typescript
        Relationships: [
```

**L12082**
```typescript
          {
```

**L12083**
```typescript
            foreignKeyName: "parties_entity_type_id_fkey"
```

**L12084**
```typescript
            columns: ["entity_type_id"]
```

**L12085**
```typescript
            isOneToOne: false
```

**L12086**
```typescript
            referencedRelation: "entity_types"
```

**L12087**
```typescript
            referencedColumns: ["id"]
```

**L12088**
```typescript
          },
```

**L12089**
```typescript
          {
```

**L12090**
```typescript
            foreignKeyName: "parties_party_type_id_fkey"
```

**L12091**
```typescript
            columns: ["party_type_id"]
```

**L12092**
```typescript
            isOneToOne: false
```

**L12093**
```typescript
            referencedRelation: "party_types"
```

**L12094**
```typescript
            referencedColumns: ["id"]
```

**L12095**
```typescript
          },
```

**L12096**
```typescript
        ]
```

**L12097**
```typescript
      }
```

**L12098**
```typescript
      party_supply_links: {
```

**L12099**
```typescript
        Row: {
```

**L12100**
```typescript
          active_since: string | null
```

**L12101**
```typescript
          active_until: string | null
```

**L12102**
```typescript
          confidence: string | null
```

**L12103**
```typescript
          created_at: string | null
```

**L12104**
```typescript
          deleted_at: string | null
```

**L12105**
```typescript
          filler_party_id: string
```

**L12106**
```typescript
          id: string
```

**L12107**
```typescript
          link_type: string | null
```

**L12108**
```typescript
          mill_party_id: string
```

**L12109**
```typescript
          module_data: Json | null
```

**L12110**
```typescript
          notes: string | null
```

**L12111**
```typescript
          updated_at: string | null
```

**L12112**
```typescript
          volume_estimate: string | null
```

**L12113**
```typescript
        }
```

**L12114**
```typescript
        Insert: {
```

**L12115**
```typescript
          active_since?: string | null
```

**L12116**
```typescript
          active_until?: string | null
```

**L12117**
```typescript
          confidence?: string | null
```

**L12118**
```typescript
          created_at?: string | null
```

**L12119**
```typescript
          deleted_at?: string | null
```

**L12120**
```typescript
          filler_party_id: string
```

**L12121**
```typescript
          id?: string
```

**L12122**
```typescript
          link_type?: string | null
```

**L12123**
```typescript
          mill_party_id: string
```

**L12124**
```typescript
          module_data?: Json | null
```

**L12125**
```typescript
          notes?: string | null
```

**L12126**
```typescript
          updated_at?: string | null
```

**L12127**
```typescript
          volume_estimate?: string | null
```

**L12128**
```typescript
        }
```

**L12129**
```typescript
        Update: {
```

**L12130**
```typescript
          active_since?: string | null
```

**L12131**
```typescript
          active_until?: string | null
```

**L12132**
```typescript
          confidence?: string | null
```

**L12133**
```typescript
          created_at?: string | null
```

**L12134**
```typescript
          deleted_at?: string | null
```

**L12135**
```typescript
          filler_party_id?: string
```

**L12136**
```typescript
          id?: string
```

**L12137**
```typescript
          link_type?: string | null
```

**L12138**
```typescript
          mill_party_id?: string
```

**L12139**
```typescript
          module_data?: Json | null
```

**L12140**
```typescript
          notes?: string | null
```

**L12141**
```typescript
          updated_at?: string | null
```

**L12142**
```typescript
          volume_estimate?: string | null
```

**L12143**
```typescript
        }
```

**L12144**
```typescript
        Relationships: [
```

**L12145**
```typescript
          {
```

**L12146**
```typescript
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
```

**L12147**
```typescript
            columns: ["filler_party_id"]
```

**L12148**
```typescript
            isOneToOne: false
```

**L12149**
```typescript
            referencedRelation: "parties"
```

**L12150**
```typescript
            referencedColumns: ["id"]
```

**L12151**
```typescript
          },
```

**L12152**
```typescript
          {
```

**L12153**
```typescript
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
```

**L12154**
```typescript
            columns: ["mill_party_id"]
```

**L12155**
```typescript
            isOneToOne: false
```

**L12156**
```typescript
            referencedRelation: "parties"
```

**L12157**
```typescript
            referencedColumns: ["id"]
```

**L12158**
```typescript
          },
```

**L12159**
```typescript
        ]
```

**L12160**
```typescript
      }
```

**L12161**
```typescript
      party_types: {
```

**L12162**
```typescript
        Row: {
```

**L12163**
```typescript
          code: string
```

**L12164**
```typescript
          created_at: string
```

**L12165**
```typescript
          description: string | null
```

**L12166**
```typescript
          display_name_en: string
```

**L12167**
```typescript
          display_name_ja: string | null
```

**L12168**
```typescript
          display_name_ko: string
```

**L12169**
```typescript
          id: number
```

**L12170**
```typescript
          is_active: boolean
```

**L12171**
```typescript
          sort_order: number
```

**L12172**
```typescript
          updated_at: string
```

**L12173**
```typescript
        }
```

**L12174**
```typescript
        Insert: {
```

**L12175**
```typescript
          code: string
```

**L12176**
```typescript
          created_at?: string
```

**L12177**
```typescript
          description?: string | null
```

**L12178**
```typescript
          display_name_en: string
```

**L12179**
```typescript
          display_name_ja?: string | null
```

**L12180**
```typescript
          display_name_ko: string
```

**L12181**
```typescript
          id: number
```

**L12182**
```typescript
          is_active?: boolean
```

**L12183**
```typescript
          sort_order?: number
```

**L12184**
```typescript
          updated_at?: string
```

**L12185**
```typescript
        }
```

**L12186**
```typescript
        Update: {
```

**L12187**
```typescript
          code?: string
```

**L12188**
```typescript
          created_at?: string
```

**L12189**
```typescript
          description?: string | null
```

**L12190**
```typescript
          display_name_en?: string
```

**L12191**
```typescript
          display_name_ja?: string | null
```

**L12192**
```typescript
          display_name_ko?: string
```

**L12193**
```typescript
          id?: number
```

**L12194**
```typescript
          is_active?: boolean
```

**L12195**
```typescript
          sort_order?: number
```

**L12196**
```typescript
          updated_at?: string
```

**L12197**
```typescript
        }
```

**L12198**
```typescript
        Relationships: []
```

**L12199**
```typescript
      }
```

**L12200**
```typescript
      pipelines: {
```

**L12201**
```typescript
        Row: {
```

**L12202**
```typescript
          code: string
```

**L12203**
```typescript
          created_at: string
```

**L12204**
```typescript
          created_by: string | null
```

**L12205**
```typescript
          description: string | null
```

**L12206**
```typescript
          id: string
```

**L12207**
```typescript
          is_active: boolean
```

**L12208**
```typescript
          is_default: boolean
```

**L12209**
```typescript
          name: string
```

**L12210**
```typescript
          sort_order: number
```

**L12211**
```typescript
          updated_at: string
```

**L12212**
```typescript
          updated_by: string | null
```

**L12213**
```typescript
        }
```

**L12214**
```typescript
        Insert: {
```

**L12215**
```typescript
          code: string
```

**L12216**
```typescript
          created_at?: string
```

**L12217**
```typescript
          created_by?: string | null
```

**L12218**
```typescript
          description?: string | null
```

**L12219**
```typescript
          id?: string
```

**L12220**
```typescript
          is_active?: boolean
```

**L12221**
```typescript
          is_default?: boolean
```

**L12222**
```typescript
          name: string
```

**L12223**
```typescript
          sort_order?: number
```

**L12224**
```typescript
          updated_at?: string
```

**L12225**
```typescript
          updated_by?: string | null
```

**L12226**
```typescript
        }
```

**L12227**
```typescript
        Update: {
```

**L12228**
```typescript
          code?: string
```

**L12229**
```typescript
          created_at?: string
```

**L12230**
```typescript
          created_by?: string | null
```

**L12231**
```typescript
          description?: string | null
```

**L12232**
```typescript
          id?: string
```

**L12233**
```typescript
          is_active?: boolean
```

**L12234**
```typescript
          is_default?: boolean
```

**L12235**
```typescript
          name?: string
```

**L12236**
```typescript
          sort_order?: number
```

**L12237**
```typescript
          updated_at?: string
```

**L12238**
```typescript
          updated_by?: string | null
```

**L12239**
```typescript
        }
```

**L12240**
```typescript
        Relationships: []
```

**L12241**
```typescript
      }
```

**L12242**
```typescript
      plant_supply_links: {
```

**L12243**
```typescript
        Row: {
```

**L12244**
```typescript
          active_since: string | null
```

**L12245**
```typescript
          active_until: string | null
```

**L12246**
```typescript
          confidence: string | null
```

**L12247**
```typescript
          created_at: string | null
```

**L12248**
```typescript
          created_by: string | null
```

**L12249**
```typescript
          deleted_at: string | null
```

**L12250**
```typescript
          filler_party_id: string
```

**L12251**
```typescript
          id: string
```

**L12252**
```typescript
          link_type: string | null
```

**L12253**
```typescript
          mill_party_id: string
```

**L12254**
```typescript
          module_data: Json | null
```

**L12255**
```typescript
          notes: string | null
```

**L12256**
```typescript
          plant_country_code: string | null
```

**L12257**
```typescript
          plant_identifier: string
```

**L12258**
```typescript
          plant_location: string | null
```

**L12259**
```typescript
          updated_at: string | null
```

**L12260**
```typescript
          updated_by: string | null
```

**L12261**
```typescript
          volume_estimate: string | null
```

**L12262**
```typescript
        }
```

**L12263**
```typescript
        Insert: {
```

**L12264**
```typescript
          active_since?: string | null
```

**L12265**
```typescript
          active_until?: string | null
```

**L12266**
```typescript
          confidence?: string | null
```

**L12267**
```typescript
          created_at?: string | null
```

**L12268**
```typescript
          created_by?: string | null
```

**L12269**
```typescript
          deleted_at?: string | null
```

**L12270**
```typescript
          filler_party_id: string
```

**L12271**
```typescript
          id?: string
```

**L12272**
```typescript
          link_type?: string | null
```

**L12273**
```typescript
          mill_party_id: string
```

**L12274**
```typescript
          module_data?: Json | null
```

**L12275**
```typescript
          notes?: string | null
```

**L12276**
```typescript
          plant_country_code?: string | null
```

**L12277**
```typescript
          plant_identifier: string
```

**L12278**
```typescript
          plant_location?: string | null
```

**L12279**
```typescript
          updated_at?: string | null
```

**L12280**
```typescript
          updated_by?: string | null
```

**L12281**
```typescript
          volume_estimate?: string | null
```

**L12282**
```typescript
        }
```

**L12283**
```typescript
        Update: {
```

**L12284**
```typescript
          active_since?: string | null
```

**L12285**
```typescript
          active_until?: string | null
```

**L12286**
```typescript
          confidence?: string | null
```

**L12287**
```typescript
          created_at?: string | null
```

**L12288**
```typescript
          created_by?: string | null
```

**L12289**
```typescript
          deleted_at?: string | null
```

**L12290**
```typescript
          filler_party_id?: string
```

**L12291**
```typescript
          id?: string
```

**L12292**
```typescript
          link_type?: string | null
```

**L12293**
```typescript
          mill_party_id?: string
```

**L12294**
```typescript
          module_data?: Json | null
```

**L12295**
```typescript
          notes?: string | null
```

**L12296**
```typescript
          plant_country_code?: string | null
```

**L12297**
```typescript
          plant_identifier?: string
```

**L12298**
```typescript
          plant_location?: string | null
```

**L12299**
```typescript
          updated_at?: string | null
```

**L12300**
```typescript
          updated_by?: string | null
```

**L12301**
```typescript
          volume_estimate?: string | null
```

**L12302**
```typescript
        }
```

**L12303**
```typescript
        Relationships: [
```

**L12304**
```typescript
          {
```

**L12305**
```typescript
            foreignKeyName: "plant_supply_links_filler_party_id_fkey"
```

**L12306**
```typescript
            columns: ["filler_party_id"]
```

**L12307**
```typescript
            isOneToOne: false
```

**L12308**
```typescript
            referencedRelation: "parties"
```

**L12309**
```typescript
            referencedColumns: ["id"]
```

**L12310**
```typescript
          },
```

**L12311**
```typescript
          {
```

**L12312**
```typescript
            foreignKeyName: "plant_supply_links_mill_party_id_fkey"
```

**L12313**
```typescript
            columns: ["mill_party_id"]
```

**L12314**
```typescript
            isOneToOne: false
```

**L12315**
```typescript
            referencedRelation: "parties"
```

**L12316**
```typescript
            referencedColumns: ["id"]
```

**L12317**
```typescript
          },
```

**L12318**
```typescript
        ]
```

**L12319**
```typescript
      }
```

**L12320**
```typescript
      stages: {
```

**L12321**
```typescript
        Row: {
```

**L12322**
```typescript
          code: string
```

**L12323**
```typescript
          color_hex: string | null
```

**L12324**
```typescript
          created_at: string
```

**L12325**
```typescript
          default_probability_pct: number
```

**L12326**
```typescript
          description: string | null
```

**L12327**
```typescript
          id: string
```

**L12328**
```typescript
          is_active: boolean
```

**L12329**
```typescript
          is_lost: boolean
```

**L12330**
```typescript
          is_terminal: boolean
```

**L12331**
```typescript
          is_won: boolean
```

**L12332**
```typescript
          name: string
```

**L12333**
```typescript
          pipeline_id: string
```

**L12334**
```typescript
          sort_order: number
```

**L12335**
```typescript
          updated_at: string
```

**L12336**
```typescript
        }
```

**L12337**
```typescript
        Insert: {
```

**L12338**
```typescript
          code: string
```

**L12339**
```typescript
          color_hex?: string | null
```

**L12340**
```typescript
          created_at?: string
```

**L12341**
```typescript
          default_probability_pct?: number
```

**L12342**
```typescript
          description?: string | null
```

**L12343**
```typescript
          id?: string
```

**L12344**
```typescript
          is_active?: boolean
```

**L12345**
```typescript
          is_lost?: boolean
```

**L12346**
```typescript
          is_terminal?: boolean
```

**L12347**
```typescript
          is_won?: boolean
```

**L12348**
```typescript
          name: string
```

**L12349**
```typescript
          pipeline_id: string
```

**L12350**
```typescript
          sort_order?: number
```

**L12351**
```typescript
          updated_at?: string
```

**L12352**
```typescript
        }
```

**L12353**
```typescript
        Update: {
```

**L12354**
```typescript
          code?: string
```

**L12355**
```typescript
          color_hex?: string | null
```

**L12356**
```typescript
          created_at?: string
```

**L12357**
```typescript
          default_probability_pct?: number
```

**L12358**
```typescript
          description?: string | null
```

**L12359**
```typescript
          id?: string
```

**L12360**
```typescript
          is_active?: boolean
```

**L12361**
```typescript
          is_lost?: boolean
```

**L12362**
```typescript
          is_terminal?: boolean
```

**L12363**
```typescript
          is_won?: boolean
```

**L12364**
```typescript
          name?: string
```

**L12365**
```typescript
          pipeline_id?: string
```

**L12366**
```typescript
          sort_order?: number
```

**L12367**
```typescript
          updated_at?: string
```

**L12368**
```typescript
        }
```

**L12369**
```typescript
        Relationships: [
```

**L12370**
```typescript
          {
```

**L12371**
```typescript
            foreignKeyName: "stages_pipeline_id_fkey"
```

**L12372**
```typescript
            columns: ["pipeline_id"]
```

**L12373**
```typescript
            isOneToOne: false
```

**L12374**
```typescript
            referencedRelation: "pipelines"
```

**L12375**
```typescript
            referencedColumns: ["id"]
```

**L12376**
```typescript
          },
```

**L12377**
```typescript
        ]
```

**L12378**
```typescript
      }
```

**L12379**
```typescript
      tasks: {
```

**L12380**
```typescript
        Row: {
```

**L12381**
```typescript
          actual_minutes: number | null
```

**L12382**
```typescript
          assigned_to_contact_id: string | null
```

**L12383**
```typescript
          assigned_to_user_id: string | null
```

**L12384**
```typescript
          checklist_id: string | null
```

**L12385**
```typescript
          completed_at: string | null
```

**L12386**
```typescript
          created_at: string
```

**L12387**
```typescript
          created_by: string | null
```

**L12388**
```typescript
          deal_id: string
```

**L12389**
```typescript
          deleted_at: string | null
```

**L12390**
```typescript
          description: string | null
```

**L12391**
```typescript
          due_at: string | null
```

**L12392**
```typescript
          estimated_minutes: number | null
```

**L12393**
```typescript
          id: string
```

**L12394**
```typescript
          module_data: Json
```

**L12395**
```typescript
          notes: string | null
```

**L12396**
```typescript
          priority: string
```

**L12397**
```typescript
          started_at: string | null
```

**L12398**
```typescript
          status: string
```

**L12399**
```typescript
          title: string
```

**L12400**
```typescript
          updated_at: string
```

**L12401**
```typescript
          updated_by: string | null
```

**L12402**
```typescript
        }
```

**L12403**
```typescript
        Insert: {
```

**L12404**
```typescript
          actual_minutes?: number | null
```

**L12405**
```typescript
          assigned_to_contact_id?: string | null
```

**L12406**
```typescript
          assigned_to_user_id?: string | null
```

**L12407**
```typescript
          checklist_id?: string | null
```

**L12408**
```typescript
          completed_at?: string | null
```

**L12409**
```typescript
          created_at?: string
```

**L12410**
```typescript
          created_by?: string | null
```

**L12411**
```typescript
          deal_id: string
```

**L12412**
```typescript
          deleted_at?: string | null
```

**L12413**
```typescript
          description?: string | null
```

**L12414**
```typescript
          due_at?: string | null
```

**L12415**
```typescript
          estimated_minutes?: number | null
```

**L12416**
```typescript
          id?: string
```

**L12417**
```typescript
          module_data?: Json
```

**L12418**
```typescript
          notes?: string | null
```

**L12419**
```typescript
          priority?: string
```

**L12420**
```typescript
          started_at?: string | null
```

**L12421**
```typescript
          status?: string
```

**L12422**
```typescript
          title: string
```

**L12423**
```typescript
          updated_at?: string
```

**L12424**
```typescript
          updated_by?: string | null
```

**L12425**
```typescript
        }
```

**L12426**
```typescript
        Update: {
```

**L12427**
```typescript
          actual_minutes?: number | null
```

**L12428**
```typescript
          assigned_to_contact_id?: string | null
```

**L12429**
```typescript
          assigned_to_user_id?: string | null
```

**L12430**
```typescript
          checklist_id?: string | null
```

**L12431**
```typescript
          completed_at?: string | null
```

**L12432**
```typescript
          created_at?: string
```

**L12433**
```typescript
          created_by?: string | null
```

**L12434**
```typescript
          deal_id?: string
```

**L12435**
```typescript
          deleted_at?: string | null
```

**L12436**
```typescript
          description?: string | null
```

**L12437**
```typescript
          due_at?: string | null
```

**L12438**
```typescript
          estimated_minutes?: number | null
```

**L12439**
```typescript
          id?: string
```

**L12440**
```typescript
          module_data?: Json
```

**L12441**
```typescript
          notes?: string | null
```

**L12442**
```typescript
          priority?: string
```

**L12443**
```typescript
          started_at?: string | null
```

**L12444**
```typescript
          status?: string
```

**L12445**
```typescript
          title?: string
```

**L12446**
```typescript
          updated_at?: string
```

**L12447**
```typescript
          updated_by?: string | null
```

**L12448**
```typescript
        }
```

**L12449**
```typescript
        Relationships: [
```

**L12450**
```typescript
          {
```

**L12451**
```typescript
            foreignKeyName: "tasks_checklist_id_fkey"
```

**L12452**
```typescript
            columns: ["checklist_id"]
```

**L12453**
```typescript
            isOneToOne: false
```

**L12454**
```typescript
            referencedRelation: "deal_checklists"
```

**L12455**
```typescript
            referencedColumns: ["id"]
```

**L12456**
```typescript
          },
```

**L12457**
```typescript
          {
```

**L12458**
```typescript
            foreignKeyName: "tasks_deal_id_fkey"
```

**L12459**
```typescript
            columns: ["deal_id"]
```

**L12460**
```typescript
            isOneToOne: false
```

**L12461**
```typescript
            referencedRelation: "deals"
```

**L12462**
```typescript
            referencedColumns: ["id"]
```

**L12463**
```typescript
          },
```

**L12464**
```typescript
        ]
```

**L12465**
```typescript
      }
```

**L12466**
```typescript
    }
```

**L12467**
```typescript
    Views: {
```

**L12468**
```typescript
      [_ in never]: never
```

**L12469**
```typescript
    }
```

**L12470**
```typescript
    Functions: {
```

**L12471**
```typescript
      [_ in never]: never
```

**L12472**
```typescript
    }
```

**L12473**
```typescript
    Enums: {
```

**L12474**
```typescript
      [_ in never]: never
```

**L12475**
```typescript
    }
```

**L12476**
```typescript
    CompositeTypes: {
```

**L12477**
```typescript
      [_ in never]: never
```

**L12478**
```typescript
    }
```

**L12479**
```typescript
  }
```

**L12480**
```typescript
}
```

**L12481**
```typescript

```

**L12482**
```typescript
type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">
```

**L12483**
```typescript

```

**L12484**
```typescript
type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]
```

**L12485**
```typescript

```

**L12486**
```typescript
export type Tables<
```

**L12487**
```typescript
  DefaultSchemaTableNameOrOptions extends
```

**L12488**
```typescript
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
```

**L12489**
```typescript
    | { schema: keyof DatabaseWithoutInternals },
```

**L12490**
```typescript
  TableName extends DefaultSchemaTableNameOrOptions extends {
```

**L12491**
```typescript
    schema: keyof DatabaseWithoutInternals
```

**L12492**
```typescript
  }
```

**L12493**
```typescript
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
```

**L12494**
```typescript
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
```

**L12495**
```typescript
    : never = never,
```

**L12496**
```typescript
> = DefaultSchemaTableNameOrOptions extends {
```

**L12497**
```typescript
  schema: keyof DatabaseWithoutInternals
```

**L12498**
```typescript
}
```

**L12499**
```typescript
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
```

**L12500**
```typescript
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
```

**L12501**
```typescript
      Row: infer R
```

**L12502**
```typescript
    }
```

**L12503**
```typescript
    ? R
```

**L12504**
```typescript
    : never
```

**L12505**
```typescript
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
```

**L12506**
```typescript
        DefaultSchema["Views"])
```

**L12507**
```typescript
    ? (DefaultSchema["Tables"] &
```

**L12508**
```typescript
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
```

**L12509**
```typescript
        Row: infer R
```

**L12510**
```typescript
      }
```

**L12511**
```typescript
      ? R
```

**L12512**
```typescript
      : never
```

**L12513**
```typescript
    : never
```

**L12514**
```typescript

```

**L12515**
```typescript
export type TablesInsert<
```

**L12516**
```typescript
  DefaultSchemaTableNameOrOptions extends
```

**L12517**
```typescript
    | keyof DefaultSchema["Tables"]
```

**L12518**
```typescript
    | { schema: keyof DatabaseWithoutInternals },
```

**L12519**
```typescript
  TableName extends DefaultSchemaTableNameOrOptions extends {
```

**L12520**
```typescript
    schema: keyof DatabaseWithoutInternals
```

**L12521**
```typescript
  }
```

**L12522**
```typescript
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
```

**L12523**
```typescript
    : never = never,
```

**L12524**
```typescript
> = DefaultSchemaTableNameOrOptions extends {
```

**L12525**
```typescript
  schema: keyof DatabaseWithoutInternals
```

**L12526**
```typescript
}
```

**L12527**
```typescript
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
```

**L12528**
```typescript
      Insert: infer I
```

**L12529**
```typescript
    }
```

**L12530**
```typescript
    ? I
```

**L12531**
```typescript
    : never
```

**L12532**
```typescript
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
```

**L12533**
```typescript
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
```

**L12534**
```typescript
        Insert: infer I
```

**L12535**
```typescript
      }
```

**L12536**
```typescript
      ? I
```

**L12537**
```typescript
      : never
```

**L12538**
```typescript
    : never
```

**L12539**
```typescript

```

**L12540**
```typescript
export type TablesUpdate<
```

**L12541**
```typescript
  DefaultSchemaTableNameOrOptions extends
```

**L12542**
```typescript
    | keyof DefaultSchema["Tables"]
```

**L12543**
```typescript
    | { schema: keyof DatabaseWithoutInternals },
```

**L12544**
```typescript
  TableName extends DefaultSchemaTableNameOrOptions extends {
```

**L12545**
```typescript
    schema: keyof DatabaseWithoutInternals
```

**L12546**
```typescript
  }
```

**L12547**
```typescript
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
```

**L12548**
```typescript
    : never = never,
```

**L12549**
```typescript
> = DefaultSchemaTableNameOrOptions extends {
```

**L12550**
```typescript
  schema: keyof DatabaseWithoutInternals
```

**L12551**
```typescript
}
```

**L12552**
```typescript
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
```

**L12553**
```typescript
      Update: infer U
```

**L12554**
```typescript
    }
```

**L12555**
```typescript
    ? U
```

**L12556**
```typescript
    : never
```

**L12557**
```typescript
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
```

**L12558**
```typescript
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
```

**L12559**
```typescript
        Update: infer U
```

**L12560**
```typescript
      }
```

**L12561**
```typescript
      ? U
```

**L12562**
```typescript
      : never
```

**L12563**
```typescript
    : never
```

**L12564**
```typescript

```

**L12565**
```typescript
export type Enums<
```

**L12566**
```typescript
  DefaultSchemaEnumNameOrOptions extends
```

**L12567**
```typescript
    | keyof DefaultSchema["Enums"]
```

**L12568**
```typescript
    | { schema: keyof DatabaseWithoutInternals },
```

**L12569**
```typescript
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
```

**L12570**
```typescript
    schema: keyof DatabaseWithoutInternals
```

**L12571**
```typescript
  }
```

**L12572**
```typescript
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
```

**L12573**
```typescript
    : never = never,
```

**L12574**
```typescript
> = DefaultSchemaEnumNameOrOptions extends {
```

**L12575**
```typescript
  schema: keyof DatabaseWithoutInternals
```

**L12576**
```typescript
}
```

**L12577**
```typescript
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
```

**L12578**
```typescript
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
```

**L12579**
```typescript
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
```

**L12580**
```typescript
    : never
```

**L12581**
```typescript

```

**L12582**
```typescript
export type CompositeTypes<
```

**L12583**
```typescript
  PublicCompositeTypeNameOrOptions extends
```

**L12584**
```typescript
    | keyof DefaultSchema["CompositeTypes"]
```

**L12585**
```typescript
    | { schema: keyof DatabaseWithoutInternals },
```

**L12586**
```typescript
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
```

**L12587**
```typescript
    schema: keyof DatabaseWithoutInternals
```

**L12588**
```typescript
  }
```

**L12589**
```typescript
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
```

**L12590**
```typescript
    : never = never,
```

**L12591**
```typescript
> = PublicCompositeTypeNameOrOptions extends {
```

**L12592**
```typescript
  schema: keyof DatabaseWithoutInternals
```

**L12593**
```typescript
}
```

**L12594**
```typescript
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
```

**L12595**
```typescript
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
```

**L12596**
```typescript
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
```

**L12597**
```typescript
    : never
```

**L12598**
```typescript

```

**L12599**
```typescript
export const Constants = {
```

**L12600**
```typescript
  ai: {
```

**L12601**
```typescript
    Enums: {
```

**L12602**
```typescript
      agent_role: [
```

**L12603**
```typescript
        "classifier",
```

**L12604**
```typescript
        "reply_drafter",
```

**L12605**
```typescript
        "strategy_advisor",
```

**L12606**
```typescript
        "summarizer",
```

**L12607**
```typescript
        "translator",
```

**L12608**
```typescript
        "extractor",
```

**L12609**
```typescript
      ],
```

**L12610**
```typescript
      draft_status: [
```

**L12611**
```typescript
        "pending_review",
```

**L12612**
```typescript
        "approved",
```

**L12613**
```typescript
        "sent",
```

**L12614**
```typescript
        "rejected",
```

**L12615**
```typescript
        "expired",
```

**L12616**
```typescript
        "auto_sent",
```

**L12617**
```typescript
      ],
```

**L12618**
```typescript
      run_status: [
```

**L12619**
```typescript
        "running",
```

**L12620**
```typescript
        "completed",
```

**L12621**
```typescript
        "failed",
```

**L12622**
```typescript
        "timed_out",
```

**L12623**
```typescript
        "rate_limited",
```

**L12624**
```typescript
      ],
```

**L12625**
```typescript
    },
```

**L12626**
```typescript
  },
```

**L12627**
```typescript
  app: {
```

**L12628**
```typescript
    Enums: {
```

**L12629**
```typescript
      attendee_response: ["no_response", "accepted", "declined", "tentative"],
```

**L12630**
```typescript
      attendee_role: ["organizer", "required", "optional", "resource"],
```

**L12631**
```typescript
      buyer_subtype: [
```

**L12632**
```typescript
        "distributor",
```

**L12633**
```typescript
        "wholesaler",
```

**L12634**
```typescript
        "retailer",
```

**L12635**
```typescript
        "oem_partner",
```

**L12636**
```typescript
        "end_brand",
```

**L12637**
```typescript
        "direct_user",
```

**L12638**
```typescript
        "other",
```

**L12639**
```typescript
      ],
```

**L12640**
```typescript
      calendar_provider: ["google", "microsoft", "internal"],
```

**L12641**
```typescript
      calendar_sync_status: [
```

**L12642**
```typescript
        "pending",
```

**L12643**
```typescript
        "syncing",
```

**L12644**
```typescript
        "success",
```

**L12645**
```typescript
        "partial",
```

**L12646**
```typescript
        "failed",
```

**L12647**
```typescript
      ],
```

**L12648**
```typescript
      consultation_channel: [
```

**L12649**
```typescript
        "inbound_email",
```

**L12650**
```typescript
        "meeting_notes",
```

**L12651**
```typescript
        "phone_call",
```

**L12652**
```typescript
        "manual_entry",
```

**L12653**
```typescript
        "attachment",
```

**L12654**
```typescript
      ],
```

**L12655**
```typescript
      decision_role: [
```

**L12656**
```typescript
        "champion",
```

**L12657**
```typescript
        "decision_maker",
```

**L12658**
```typescript
        "influencer",
```

**L12659**
```typescript
        "gatekeeper",
```

**L12660**
```typescript
        "user",
```

**L12661**
```typescript
        "unknown",
```

**L12662**
```typescript
      ],
```

**L12663**
```typescript
      dedup_status: [
```

**L12664**
```typescript
        "pending",
```

**L12665**
```typescript
        "auto_merged",
```

**L12666**
```typescript
        "manual_merged",
```

**L12667**
```typescript
        "rejected_duplicate",
```

**L12668**
```typescript
        "kept_separate",
```

**L12669**
```typescript
      ],
```

**L12670**
```typescript
      direction_type: ["inbound", "outbound", "internal"],
```

**L12671**
```typescript
      email_sequence_status: ["draft", "active", "paused", "archived"],
```

**L12672**
```typescript
      engagement_channel: [
```

**L12673**
```typescript
        "in_person",
```

**L12674**
```typescript
        "video_call",
```

**L12675**
```typescript
        "video_conference",
```

**L12676**
```typescript
        "phone_call",
```

**L12677**
```typescript
        "email",
```

**L12678**
```typescript
        "sms",
```

**L12679**
```typescript
        "kakaotalk",
```

**L12680**
```typescript
        "wechat",
```

**L12681**
```typescript
        "whatsapp",
```

**L12682**
```typescript
        "linkedin",
```

**L12683**
```typescript
        "slack",
```

**L12684**
```typescript
        "webform",
```

**L12685**
```typescript
        "postal",
```

**L12686**
```typescript
        "hybrid",
```

**L12687**
```typescript
        "other",
```

**L12688**
```typescript
      ],
```

**L12689**
```typescript
      engagement_status: [
```

**L12690**
```typescript
        "open",
```

**L12691**
```typescript
        "in_progress",
```

**L12692**
```typescript
        "on_hold",
```

**L12693**
```typescript
        "won",
```

**L12694**
```typescript
        "lost",
```

**L12695**
```typescript
        "archived",
```

**L12696**
```typescript
      ],
```

**L12697**
```typescript
      enrollment_status: [
```

**L12698**
```typescript
        "active",
```

**L12699**
```typescript
        "completed",
```

**L12700**
```typescript
        "cancelled",
```

**L12701**
```typescript
        "failed",
```

**L12702**
```typescript
        "paused",
```

**L12703**
```typescript
      ],
```

**L12704**
```typescript
      entity_status: ["active", "inactive", "archived", "blocked"],
```

**L12705**
```typescript
      event_status: ["confirmed", "tentative", "cancelled"],
```

**L12706**
```typescript
      investor_subtype: [
```

**L12707**
```typescript
        "vc",
```

**L12708**
```typescript
        "cvc",
```

**L12709**
```typescript
        "growth_equity",
```

**L12710**
```typescript
        "private_equity",
```

**L12711**
```typescript
        "family_office",
```

**L12712**
```typescript
        "accelerator",
```

**L12713**
```typescript
        "angel",
```

**L12714**
```typescript
        "crowdfunding",
```

**L12715**
```typescript
        "government",
```

**L12716**
```typescript
        "other",
```

**L12717**
```typescript
      ],
```

**L12718**
```typescript
      invoice_status: [
```

**L12719**
```typescript
        "draft",
```

**L12720**
```typescript
        "issued",
```

**L12721**
```typescript
        "partial_paid",
```

**L12722**
```typescript
        "paid",
```

**L12723**
```typescript
        "overdue",
```

**L12724**
```typescript
        "void",
```

**L12725**
```typescript
      ],
```

**L12726**
```typescript
      meeting_status: [
```

**L12727**
```typescript
        "scheduled",
```

**L12728**
```typescript
        "completed",
```

**L12729**
```typescript
        "cancelled",
```

**L12730**
```typescript
        "no_show",
```

**L12731**
```typescript
        "rescheduled",
```

**L12732**
```typescript
      ],
```

**L12733**
```typescript
      meeting_type: [
```

**L12734**
```typescript
        "intro",
```

**L12735**
```typescript
        "discovery",
```

**L12736**
```typescript
        "pitch",
```

**L12737**
```typescript
        "negotiation",
```

**L12738**
```typescript
        "due_diligence",
```

**L12739**
```typescript
        "kickoff",
```

**L12740**
```typescript
        "review",
```

**L12741**
```typescript
        "closing",
```

**L12742**
```typescript
        "other",
```

**L12743**
```typescript
      ],
```

**L12744**
```typescript
      order_status: [
```

**L12745**
```typescript
        "draft",
```

**L12746**
```typescript
        "confirmed",
```

**L12747**
```typescript
        "in_production",
```

**L12748**
```typescript
        "ready_to_ship",
```

**L12749**
```typescript
        "shipped",
```

**L12750**
```typescript
        "delivered",
```

**L12751**
```typescript
        "cancelled",
```

**L12752**
```typescript
        "returned",
```

**L12753**
```typescript
      ],
```

**L12754**
```typescript
      participant_role: [
```

**L12755**
```typescript
        "sender",
```

**L12756**
```typescript
        "recipient",
```

**L12757**
```typescript
        "cc",
```

**L12758**
```typescript
        "bcc",
```

**L12759**
```typescript
        "host",
```

**L12760**
```typescript
        "attendee",
```

**L12761**
```typescript
        "observer",
```

**L12762**
```typescript
        "decision_maker",
```

**L12763**
```typescript
        "introducer",
```

**L12764**
```typescript
      ],
```

**L12765**
```typescript
      partner_seniority: [
```

**L12766**
```typescript
        "founder",
```

**L12767**
```typescript
        "partner",
```

**L12768**
```typescript
        "principal",
```

**L12769**
```typescript
        "associate",
```

**L12770**
```typescript
        "advisor",
```

**L12771**
```typescript
        "other",
```

**L12772**
```typescript
      ],
```

**L12773**
```typescript
      party_kind: [
```

**L12774**
```typescript
        "company",
```

**L12775**
```typescript
        "organization",
```

**L12776**
```typescript
        "individual",
```

**L12777**
```typescript
        "fund",
```

**L12778**
```typescript
        "government",
```

**L12779**
```typescript
      ],
```

**L12780**
```typescript
      party_type: [
```

**L12781**
```typescript
        "investor",
```

**L12782**
```typescript
        "paper_mill",
```

**L12783**
```typescript
        "partner",
```

**L12784**
```typescript
        "customer",
```

**L12785**
```typescript
        "crowdfunding",
```

**L12786**
```typescript
        "product_launch",
```

**L12787**
```typescript
        "sales",
```

**L12788**
```typescript
        "filler",
```

**L12789**
```typescript
        "filler_supplier",
```

**L12790**
```typescript
        "government_grant",
```

**L12791**
```typescript
        "buyer",
```

**L12792**
```typescript
      ],
```

**L12793**
```typescript
      pipeline_stage_type: [
```

**L12794**
```typescript
        "lead",
```

**L12795**
```typescript
        "qualified",
```

**L12796**
```typescript
        "proposal",
```

**L12797**
```typescript
        "negotiation",
```

**L12798**
```typescript
        "won",
```

**L12799**
```typescript
        "lost",
```

**L12800**
```typescript
      ],
```

**L12801**
```typescript
      priority_level: ["low", "medium", "high", "urgent"],
```

**L12802**
```typescript
      scraping_job_status: [
```

**L12803**
```typescript
        "queued",
```

**L12804**
```typescript
        "running",
```

**L12805**
```typescript
        "completed",
```

**L12806**
```typescript
        "failed",
```

**L12807**
```typescript
        "cancelled",
```

**L12808**
```typescript
        "rate_limited",
```

**L12809**
```typescript
      ],
```

**L12810**
```typescript
      scraping_source_type: [
```

**L12811**
```typescript
        "industry_directory",
```

**L12812**
```typescript
        "public_disclosure",
```

**L12813**
```typescript
        "company_website",
```

**L12814**
```typescript
        "gleif_lei",
```

**L12815**
```typescript
        "sec_edgar",
```

**L12816**
```typescript
        "dart_kr",
```

**L12817**
```typescript
        "press_release",
```

**L12818**
```typescript
        "other",
```

**L12819**
```typescript
      ],
```

**L12820**
```typescript
      send_status: ["pending", "sent", "skipped", "bounced", "failed"],
```

**L12821**
```typescript
      strategy_status: ["draft", "active", "completed", "abandoned"],
```

**L12822**
```typescript
      strategy_type: ["immediate", "short_term", "long_term"],
```

**L12823**
```typescript
      supply_link_type: ["potential", "active", "historical"],
```

**L12824**
```typescript
      sync_operation: [
```

**L12825**
```typescript
        "pull",
```

**L12826**
```typescript
        "push",
```

**L12827**
```typescript
        "match_party",
```

**L12828**
```typescript
        "promote",
```

**L12829**
```typescript
        "conflict",
```

**L12830**
```typescript
        "error",
```

**L12831**
```typescript
      ],
```

**L12832**
```typescript
      task_status: ["todo", "in_progress", "blocked", "done", "cancelled"],
```

**L12833**
```typescript
      template_status: ["draft", "active", "archived", "deprecated"],
```

**L12834**
```typescript
      tier_level: ["tier_1", "tier_2", "tier_3", "tier_4", "tier_5"],
```

**L12835**
```typescript
    },
```

**L12836**
```typescript
  },
```

**L12837**
```typescript
  public: {
```

**L12838**
```typescript
    Enums: {
```

**L12839**
```typescript
      tier_role: ["HQ", "Regional", "Country", "Plant"],
```

**L12840**
```typescript
    },
```

**L12841**
```typescript
  },
```

**L12842**
```typescript
  urm: {
```

**L12843**
```typescript
    Enums: {},
```

**L12844**
```typescript
  },
```

**L12845**
```typescript
} as const
```

### `src\types\draft-detail.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/draft-detail.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * AI 초안 상세·편집 화면의 데이터 모델.
```

**L5**
```typescript
 * 큐 행(DraftQueueRow)보다 훨씬 풍부 — 본문 전체, AI 런 메타, 게이트 평가, 거래처 등.
```

**L6**
```typescript
 */
```

**L7**
```typescript

```

**L8**
```typescript
import type {
```

**L9**
```typescript
  ClassificationCategory,
```

**L10**
```typescript
  DraftStatus,
```

**L11**
```typescript
  Language,
```

**L12**
```typescript
  PartyTypeCode,
```

**L13**
```typescript
} from './ai';
```

**L14**
```typescript

```

**L15**
```typescript
/** AI 런 메타 (분류기·회신가 각각). */
```

**L16**
```typescript
export interface DraftRunSummary {
```

**L17**
```typescript
  id: string;
```

**L18**
```typescript
  modelUsed: string;
```

**L19**
```typescript
  inputTokens: number | null;
```

**L20**
```typescript
  outputTokens: number | null;
```

**L21**
```typescript
  costUsd: number;
```

**L22**
```typescript
  latencyMs: number | null;
```

**L23**
```typescript
  status: string;
```

**L24**
```typescript
  startedAt: string;
```

**L25**
```typescript
  completedAt: string | null;
```

**L26**
```typescript
  /** ai.runs.metadata 안의 trace_label, retry_count 등 */
```

**L27**
```typescript
  metadata: Record<string, unknown>;
```

**L28**
```typescript
}
```

**L29**
```typescript

```

**L30**
```typescript
/** 원본 인바운드 메일. */
```

**L31**
```typescript
export interface DraftInboundSummary {
```

**L32**
```typescript
  id: string;
```

**L33**
```typescript
  fromAddress: string | null;
```

**L34**
```typescript
  fromName: string | null;
```

**L35**
```typescript
  toAddresses: string[];
```

**L36**
```typescript
  ccAddresses: string[];
```

**L37**
```typescript
  subject: string | null;
```

**L38**
```typescript
  bodyPlain: string | null;
```

**L39**
```typescript
  bodyHtml: string | null;
```

**L40**
```typescript
  occurredAt: string;
```

**L41**
```typescript
  messageId: string | null;
```

**L42**
```typescript
  threadId: string | null;
```

**L43**
```typescript
  inReplyTo: string | null;
```

**L44**
```typescript
  channel: string;
```

**L45**
```typescript
}
```

**L46**
```typescript

```

**L47**
```typescript
/** 거래처 요약. */
```

**L48**
```typescript
export interface DraftPartySummary {
```

**L49**
```typescript
  id: string;
```

**L50**
```typescript
  name: string;
```

**L51**
```typescript
  partyType: PartyTypeCode;
```

**L52**
```typescript
  tier: string | null;
```

**L53**
```typescript
  countryCode: string | null;
```

**L54**
```typescript
  website: string | null;
```

**L55**
```typescript
}
```

**L56**
```typescript

```

**L57**
```typescript
/** 인게이지먼트 요약. */
```

**L58**
```typescript
export interface DraftEngagementSummary {
```

**L59**
```typescript
  id: string;
```

**L60**
```typescript
  name: string;
```

**L61**
```typescript
  partyType: PartyTypeCode;
```

**L62**
```typescript
  status: string;
```

**L63**
```typescript
  valueAmount: number | null;
```

**L64**
```typescript
  valueCurrency: string;
```

**L65**
```typescript
}
```

**L66**
```typescript

```

**L67**
```typescript
/** 자동발송 규칙 + 평가 로그. */
```

**L68**
```typescript
export interface DraftAutoSendInfo {
```

**L69**
```typescript
  eligible: boolean;
```

**L70**
```typescript
  blockedReasons: string[];
```

**L71**
```typescript
  ruleId: string | null;
```

**L72**
```typescript
  /** 게이트가 적용한 카테고리·신뢰도 기준 (디버깅용) */
```

**L73**
```typescript
  evaluationLog: Record<string, unknown>;
```

**L74**
```typescript
  /** 규칙 자체의 활성 여부·키워드 등 */
```

**L75**
```typescript
  rule: {
```

**L76**
```typescript
    classificationCategory: string;
```

**L77**
```typescript
    minConfidence: number;
```

**L78**
```typescript
    requiresHumanApproval: boolean;
```

**L79**
```typescript
    isBlocked: boolean;
```

**L80**
```typescript
    blockReason: string | null;
```

**L81**
```typescript
    isActive: boolean;
```

**L82**
```typescript
  } | null;
```

**L83**
```typescript
}
```

**L84**
```typescript

```

**L85**
```typescript
/** 상세 화면 데이터 한 묶음. */
```

**L86**
```typescript
export interface DraftDetail {
```

**L87**
```typescript
  id: string;
```

**L88**
```typescript
  organizationId: string;
```

**L89**
```typescript
  status: DraftStatus;
```

**L90**
```typescript
  partyType: PartyTypeCode | null;
```

**L91**
```typescript
  language: Language;
```

**L92**
```typescript

```

**L93**
```typescript
  // 분류 결과
```

**L94**
```typescript
  classificationCategory: ClassificationCategory | null;
```

**L95**
```typescript
  confidenceScore: number | null;
```

**L96**
```typescript
  riskFlags: string[];
```

**L97**
```typescript
  requiresHumanApproval: boolean;
```

**L98**
```typescript
  rationale: string | null;
```

**L99**
```typescript

```

**L100**
```typescript
  // 본문 (원본 vs 편집본)
```

**L101**
```typescript
  subject: string | null;
```

**L102**
```typescript
  bodyPlain: string;
```

**L103**
```typescript
  bodyHtml: string | null;
```

**L104**
```typescript
  finalSubject: string | null;
```

**L105**
```typescript
  finalBodyPlain: string | null;
```

**L106**
```typescript
  editDistance: number | null;
```

**L107**
```typescript

```

**L108**
```typescript
  // 검토 정보
```

**L109**
```typescript
  reviewedByUserId: string | null;
```

**L110**
```typescript
  reviewedAt: string | null;
```

**L111**
```typescript
  reviewNotes: string | null;
```

**L112**
```typescript

```

**L113**
```typescript
  // 만료
```

**L114**
```typescript
  expiresAt: string;
```

**L115**
```typescript
  expiredHandled: boolean;
```

**L116**
```typescript

```

**L117**
```typescript
  // 발송 결과 (status='sent'일 때)
```

**L118**
```typescript
  sentCommunicationId: string | null;
```

**L119**
```typescript

```

**L120**
```typescript
  aiGenerated: boolean;
```

**L121**
```typescript
  createdAt: string;
```

**L122**
```typescript
  updatedAt: string;
```

**L123**
```typescript

```

**L124**
```typescript
  // 조인된 객체
```

**L125**
```typescript
  inbound: DraftInboundSummary | null;
```

**L126**
```typescript
  party: DraftPartySummary | null;
```

**L127**
```typescript
  engagement: DraftEngagementSummary | null;
```

**L128**
```typescript
  classifierRun: DraftRunSummary | null;
```

**L129**
```typescript
  drafterRun: DraftRunSummary | null;
```

**L130**
```typescript
  autoSend: DraftAutoSendInfo;
```

**L131**
```typescript
}
```

**L132**
```typescript

```

**L133**
```typescript
/** 거부 사유 — 4 preset + 'other' (free text는 notes 필드에). */
```

**L134**
```typescript
export type RejectReason =
```

**L135**
```typescript
  | 'outdated_request'
```

**L136**
```typescript
  | 'off_topic'
```

**L137**
```typescript
  | 'wrong_tone'
```

**L138**
```typescript
  | 'incorrect_info'
```

**L139**
```typescript
  | 'other';
```

**L140**
```typescript

```

**L141**
```typescript
export const REJECT_REASONS: readonly RejectReason[] = [
```

**L142**
```typescript
  'outdated_request',
```

**L143**
```typescript
  'off_topic',
```

**L144**
```typescript
  'wrong_tone',
```

**L145**
```typescript
  'incorrect_info',
```

**L146**
```typescript
  'other',
```

**L147**
```typescript
] as const;
```

### `src\types\draft-queue.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/draft-queue.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * AI 초안 큐 목록 화면용 타입.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * DraftQueueRow는 ai.drafts + parties(name) + contacts(full_name) +
```

**L7**
```typescript
 * inbound communications(from_address, subject) 조인 결과를 평탄화한 형태.
```

**L8**
```typescript
 */
```

**L9**
```typescript

```

**L10**
```typescript
import type {
```

**L11**
```typescript
  ClassificationCategory,
```

**L12**
```typescript
  DraftStatus,
```

**L13**
```typescript
  Language,
```

**L14**
```typescript
  PartyTypeCode,
```

**L15**
```typescript
} from './ai';
```

**L16**
```typescript

```

**L17**
```typescript
/**
```

**L18**
```typescript
 * 큐 목록의 한 행. 큐 화면에서만 사용하는 좁은 SELECT 결과.
```

**L19**
```typescript
 */
```

**L20**
```typescript
export interface DraftQueueRow {
```

**L21**
```typescript
  id: string;
```

**L22**
```typescript
  status: DraftStatus;
```

**L23**
```typescript
  partyType: PartyTypeCode | null;
```

**L24**
```typescript
  classificationCategory: ClassificationCategory | null;
```

**L25**
```typescript
  confidenceScore: number | null;
```

**L26**
```typescript
  language: Language;
```

**L27**
```typescript
  subject: string | null;
```

**L28**
```typescript
  bodyPlainPreview: string;  // body_plain의 첫 120자
```

**L29**
```typescript
  riskFlags: string[];
```

**L30**
```typescript
  requiresHumanApproval: boolean;
```

**L31**
```typescript
  autoSendEligible: boolean;
```

**L32**
```typescript
  /** 사용자가 final_body_plain을 입력했는지 (편집 중 판단). 일괄 승인에서 제외. */
```

**L33**
```typescript
  hasEdits: boolean;
```

**L34**
```typescript
  expiresAt: string;  // ISO 8601
```

**L35**
```typescript
  createdAt: string;
```

**L36**
```typescript
  /** 거래처 정보 (null이면 미지정 — 첫 콜드 컨택 등) */
```

**L37**
```typescript
  partyId: string | null;
```

**L38**
```typescript
  partyName: string | null;
```

**L39**
```typescript
  /** 발신자 (party 없을 때 fallback) */
```

**L40**
```typescript
  fromAddress: string | null;
```

**L41**
```typescript
  /** 원본 inbound 메일 제목 */
```

**L42**
```typescript
  inboundSubject: string | null;
```

**L43**
```typescript
  /** 인게이지먼트 (있으면) */
```

**L44**
```typescript
  engagementId: string | null;
```

**L45**
```typescript
  engagementName: string | null;
```

**L46**
```typescript
}
```

**L47**
```typescript

```

**L48**
```typescript
/**
```

**L49**
```typescript
 * 큐 필터. URL query string으로 전달되어 Server Component에서 파싱.
```

**L50**
```typescript
 */
```

**L51**
```typescript
export interface DraftQueueFilters {
```

**L52**
```typescript
  /** 상태 — 기본 'pending_review'. 'all'은 모든 상태 */
```

**L53**
```typescript
  status: DraftStatus | 'all';
```

**L54**
```typescript
  partyType: PartyTypeCode | 'all';
```

**L55**
```typescript
  category: ClassificationCategory | 'all';
```

**L56**
```typescript
  /** 최소 신뢰도 (0~1). 0이면 필터 없음 */
```

**L57**
```typescript
  minConfidence: number;
```

**L58**
```typescript
  /** 위험 표시 있는 것만 */
```

**L59**
```typescript
  onlyRisky: boolean;
```

**L60**
```typescript
}
```

**L61**
```typescript

```

**L62**
```typescript
/**
```

**L63**
```typescript
 * 큐 정렬 옵션.
```

**L64**
```typescript
 */
```

**L65**
```typescript
export type DraftQueueSort =
```

**L66**
```typescript
  | 'urgent'           // confidence ASC, expires_at ASC (기본)
```

**L67**
```typescript
  | 'newest'           // created_at DESC
```

**L68**
```typescript
  | 'oldest'           // created_at ASC
```

**L69**
```typescript
  | 'confidence_high'  // confidence DESC
```

**L70**
```typescript
  | 'expiring_soon';   // expires_at ASC
```

**L71**
```typescript

```

**L72**
```typescript
/**
```

**L73**
```typescript
 * 페이지네이션.
```

**L74**
```typescript
 */
```

**L75**
```typescript
export interface DraftQueuePagination {
```

**L76**
```typescript
  page: number;        // 1-indexed
```

**L77**
```typescript
  pageSize: number;    // 20 / 50 / 100
```

**L78**
```typescript
}
```

**L79**
```typescript

```

**L80**
```typescript
/**
```

**L81**
```typescript
 * 큐 쿼리 결과 — 행 + 전체 카운트(페이지네이션 표시용).
```

**L82**
```typescript
 */
```

**L83**
```typescript
export interface DraftQueueResult {
```

**L84**
```typescript
  rows: DraftQueueRow[];
```

**L85**
```typescript
  totalCount: number;
```

**L86**
```typescript
  filters: DraftQueueFilters;
```

**L87**
```typescript
  sort: DraftQueueSort;
```

**L88**
```typescript
  pagination: DraftQueuePagination;
```

**L89**
```typescript
}
```

**L90**
```typescript

```

**L91**
```typescript
/* ============================================================
```

**L92**
```typescript
 * 기본값
```

**L93**
```typescript
 * ============================================================ */
```

**L94**
```typescript

```

**L95**
```typescript
export const DEFAULT_FILTERS: DraftQueueFilters = {
```

**L96**
```typescript
  status: 'pending_review',
```

**L97**
```typescript
  partyType: 'all',
```

**L98**
```typescript
  category: 'all',
```

**L99**
```typescript
  minConfidence: 0,
```

**L100**
```typescript
  onlyRisky: false,
```

**L101**
```typescript
};
```

**L102**
```typescript

```

**L103**
```typescript
export const DEFAULT_SORT: DraftQueueSort = 'urgent';
```

**L104**
```typescript

```

**L105**
```typescript
export const DEFAULT_PAGE_SIZE = 20;
```

**L106**
```typescript
export const PAGE_SIZE_OPTIONS: readonly number[] = [20, 50, 100] as const;
```

### `src\types\email.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/email.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 이메일 통신 도메인 객체 타입.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * 다루는 영역:
```

**L7**
```typescript
 *   - app.communications 행 (CommunicationRow)
```

**L8**
```typescript
 *   - app.attachments 행 (AttachmentRow)
```

**L9**
```typescript
 *   - 수신 메일 파싱 결과 (ParsedHeaders, ParsedInbound)
```

**L10**
```typescript
 *   - URM 자체 헤더 (UrmHeaders, X-URM-* 4종)
```

**L11**
```typescript
 *   - 발송 입력 (SendOneInput, CampaignParams)
```

**L12**
```typescript
 *   - 발송 통계 (TabsCampaignStats)
```

**L13**
```typescript
 *   - 대량발송 잡 (MailMergeJobRow, QuietHours)
```

**L14**
```typescript
 *   - 스레드 매칭 결과
```

**L15**
```typescript
 */
```

**L16**
```typescript

```

**L17**
```typescript
import type { PartyTypeCode, Language } from './ai';
```

**L18**
```typescript

```

**L19**
```typescript
/* ============================================================
```

**L20**
```typescript
 * 1. 채널·방향 enum
```

**L21**
```typescript
 * ============================================================ */
```

**L22**
```typescript

```

**L23**
```typescript
export type Direction = 'inbound' | 'outbound';
```

**L24**
```typescript
export type Channel = 'email' | 'phone' | 'meeting' | 'note' | 'chat' | 'social' | 'linkedin';
```

**L25**
```typescript

```

**L26**
```typescript
/** communications.status (DB CHECK 제약과 일치). */
```

**L27**
```typescript
export type CommunicationStatus =
```

**L28**
```typescript
  | 'draft'
```

**L29**
```typescript
  | 'queued'
```

**L30**
```typescript
  | 'sending'
```

**L31**
```typescript
  | 'sent'
```

**L32**
```typescript
  | 'delivered'
```

**L33**
```typescript
  | 'bounced'
```

**L34**
```typescript
  | 'failed'
```

**L35**
```typescript
  | 'received'
```

**L36**
```typescript
  | 'archived';
```

**L37**
```typescript

```

**L38**
```typescript
export type AiProcessingStatus =
```

**L39**
```typescript
  | 'pending'
```

**L40**
```typescript
  | 'processing'
```

**L41**
```typescript
  | 'completed'
```

**L42**
```typescript
  | 'failed'
```

**L43**
```typescript
  | 'skipped';
```

**L44**
```typescript

```

**L45**
```typescript
/* ============================================================
```

**L46**
```typescript
 * 2. URM 자체 헤더 (X-URM-*)
```

**L47**
```typescript
 * ----------------------------------------------------------
```

**L48**
```typescript
 * 발송 시 부착, 수신 시 회수해 thread 매칭 1순위로 사용.
```

**L49**
```typescript
 * TABS Mailer 4가 헤더를 통과시키지 않을 가능성 대비
```

**L50**
```typescript
 * Message-ID·In-Reply-To 기반 fallback 제공 (mailcarrier 모듈).
```

**L51**
```typescript
 * ============================================================ */
```

**L52**
```typescript
export interface UrmHeaders {
```

**L53**
```typescript
  /** 인게이지먼트 UUID. 스레드·수신 매칭 1순위. */
```

**L54**
```typescript
  engagementId?: string;
```

**L55**
```typescript
  /** 발신 communications 행 UUID. 회신 시 thread 1:1 매칭. */
```

**L56**
```typescript
  communicationId?: string;
```

**L57**
```typescript
  /** 자동발송 게이트 통과 여부(true/false). */
```

**L58**
```typescript
  autoSend?: boolean;
```

**L59**
```typescript
  /** 사용된 brand_voice 행 UUID(학습 루프용). */
```

**L60**
```typescript
  brandVoiceId?: string;
```

**L61**
```typescript
}
```

**L62**
```typescript

```

**L63**
```typescript
/** X-URM-* 헤더 이름 상수 (대소문자 비교 시 항상 lowercase 사용). */
```

**L64**
```typescript
export const URM_HEADER_NAMES = {
```

**L65**
```typescript
  engagementId: 'x-urm-engagement-id',
```

**L66**
```typescript
  communicationId: 'x-urm-communication-id',
```

**L67**
```typescript
  autoSend: 'x-urm-auto-send',
```

**L68**
```typescript
  brandVoiceId: 'x-urm-brand-voice-id',
```

**L69**
```typescript
} as const;
```

**L70**
```typescript

```

**L71**
```typescript
/* ============================================================
```

**L72**
```typescript
 * 3. 첨부파일 입출력
```

**L73**
```typescript
 * ============================================================ */
```

**L74**
```typescript

```

**L75**
```typescript
export interface AttachmentInput {
```

**L76**
```typescript
  filename: string;
```

**L77**
```typescript
  content: Buffer;
```

**L78**
```typescript
  contentType?: string;
```

**L79**
```typescript
}
```

**L80**
```typescript

```

**L81**
```typescript
export interface AttachmentRow {
```

**L82**
```typescript
  id: string;
```

**L83**
```typescript
  organizationId: string;
```

**L84**
```typescript
  entityType: 'communication' | 'meeting' | 'task' | 'party' | 'engagement' | 'consultation';
```

**L85**
```typescript
  entityId: string;
```

**L86**
```typescript
  fileName: string;
```

**L87**
```typescript
  fileSizeBytes: number;
```

**L88**
```typescript
  mimeType: string;
```

**L89**
```typescript
  storageProvider: 'supabase' | 's3' | 'external_url';
```

**L90**
```typescript
  storageBucket?: string;
```

**L91**
```typescript
  storagePath: string;
```

**L92**
```typescript
  contentHashSha256?: string;
```

**L93**
```typescript
  isInline: boolean;
```

**L94**
```typescript
  isQuarantined: boolean;
```

**L95**
```typescript
  virusScanStatus?: 'pending' | 'clean' | 'infected' | 'skipped' | 'failed';
```

**L96**
```typescript
  description?: string;
```

**L97**
```typescript
  uploadedBy?: string;
```

**L98**
```typescript
  uploadedAt: string;
```

**L99**
```typescript
  expiresAt?: string;
```

**L100**
```typescript
}
```

**L101**
```typescript

```

**L102**
```typescript
/* ============================================================
```

**L103**
```typescript
 * 4. communications 행 (camelCase 도메인 객체)
```

**L104**
```typescript
 * ============================================================ */
```

**L105**
```typescript

```

**L106**
```typescript
export interface CommunicationRow {
```

**L107**
```typescript
  id: string;
```

**L108**
```typescript
  organizationId: string;
```

**L109**
```typescript
  partyId?: string;
```

**L110**
```typescript
  contactId?: string;
```

**L111**
```typescript
  engagementId?: string;
```

**L112**
```typescript
  partyType?: PartyTypeCode;
```

**L113**
```typescript
  channel: Channel;
```

**L114**
```typescript
  direction: Direction;
```

**L115**
```typescript
  // RFC 5322
```

**L116**
```typescript
  messageId?: string;
```

**L117**
```typescript
  inReplyTo?: string;
```

**L118**
```typescript
  threadId?: string;
```

**L119**
```typescript
  // 발신·수신
```

**L120**
```typescript
  fromAddress?: string;
```

**L121**
```typescript
  fromName?: string;
```

**L122**
```typescript
  toAddresses: string[];
```

**L123**
```typescript
  ccAddresses: string[];
```

**L124**
```typescript
  bccAddresses: string[];
```

**L125**
```typescript
  replyToAddress?: string;
```

**L126**
```typescript
  // 본문
```

**L127**
```typescript
  subject?: string;
```

**L128**
```typescript
  bodyHtml?: string;
```

**L129**
```typescript
  bodyPlain?: string;
```

**L130**
```typescript
  bodySummary?: string;
```

**L131**
```typescript
  // 언어
```

**L132**
```typescript
  languageDetected?: 'ko' | 'en' | 'ja' | 'zh-CN' | 'other';
```

**L133**
```typescript
  // 상태
```

**L134**
```typescript
  status: CommunicationStatus;
```

**L135**
```typescript
  // 타임스탬프
```

**L136**
```typescript
  occurredAt: string;
```

**L137**
```typescript
  sentAt?: string;
```

**L138**
```typescript
  deliveredAt?: string;
```

**L139**
```typescript
  receivedAt?: string;
```

**L140**
```typescript
  openedAt?: string;
```

**L141**
```typescript
  clickedAt?: string;
```

**L142**
```typescript
  repliedAt?: string;
```

**L143**
```typescript
  bouncedAt?: string;
```

**L144**
```typescript
  bounceReason?: string;
```

**L145**
```typescript
  // AI
```

**L146**
```typescript
  aiClassification?: Record<string, unknown>;
```

**L147**
```typescript
  aiDraftId?: string;
```

**L148**
```typescript
  aiGenerated: boolean;
```

**L149**
```typescript
  aiProcessingStatus?: AiProcessingStatus;
```

**L150**
```typescript
  // 템플릿
```

**L151**
```typescript
  templateId?: string;
```

**L152**
```typescript
  templateVariables?: Record<string, unknown>;
```

**L153**
```typescript
  // 외부
```

**L154**
```typescript
  externalData: Record<string, unknown>;
```

**L155**
```typescript
  // 메타
```

**L156**
```typescript
  sentByUserId?: string;
```

**L157**
```typescript
  isStarred: boolean;
```

**L158**
```typescript
  isImportant: boolean;
```

**L159**
```typescript
  notes?: string;
```

**L160**
```typescript
}
```

**L161**
```typescript

```

**L162**
```typescript
/* ============================================================
```

**L163**
```typescript
 * 5. 수신 메일 파싱 결과
```

**L164**
```typescript
 * ============================================================ */
```

**L165**
```typescript

```

**L166**
```typescript
/** mailparser ParsedMail에서 추출한 우리 도메인 헤더. */
```

**L167**
```typescript
export interface ParsedHeaders {
```

**L168**
```typescript
  messageId: string;
```

**L169**
```typescript
  inReplyTo?: string;
```

**L170**
```typescript
  references: string[];
```

**L171**
```typescript
  from: { name?: string; address: string };
```

**L172**
```typescript
  to: Array<{ name?: string; address: string }>;
```

**L173**
```typescript
  cc?: Array<{ name?: string; address: string }>;
```

**L174**
```typescript
  replyTo?: string;
```

**L175**
```typescript
  subject: string;
```

**L176**
```typescript
  date: Date;
```

**L177**
```typescript
  urmHeaders: UrmHeaders;
```

**L178**
```typescript
  /** 원본 헤더 일부 (디버깅·재처리용). */
```

**L179**
```typescript
  rawSelectedHeaders?: Record<string, string>;
```

**L180**
```typescript
}
```

**L181**
```typescript

```

**L182**
```typescript
/** mailcarrier가 communications INSERT 후 processor.ts에 전달하는 메시지. */
```

**L183**
```typescript
export interface InboundMessageEvent {
```

**L184**
```typescript
  communicationId: string;
```

**L185**
```typescript
  organizationId: string;
```

**L186**
```typescript
  threadId: string;
```

**L187**
```typescript
  messageId: string;
```

**L188**
```typescript
  /** 사전 마스킹된 본문(processor가 다시 마스킹할 필요 없게). */
```

**L189**
```typescript
  bodyText: string;
```

**L190**
```typescript
  /** 마스킹된 PII 카테고리(통계용). */
```

**L191**
```typescript
  piiCategories: string[];
```

**L192**
```typescript
  /** ParsedHeaders 일부 발췌 (party 매칭용). */
```

**L193**
```typescript
  fromAddress: string;
```

**L194**
```typescript
}
```

**L195**
```typescript

```

**L196**
```typescript
/* ============================================================
```

**L197**
```typescript
 * 6. 발송 입력
```

**L198**
```typescript
 * ============================================================ */
```

**L199**
```typescript

```

**L200**
```typescript
export interface MailRecipient {
```

**L201**
```typescript
  name?: string;
```

**L202**
```typescript
  address: string;
```

**L203**
```typescript
}
```

**L204**
```typescript

```

**L205**
```typescript
/**
```

**L206**
```typescript
 * 발신 주소 종류. 사용자가 회신 시 선택.
```

**L207**
```typescript
 * - personal: 개인 메일 (예: yunyoung.heo@marinebiogroup.com)
```

**L208**
```typescript
 * - role:     직책 메일 (예: ceo@marinebiogroup.com)
```

**L209**
```typescript
 * - shared:   공통/팀 메일 (예: contact@marinebiogroup.com)
```

**L210**
```typescript
 */
```

**L211**
```typescript
export type SendingAddressKind = 'personal' | 'role' | 'shared';
```

**L212**
```typescript

```

**L213**
```typescript
export interface SendOneInput {
```

**L214**
```typescript
  to: MailRecipient;
```

**L215**
```typescript
  cc?: MailRecipient[];
```

**L216**
```typescript
  bcc?: MailRecipient[];
```

**L217**
```typescript
  fromName: string;
```

**L218**
```typescript
  fromAddress: string;
```

**L219**
```typescript
  replyTo?: string;
```

**L220**
```typescript
  subject: string;
```

**L221**
```typescript
  bodyText: string;
```

**L222**
```typescript
  bodyHtml?: string;
```

**L223**
```typescript
  /** 부착할 X-URM-* 헤더. communicationId만 필수. */
```

**L224**
```typescript
  urmHeaders: Required<Pick<UrmHeaders, 'communicationId'>> &
```

**L225**
```typescript
    Omit<UrmHeaders, 'communicationId'> & { autoSend: boolean };
```

**L226**
```typescript
  attachments?: AttachmentInput[];
```

**L227**
```typescript
  /** quiet hours 검증 우회(테스트·운영자 수동 발송용). */
```

**L228**
```typescript
  bypassQuietHours?: boolean;
```

**L229**
```typescript
  /** 적용할 quiet hours(미지정 시 검증 안 함). */
```

**L230**
```typescript
  quietHours?: QuietHours;
```

**L231**
```typescript
  /** 추적용 라벨(로그·ai.runs trace_label). */
```

**L232**
```typescript
  traceLabel?: string;
```

**L233**
```typescript
  /** 사용할 SMTP 자격증명 종류. 미지정 시 기존 단일 transporter 사용(하위호환). */
```

**L234**
```typescript
  sendingAddressKind?: SendingAddressKind;
```

**L235**
```typescript
}
```

**L236**
```typescript

```

**L237**
```typescript
export interface SendOneOutput {
```

**L238**
```typescript
  /** RFC 5322 Message-ID. */
```

**L239**
```typescript
  messageId: string;
```

**L240**
```typescript
  acceptedRecipients: string[];
```

**L241**
```typescript
  rejectedRecipients: string[];
```

**L242**
```typescript
  rawResponse: string;
```

**L243**
```typescript
  /** 발송 시각(서버 응답 시각). */
```

**L244**
```typescript
  sentAt: string;
```

**L245**
```typescript
}
```

**L246**
```typescript

```

**L247**
```typescript
/* ============================================================
```

**L248**
```typescript
 * 7. 캠페인 (대량발송)
```

**L249**
```typescript
 * ============================================================ */
```

**L250**
```typescript

```

**L251**
```typescript
export interface CampaignParams {
```

**L252**
```typescript
  name: string;
```

**L253**
```typescript
  description?: string;
```

**L254**
```typescript
  templateId: string;
```

**L255**
```typescript
  scheduledAt?: Date;
```

**L256**
```typescript
  recipientCount: number;
```

**L257**
```typescript
  fromAddress: string;
```

**L258**
```typescript
  fromName?: string;
```

**L259**
```typescript
  replyToAddress?: string;
```

**L260**
```typescript
}
```

**L261**
```typescript

```

**L262**
```typescript
export interface CampaignCreateResult {
```

**L263**
```typescript
  tabsCampaignId: string;
```

**L264**
```typescript
  status: string;
```

**L265**
```typescript
}
```

**L266**
```typescript

```

**L267**
```typescript
export interface TabsCampaignStats {
```

**L268**
```typescript
  tabsCampaignId: string;
```

**L269**
```typescript
  totalSent: number;
```

**L270**
```typescript
  totalDelivered: number;
```

**L271**
```typescript
  totalOpened: number;
```

**L272**
```typescript
  totalClicked: number;
```

**L273**
```typescript
  totalBounced: number;
```

**L274**
```typescript
  totalUnsubscribed: number;
```

**L275**
```typescript
  totalFailed: number;
```

**L276**
```typescript
  totalReplied: number;
```

**L277**
```typescript
  lastUpdatedAt: Date;
```

**L278**
```typescript
}
```

**L279**
```typescript

```

**L280**
```typescript
/* ============================================================
```

**L281**
```typescript
 * 8. Quiet hours
```

**L282**
```typescript
 * ============================================================ */
```

**L283**
```typescript

```

**L284**
```typescript
export interface QuietHours {
```

**L285**
```typescript
  /** IANA 타임존 (예: "Asia/Seoul", "America/New_York"). */
```

**L286**
```typescript
  timezone: string;
```

**L287**
```typescript
  /** "HH:mm" 24h. 자정을 넘는 경우(22:00 → 08:00) 지원. */
```

**L288**
```typescript
  start: string;
```

**L289**
```typescript
  /** "HH:mm" 24h. */
```

**L290**
```typescript
  end: string;
```

**L291**
```typescript
  /** 토·일 차단 여부. */
```

**L292**
```typescript
  weekends_blocked: boolean;
```

**L293**
```typescript
}
```

**L294**
```typescript

```

**L295**
```typescript
/* ============================================================
```

**L296**
```typescript
 * 9. mail_merge_jobs 행
```

**L297**
```typescript
 * ============================================================ */
```

**L298**
```typescript

```

**L299**
```typescript
export type MailMergeJobStatus =
```

**L300**
```typescript
  | 'draft'
```

**L301**
```typescript
  | 'queued'
```

**L302**
```typescript
  | 'running'
```

**L303**
```typescript
  | 'paused'
```

**L304**
```typescript
  | 'completed'
```

**L305**
```typescript
  | 'cancelled'
```

**L306**
```typescript
  | 'failed';
```

**L307**
```typescript

```

**L308**
```typescript
export interface MailMergeProgress {
```

**L309**
```typescript
  sent: number;
```

**L310**
```typescript
  failed: number;
```

**L311**
```typescript
  opened: number;
```

**L312**
```typescript
  clicked: number;
```

**L313**
```typescript
  replied: number;
```

**L314**
```typescript
  bounced: number;
```

**L315**
```typescript
  unsubscribed?: number;
```

**L316**
```typescript
}
```

**L317**
```typescript

```

**L318**
```typescript
export interface MailMergeJobRow {
```

**L319**
```typescript
  id: string;
```

**L320**
```typescript
  organizationId: string;
```

**L321**
```typescript
  name: string;
```

**L322**
```typescript
  description?: string;
```

**L323**
```typescript
  templateId: string;
```

**L324**
```typescript
  templateVersionId?: string;
```

**L325**
```typescript
  abTestId?: string;
```

**L326**
```typescript
  recipientFilter: Record<string, unknown>;
```

**L327**
```typescript
  recipientPartyIds: string[];
```

**L328**
```typescript
  recipientContactIds: string[];
```

**L329**
```typescript
  estimatedRecipientCount?: number;
```

**L330**
```typescript
  fromAddress: string;
```

**L331**
```typescript
  fromName?: string;
```

**L332**
```typescript
  replyToAddress?: string;
```

**L333**
```typescript
  scheduledAt?: string;
```

**L334**
```typescript
  rateLimitPerHour: number;
```

**L335**
```typescript
  rateLimitPerMinute: number;
```

**L336**
```typescript
  quietHours: QuietHours;
```

**L337**
```typescript
  tabsCampaignId?: string;
```

**L338**
```typescript
  tabsCampaignStatus?: string;
```

**L339**
```typescript
  tabsCampaignSyncedAt?: string;
```

**L340**
```typescript
  status: MailMergeJobStatus;
```

**L341**
```typescript
  progress: MailMergeProgress;
```

**L342**
```typescript
  startedAt?: string;
```

**L343**
```typescript
  completedAt?: string;
```

**L344**
```typescript
  errorMessage?: string;
```

**L345**
```typescript
  /** 워커가 재시도 백오프를 적용할 다음 시각. */
```

**L346**
```typescript
  nextSendAt?: string;
```

**L347**
```typescript
  retryCount: number;
```

**L348**
```typescript
  maxRetries: number;
```

**L349**
```typescript
  requiresLegalApproval: boolean;
```

**L350**
```typescript
  legalApprovedAt?: string;
```

**L351**
```typescript
  legalApprovedBy?: string;
```

**L352**
```typescript
}
```

**L353**
```typescript

```

**L354**
```typescript
/* ============================================================
```

**L355**
```typescript
 * 10. DB row → 도메인 객체 매퍼 (mail_merge_jobs)
```

**L356**
```typescript
 * ============================================================ */
```

**L357**
```typescript

```

**L358**
```typescript
export function mapMailMergeJobRow(row: Record<string, unknown>): MailMergeJobRow {
```

**L359**
```typescript
  const progress = (row.progress ?? {}) as Record<string, unknown>;
```

**L360**
```typescript
  const quietHoursRaw = (row.quiet_hours ?? {}) as Record<string, unknown>;
```

**L361**
```typescript

```

**L362**
```typescript
  return {
```

**L363**
```typescript
    id: row.id as string,
```

**L364**
```typescript
    organizationId: row.organization_id as string,
```

**L365**
```typescript
    name: row.name as string,
```

**L366**
```typescript
    description: (row.description as string | null) ?? undefined,
```

**L367**
```typescript
    templateId: row.template_id as string,
```

**L368**
```typescript
    templateVersionId: (row.template_version_id as string | null) ?? undefined,
```

**L369**
```typescript
    abTestId: (row.ab_test_id as string | null) ?? undefined,
```

**L370**
```typescript
    recipientFilter: (row.recipient_filter ?? {}) as Record<string, unknown>,
```

**L371**
```typescript
    recipientPartyIds: (row.recipient_party_ids ?? []) as string[],
```

**L372**
```typescript
    recipientContactIds: (row.recipient_contact_ids ?? []) as string[],
```

**L373**
```typescript
    estimatedRecipientCount:
```

**L374**
```typescript
      (row.estimated_recipient_count as number | null) ?? undefined,
```

**L375**
```typescript
    fromAddress: row.from_address as string,
```

**L376**
```typescript
    fromName: (row.from_name as string | null) ?? undefined,
```

**L377**
```typescript
    replyToAddress: (row.reply_to_address as string | null) ?? undefined,
```

**L378**
```typescript
    scheduledAt: (row.scheduled_at as string | null) ?? undefined,
```

**L379**
```typescript
    rateLimitPerHour: Number(row.rate_limit_per_hour ?? 100),
```

**L380**
```typescript
    rateLimitPerMinute: Number(row.rate_limit_per_minute ?? 5),
```

**L381**
```typescript
    quietHours: {
```

**L382**
```typescript
      timezone: String(quietHoursRaw.timezone ?? 'Asia/Seoul'),
```

**L383**
```typescript
      start: String(quietHoursRaw.start ?? '22:00'),
```

**L384**
```typescript
      end: String(quietHoursRaw.end ?? '08:00'),
```

**L385**
```typescript
      weekends_blocked: Boolean(quietHoursRaw.weekends_blocked ?? true),
```

**L386**
```typescript
    },
```

**L387**
```typescript
    tabsCampaignId: (row.tabs_campaign_id as string | null) ?? undefined,
```

**L388**
```typescript
    tabsCampaignStatus:
```

**L389**
```typescript
      (row.tabs_campaign_status as string | null) ?? undefined,
```

**L390**
```typescript
    tabsCampaignSyncedAt:
```

**L391**
```typescript
      (row.tabs_campaign_synced_at as string | null) ?? undefined,
```

**L392**
```typescript
    status: row.status as MailMergeJobStatus,
```

**L393**
```typescript
    progress: {
```

**L394**
```typescript
      sent: Number(progress.sent ?? 0),
```

**L395**
```typescript
      failed: Number(progress.failed ?? 0),
```

**L396**
```typescript
      opened: Number(progress.opened ?? 0),
```

**L397**
```typescript
      clicked: Number(progress.clicked ?? 0),
```

**L398**
```typescript
      replied: Number(progress.replied ?? 0),
```

**L399**
```typescript
      bounced: Number(progress.bounced ?? 0),
```

**L400**
```typescript
      unsubscribed:
```

**L401**
```typescript
        progress.unsubscribed !== undefined
```

**L402**
```typescript
          ? Number(progress.unsubscribed)
```

**L403**
```typescript
          : undefined,
```

**L404**
```typescript
    },
```

**L405**
```typescript
    startedAt: (row.started_at as string | null) ?? undefined,
```

**L406**
```typescript
    completedAt: (row.completed_at as string | null) ?? undefined,
```

**L407**
```typescript
    errorMessage: (row.error_message as string | null) ?? undefined,
```

**L408**
```typescript
    nextSendAt: (row.next_send_at as string | null) ?? undefined,
```

**L409**
```typescript
    retryCount: Number(row.retry_count ?? 0),
```

**L410**
```typescript
    maxRetries: Number(row.max_retries ?? 3),
```

**L411**
```typescript
    requiresLegalApproval: Boolean(row.requires_legal_approval ?? false),
```

**L412**
```typescript
    legalApprovedAt: (row.legal_approved_at as string | null) ?? undefined,
```

**L413**
```typescript
    legalApprovedBy: (row.legal_approved_by as string | null) ?? undefined,
```

**L414**
```typescript
  };
```

**L415**
```typescript
}
```

**L416**
```typescript

```

**L417**
```typescript
/* ============================================================
```

**L418**
```typescript
 * 11. 회신 언어 결정 헬퍼
```

**L419**
```typescript
 * ----------------------------------------------------------
```

**L420**
```typescript
 * 마스터 §8.2의 우선순위 규칙을 코드화.
```

**L421**
```typescript
 *   1. contacts.preferred_language
```

**L422**
```typescript
 *   2. communications.language_detected
```

**L423**
```typescript
 *   3. parties.country 기본 언어
```

**L424**
```typescript
 *   4. 조직 기본 언어
```

**L425**
```typescript
 * ============================================================ */
```

**L426**
```typescript
export function resolveReplyLanguage(input: {
```

**L427**
```typescript
  contactPreferred?: string;
```

**L428**
```typescript
  detectedFromInbound?: string;
```

**L429**
```typescript
  partyCountryCode?: string;
```

**L430**
```typescript
  organizationDefault?: Language;
```

**L431**
```typescript
}): Language {
```

**L432**
```typescript
  const contact = input.contactPreferred?.toLowerCase();
```

**L433**
```typescript
  if (contact === 'ko' || contact === 'en' || contact === 'ja') return contact;
```

**L434**
```typescript

```

**L435**
```typescript
  const detected = input.detectedFromInbound?.toLowerCase();
```

**L436**
```typescript
  if (detected === 'ko' || detected === 'en' || detected === 'ja') return detected;
```

**L437**
```typescript

```

**L438**
```typescript
  const country = (input.partyCountryCode ?? '').toUpperCase();
```

**L439**
```typescript
  if (country === 'KR') return 'ko';
```

**L440**
```typescript
  if (country === 'JP') return 'ja';
```

**L441**
```typescript
  if (country) return 'en'; // 그 외 국가는 영어로
```

**L442**
```typescript

```

**L443**
```typescript
  return input.organizationDefault ?? 'en';
```

**L444**
```typescript
}
```

### `src\types\engagement.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/engagement.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * Engagement(인게이지먼트, deals) 화면의 데이터 모델.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * Kanban 구조 (스키마 정규화):
```

**L7**
```typescript
 *   pipeline_definitions (모듈별 활성 파이프라인)
```

**L8**
```typescript
 *     └─ pipeline_stages   (stage 컬럼들)
```

**L9**
```typescript
 *         └─ engagements   (각 stage에 속한 카드들)
```

**L10**
```typescript
 */
```

**L11**
```typescript

```

**L12**
```typescript
import type { PartyTypeCode } from './ai';
```

**L13**
```typescript

```

**L14**
```typescript
/** app.engagement_status enum. */
```

**L15**
```typescript
export type EngagementStatus =
```

**L16**
```typescript
  | 'open'
```

**L17**
```typescript
  | 'in_progress'
```

**L18**
```typescript
  | 'on_hold'
```

**L19**
```typescript
  | 'won'
```

**L20**
```typescript
  | 'lost'
```

**L21**
```typescript
  | 'archived';
```

**L22**
```typescript

```

**L23**
```typescript
/** pipeline_stage_type — LEAN 분석용 공통 매핑. */
```

**L24**
```typescript
export type PipelineStageType =
```

**L25**
```typescript
  | 'lead'
```

**L26**
```typescript
  | 'qualified'
```

**L27**
```typescript
  | 'proposal'
```

**L28**
```typescript
  | 'negotiation'
```

**L29**
```typescript
  | 'closed_won'
```

**L30**
```typescript
  | 'closed_lost'
```

**L31**
```typescript
  | 'other';
```

**L32**
```typescript

```

**L33**
```typescript
/** Kanban 한 컬럼 = 한 pipeline_stage. */
```

**L34**
```typescript
export interface KanbanStage {
```

**L35**
```typescript
  id: string;
```

**L36**
```typescript
  pipelineDefinitionId: string;
```

**L37**
```typescript
  code: string;
```

**L38**
```typescript
  name: string;
```

**L39**
```typescript
  stageType: PipelineStageType;
```

**L40**
```typescript
  sortOrder: number;
```

**L41**
```typescript
  defaultProbabilityPct: number;
```

**L42**
```typescript
  isTerminal: boolean;
```

**L43**
```typescript
  isWon: boolean;
```

**L44**
```typescript
  isLost: boolean;
```

**L45**
```typescript
  colorHex: string | null;
```

**L46**
```typescript
}
```

**L47**
```typescript

```

**L48**
```typescript
/** Kanban 카드 = 한 engagement (목록용 평탄화). */
```

**L49**
```typescript
export interface KanbanCard {
```

**L50**
```typescript
  id: string;
```

**L51**
```typescript
  name: string;
```

**L52**
```typescript
  partyType: PartyTypeCode;
```

**L53**
```typescript
  status: EngagementStatus;
```

**L54**
```typescript
  currentStageId: string | null;
```

**L55**
```typescript
  pipelineDefinitionId: string | null;
```

**L56**
```typescript
  partyId: string;
```

**L57**
```typescript
  partyName: string;
```

**L58**
```typescript
  valueAmount: number | null;
```

**L59**
```typescript
  valueCurrency: string;
```

**L60**
```typescript
  probabilityPct: number;
```

**L61**
```typescript
  weightedAmount: number | null;
```

**L62**
```typescript
  expectedCloseDate: string | null;
```

**L63**
```typescript
  ownerUserId: string | null;
```

**L64**
```typescript
  updatedAt: string;
```

**L65**
```typescript
}
```

**L66**
```typescript

```

**L67**
```typescript
/** Kanban 보드 — 한 모듈의 default pipeline + stages + cards. */
```

**L68**
```typescript
export interface KanbanBoard {
```

**L69**
```typescript
  partyType: PartyTypeCode;
```

**L70**
```typescript
  /** module에 default pipeline이 없을 경우 null — 사용자에게 안내 표시 */
```

**L71**
```typescript
  pipelineDefinitionId: string | null;
```

**L72**
```typescript
  pipelineName: string | null;
```

**L73**
```typescript
  stages: KanbanStage[];
```

**L74**
```typescript
  /** stage_id → cards 그룹 매핑 */
```

**L75**
```typescript
  cardsByStage: Record<string, KanbanCard[]>;
```

**L76**
```typescript
  /** stage가 없거나 매핑 안 된 카드 — '미분류' 컬럼 */
```

**L77**
```typescript
  uncategorizedCards: KanbanCard[];
```

**L78**
```typescript
  /** 카운트 (UI 헤더 표시용) */
```

**L79**
```typescript
  totalCount: number;
```

**L80**
```typescript
}
```

**L81**
```typescript

```

**L82**
```typescript
/* ============================================================
```

**L83**
```typescript
 * Engagement Detail
```

**L84**
```typescript
 * ============================================================ */
```

**L85**
```typescript

```

**L86**
```typescript
export interface EngagementStageHistoryItem {
```

**L87**
```typescript
  id: string;
```

**L88**
```typescript
  fromStageId: string | null;
```

**L89**
```typescript
  fromStageName: string | null;
```

**L90**
```typescript
  toStageId: string | null;
```

**L91**
```typescript
  toStageName: string;
```

**L92**
```typescript
  movedAt: string;
```

**L93**
```typescript
  movedByUserId: string | null;
```

**L94**
```typescript
  durationSeconds: number | null;
```

**L95**
```typescript
  reason: string | null;
```

**L96**
```typescript
}
```

**L97**
```typescript

```

**L98**
```typescript
export interface EngagementDetail {
```

**L99**
```typescript
  id: string;
```

**L100**
```typescript
  organizationId: string;
```

**L101**
```typescript
  partyId: string;
```

**L102**
```typescript
  partyName: string;
```

**L103**
```typescript
  primaryContactId: string | null;
```

**L104**
```typescript
  primaryContactName: string | null;
```

**L105**
```typescript
  partyType: PartyTypeCode;
```

**L106**
```typescript
  name: string;
```

**L107**
```typescript
  description: string | null;
```

**L108**
```typescript
  pipelineDefinitionId: string | null;
```

**L109**
```typescript
  pipelineName: string | null;
```

**L110**
```typescript
  currentStageId: string | null;
```

**L111**
```typescript
  currentStageName: string | null;
```

**L112**
```typescript
  currentStageColor: string | null;
```

**L113**
```typescript
  status: EngagementStatus;
```

**L114**
```typescript
  valueAmount: number | null;
```

**L115**
```typescript
  valueCurrency: string;
```

**L116**
```typescript
  probabilityPct: number;
```

**L117**
```typescript
  weightedAmount: number | null;
```

**L118**
```typescript
  expectedCloseDate: string | null;
```

**L119**
```typescript
  actualCloseDate: string | null;
```

**L120**
```typescript
  ownerUserId: string | null;
```

**L121**
```typescript
  wonLostReason: string | null;
```

**L122**
```typescript
  source: string | null;
```

**L123**
```typescript
  createdAt: string;
```

**L124**
```typescript
  updatedAt: string;
```

**L125**
```typescript
  /** 이 인게이지먼트의 사용 가능 stages (드롭다운 옵션) */
```

**L126**
```typescript
  availableStages: KanbanStage[];
```

**L127**
```typescript
  stageHistory: EngagementStageHistoryItem[];
```

**L128**
```typescript
}
```

### `src\types\inbox.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/inbox.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 받은 편지함(Inbox) 화면의 데이터 모델.
```

**L5**
```typescript
 * communications 테이블의 inbound + outbound를 시간순으로 통합 표시.
```

**L6**
```typescript
 *
```

**L7**
```typescript
 * 변경 이력:
```

**L8**
```typescript
 *   - 2026-05-12 (1차): CommunicationChannel을 DB enum 9개로 정렬.
```

**L9**
```typescript
 *   - 2026-05-12 (2차): UI 호환을 위해 11개로 확장 (slack, other 추가).
```

**L10**
```typescript
 *   - 2026-05-12 (3차): DB enum과 완전 일치 (12개) — webform 추가.
```

**L11**
```typescript
 *                       이제 DB enum app.channel_type과 1:1 매칭.
```

**L12**
```typescript
 */
```

**L13**
```typescript

```

**L14**
```typescript
import type { PartyTypeCode } from './ai';
```

**L15**
```typescript

```

**L16**
```typescript
/**
```

**L17**
```typescript
 * 통신 채널 — DB enum app.channel_type과 1:1 매칭 (12개).
```

**L18**
```typescript
 *
```

**L19**
```typescript
 * email, phone, sms, linkedin, kakaotalk, wechat, whatsapp,
```

**L20**
```typescript
 * in_person, video_call, webform, other, slack
```

**L21**
```typescript
 */
```

**L22**
```typescript
export type CommunicationChannel =
```

**L23**
```typescript
  | 'email'
```

**L24**
```typescript
  | 'phone'
```

**L25**
```typescript
  | 'sms'
```

**L26**
```typescript
  | 'linkedin'
```

**L27**
```typescript
  | 'kakaotalk'
```

**L28**
```typescript
  | 'wechat'
```

**L29**
```typescript
  | 'whatsapp'
```

**L30**
```typescript
  | 'in_person'
```

**L31**
```typescript
  | 'video_call'
```

**L32**
```typescript
  | 'webform'
```

**L33**
```typescript
  | 'other'
```

**L34**
```typescript
  | 'slack';
```

**L35**
```typescript

```

**L36**
```typescript
/**
```

**L37**
```typescript
 * 통신 방향 — DB enum app.direction_type과 일치.
```

**L38**
```typescript
 * 'internal'도 enum에는 있지만 Phase 1은 inbound/outbound만 처리.
```

**L39**
```typescript
 */
```

**L40**
```typescript
export type CommunicationDirection = 'inbound' | 'outbound';
```

**L41**
```typescript

```

**L42**
```typescript
/** 통신 상태 — outbound 발송 결과 추적. */
```

**L43**
```typescript
export type CommunicationStatus =
```

**L44**
```typescript
  | 'received'    // inbound 수신 완료
```

**L45**
```typescript
  | 'pending'     // 발송 대기
```

**L46**
```typescript
  | 'sending'     // 발송 중
```

**L47**
```typescript
  | 'sent'        // 발송 완료
```

**L48**
```typescript
  | 'failed'      // 발송 실패
```

**L49**
```typescript
  | 'bounced';    // 반송
```

**L50**
```typescript

```

**L51**
```typescript
/**
```

**L52**
```typescript
 * 인박스 행 모델 (목록 페이지용).
```

**L53**
```typescript
 */
```

**L54**
```typescript
export interface InboxRow {
```

**L55**
```typescript
  id: string;
```

**L56**
```typescript
  channel: CommunicationChannel;
```

**L57**
```typescript
  direction: CommunicationDirection;
```

**L58**
```typescript
  status: CommunicationStatus;
```

**L59**
```typescript
  fromAddress: string | null;
```

**L60**
```typescript
  fromName: string | null;
```

**L61**
```typescript
  toAddresses: string[];
```

**L62**
```typescript
  subject: string | null;
```

**L63**
```typescript
  bodyPreview: string;       // 첫 120자
```

**L64**
```typescript
  occurredAt: string;
```

**L65**
```typescript
  sentAt: string | null;
```

**L66**
```typescript
  partyId: string | null;
```

**L67**
```typescript
  partyName: string | null;
```

**L68**
```typescript
  partyModule: PartyTypeCode | null;
```

**L69**
```typescript
  /** 이 인바운드에서 생성된 AI 초안이 존재하는가 (해당 시) */
```

**L70**
```typescript
  hasDraft: boolean;
```

**L71**
```typescript
  /** 이 아웃바운드가 AI 초안에서 생성되었는가 */
```

**L72**
```typescript
  aiGenerated: boolean;
```

**L73**
```typescript
  /** 첨부 파일 개수 — Phase 1 미구현, 항상 0 (DB 컬럼 없음) */
```

**L74**
```typescript
  attachmentCount: number;
```

**L75**
```typescript
}
```

**L76**
```typescript

```

**L77**
```typescript
/**
```

**L78**
```typescript
 * 인박스 필터 — URL searchParams로 전달.
```

**L79**
```typescript
 */
```

**L80**
```typescript
export interface InboxFilters {
```

**L81**
```typescript
  channel: CommunicationChannel | 'all';
```

**L82**
```typescript
  direction: CommunicationDirection | 'all';
```

**L83**
```typescript
  /** 검색어 (ilike + pg_trgm). subject + body_plain 대상 */
```

**L84**
```typescript
  query: string;
```

**L85**
```typescript
  /** AI 초안 있는 인바운드만 */
```

**L86**
```typescript
  hasDraft: boolean;
```

**L87**
```typescript
  /** 특정 거래처 (UUID) — Phase 1은 URL 직접 입력만 지원 */
```

**L88**
```typescript
  partyId: string | null;
```

**L89**
```typescript
}
```

**L90**
```typescript

```

**L91**
```typescript
export interface InboxPagination {
```

**L92**
```typescript
  page: number;
```

**L93**
```typescript
  pageSize: number;
```

**L94**
```typescript
}
```

**L95**
```typescript

```

**L96**
```typescript
export interface InboxResult {
```

**L97**
```typescript
  rows: InboxRow[];
```

**L98**
```typescript
  totalCount: number;
```

**L99**
```typescript
  filters: InboxFilters;
```

**L100**
```typescript
  pagination: InboxPagination;
```

**L101**
```typescript
}
```

**L102**
```typescript

```

**L103**
```typescript
export const DEFAULT_INBOX_FILTERS: InboxFilters = {
```

**L104**
```typescript
  channel: 'all',
```

**L105**
```typescript
  direction: 'all',
```

**L106**
```typescript
  query: '',
```

**L107**
```typescript
  hasDraft: false,
```

**L108**
```typescript
  partyId: null,
```

**L109**
```typescript
};
```

**L110**
```typescript

```

**L111**
```typescript
export const INBOX_DEFAULT_PAGE_SIZE = 25;
```

**L112**
```typescript
export const INBOX_PAGE_SIZE_OPTIONS: readonly number[] = [25, 50, 100] as const;
```

### `src\types\industry-link.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/industry-link.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * Phase 6 — Industry master DB와 연결된 거래처 detail 섹션 도메인 타입.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * industry 스키마의 정규화된 raw row를 UI 표시용 camelCase로 변환한 결과.
```

**L7**
```typescript
 * V11.4 평가 체계(Mill-Specific vs Supplier Footprint)와 mill 단위 likely_* 메타
```

**L8**
```typescript
 * (unmatched mill의 fallback intel)를 1급 시민으로 노출.
```

**L9**
```typescript
 *
```

**L10**
```typescript
 * 참고: industry 스키마는 flat columns만 사용 (jsonb module_data 없음).
```

**L11**
```typescript
 */
```

**L12**
```typescript

```

**L13**
```typescript
export type EvidenceLevel = 'A' | 'B' | 'C';
```

**L14**
```typescript
export type ConfidenceGrade = 'A' | 'B' | 'C';
```

**L15**
```typescript
export type AssessmentScope = 'Mill-Specific' | 'Supplier Footprint';
```

**L16**
```typescript

```

**L17**
```typescript
/* ============================================================
```

**L18**
```typescript
 * Paper Company 측 (buyer module)
```

**L19**
```typescript
 * ============================================================ */
```

**L20**
```typescript

```

**L21**
```typescript
export interface IndustryPaperCompanySummary {
```

**L22**
```typescript
  id: number;
```

**L23**
```typescript
  name: string;
```

**L24**
```typescript
  marketCode: string | null;
```

**L25**
```typescript
  sourceUrl: string | null;
```

**L26**
```typescript
  evidenceLevel: EvidenceLevel | null;
```

**L27**
```typescript
  /** 'High' | 'Medium' | 'Low' 등 자유 텍스트 */
```

**L28**
```typescript
  fillerUseIntensity: string | null;
```

**L29**
```typescript
  knownFillerTypes: string[];
```

**L30**
```typescript
  /** 회사 차원의 paper grade */
```

**L31**
```typescript
  mainProductCategory: string | null;
```

**L32**
```typescript
  mainProducts: string | null;
```

**L33**
```typescript
  headquarters: string | null;
```

**L34**
```typescript
  /** 유럽 mill 분포 텍스트 — V11.4 footprint hint */
```

**L35**
```typescript
  europeMillsFootprint: string | null;
```

**L36**
```typescript
  /** "supply structure" 메모 (Tolling/Onsite/Toll-manufacturer 등) */
```

**L37**
```typescript
  supplyStructureNote: string | null;
```

**L38**
```typescript
  notes: string | null;
```

**L39**
```typescript
}
```

**L40**
```typescript

```

**L41**
```typescript
export interface IndustryMillRow {
```

**L42**
```typescript
  id: number;
```

**L43**
```typescript
  millName: string;
```

**L44**
```typescript
  city: string | null;
```

**L45**
```typescript
  region: string | null;
```

**L46**
```typescript
  marketCode: string | null;
```

**L47**
```typescript
  mainProductCategory: string | null;
```

**L48**
```typescript
  mainProducts: string | null;
```

**L49**
```typescript
  /** confidence 같은 게 아닌, "이 mill이 filler를 쓸 확률" 메모 */
```

**L50**
```typescript
  fillerProbability: string | null;
```

**L51**
```typescript
  /** likely supplier 추측 (linkage 매칭 안 된 mill의 fallback) */
```

**L52**
```typescript
  likelyFillerTypes: string[];
```

**L53**
```typescript
  likelySupplyStructure: string | null;
```

**L54**
```typescript
  likelySupplierNote: string | null;
```

**L55**
```typescript
  /** 확정된 supplier 매트릭스 (supplier_mill_linkages 기반) */
```

**L56**
```typescript
  suppliers: Array<{
```

**L57**
```typescript
    fillerSupplierId: number | null;
```

**L58**
```typescript
    supplierName: string;
```

**L59**
```typescript
    fillerType: string | null;
```

**L60**
```typescript
    supplyStructure: string | null;
```

**L61**
```typescript
    relationshipType: string | null;
```

**L62**
```typescript
    confidenceGrade: ConfidenceGrade | null;
```

**L63**
```typescript
  }>;
```

**L64**
```typescript
}
```

**L65**
```typescript

```

**L66**
```typescript
/** Supplier 단위 aggregation — "이 회사에 가장 많이 들어가는 공급사 순" */
```

**L67**
```typescript
export interface PaperCompanySupplierSummaryRow {
```

**L68**
```typescript
  fillerSupplierId: number | null;
```

**L69**
```typescript
  supplierName: string;
```

**L70**
```typescript
  millCount: number;
```

**L71**
```typescript
  /** 같은 supplier의 mill별 confidence 중 최고 등급 (A > B > C) */
```

**L72**
```typescript
  topConfidence: ConfidenceGrade | null;
```

**L73**
```typescript
}
```

**L74**
```typescript

```

**L75**
```typescript
export interface PaperCompanyIntel {
```

**L76**
```typescript
  company: IndustryPaperCompanySummary;
```

**L77**
```typescript
  mills: IndustryMillRow[];
```

**L78**
```typescript
  supplierSummary: PaperCompanySupplierSummaryRow[];
```

**L79**
```typescript
  stats: {
```

**L80**
```typescript
    totalMills: number;
```

**L81**
```typescript
    /** 1개 이상의 확정 supplier가 매핑된 mill 수 */
```

**L82**
```typescript
    millsWithSuppliers: number;
```

**L83**
```typescript
    /** unique 공급사 수 (mill 횟수 무관) */
```

**L84**
```typescript
    totalSupplierCount: number;
```

**L85**
```typescript
    /** likely_filler_types만 있고 확정 supplier가 없는 mill 수 — 영업 우선순위 */
```

**L86**
```typescript
    millsWithLikelyOnly: number;
```

**L87**
```typescript
  };
```

**L88**
```typescript
}
```

**L89**
```typescript

```

**L90**
```typescript
/* ============================================================
```

**L91**
```typescript
 * Filler Supplier 측 (filler module)
```

**L92**
```typescript
 * ============================================================ */
```

**L93**
```typescript

```

**L94**
```typescript
export interface IndustryFillerSupplierSummary {
```

**L95**
```typescript
  id: number;
```

**L96**
```typescript
  name: string;
```

**L97**
```typescript
  marketCode: string | null;
```

**L98**
```typescript
  sourceUrl: string | null;
```

**L99**
```typescript
  evidenceLevel: EvidenceLevel | null;
```

**L100**
```typescript
  /** 'GCC' | 'PCC' | 'Kaolin' | 'Multi-mineral' 등 */
```

**L101**
```typescript
  supplierType: string | null;
```

**L102**
```typescript
  /** 'Global major' | 'Regional' | 'Niche' 등 */
```

**L103**
```typescript
  marketRole: string | null;
```

**L104**
```typescript
  /** 'Tolling' | 'Direct' 등 (자유 텍스트) */
```

**L105**
```typescript
  supplyModel: string | null;
```

**L106**
```typescript
  /** 공급 가능한 filler 종류 (V11.4) */
```

**L107**
```typescript
  relevantFillerTypes: string[];
```

**L108**
```typescript
  europePaperEvidence: string | null;
```

**L109**
```typescript
  onsitePccEvidence: string | null;
```

**L110**
```typescript
  notes: string | null;
```

**L111**
```typescript
}
```

**L112**
```typescript

```

**L113**
```typescript
export interface FillerLinkageRow {
```

**L114**
```typescript
  /** supplier_mill_linkages.id를 string으로 정규화 */
```

**L115**
```typescript
  id: string;
```

**L116**
```typescript
  paperCompanyId: number | null;
```

**L117**
```typescript
  /** FK 매핑 우선, 없으면 raw name fallback */
```

**L118**
```typescript
  paperCompanyName: string;
```

**L119**
```typescript
  paperMillId: number | null;
```

**L120**
```typescript
  /** FK 매핑 우선 → mill_site_raw → null */
```

**L121**
```typescript
  millName: string | null;
```

**L122**
```typescript
  marketCode: string | null;
```

**L123**
```typescript
  countryRegion: string | null;
```

**L124**
```typescript
  fillerType: string | null;
```

**L125**
```typescript
  supplyStructure: string | null;
```

**L126**
```typescript
  relationshipType: string | null;
```

**L127**
```typescript
  confidenceGrade: ConfidenceGrade | null;
```

**L128**
```typescript
  /** V11.4 평가 범위 */
```

**L129**
```typescript
  assessmentScope: AssessmentScope;
```

**L130**
```typescript
  /** 'Confirmed' | 'Probable' | 'Unconfirmed' 등 */
```

**L131**
```typescript
  confirmationStatus: string | null;
```

**L132**
```typescript
}
```

**L133**
```typescript

```

**L134**
```typescript
export interface FillerSupplierIntel {
```

**L135**
```typescript
  supplier: IndustryFillerSupplierSummary;
```

**L136**
```typescript
  /** assessment_scope = 'Mill-Specific' — plant 단위 확정 거래 */
```

**L137**
```typescript
  millSpecificLinks: FillerLinkageRow[];
```

**L138**
```typescript
  /** assessment_scope = 'Supplier Footprint' — 지역 단위만 확인 */
```

**L139**
```typescript
  footprintLinks: FillerLinkageRow[];
```

**L140**
```typescript
  stats: {
```

**L141**
```typescript
    totalLinks: number;
```

**L142**
```typescript
    millSpecificCount: number;
```

**L143**
```typescript
    footprintCount: number;
```

**L144**
```typescript
    /** 거래 중인 unique paper company 수 (raw name 포함) */
```

**L145**
```typescript
    uniquePaperCompanies: number;
```

**L146**
```typescript
    /** Mill-Specific 한정 unique mill 수 */
```

**L147**
```typescript
    uniqueMills: number;
```

**L148**
```typescript
  };
```

**L149**
```typescript
}
```

### `src\types\party-detail.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/party-detail.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 거래처(parties) 상세 화면의 데이터 모델.
```

**L5**
```typescript
 * Phase 1은 read-only.
```

**L6**
```typescript
 *
```

**L7**
```typescript
 * 변경 이력:
```

**L8**
```typescript
 *   - 2026-05-11: DB 스키마와 정합 — 단일 industry/tags 필드 제거,
```

**L9**
```typescript
 *                 industryTags/interestTags 배열로 분리.
```

**L10**
```typescript
 *                 (DB 실제 컬럼: industry_tags ARRAY, interest_tags ARRAY)
```

**L11**
```typescript
 *   - 2026-05-14: Phase 6 — industryPaperCompanyId /
```

**L12**
```typescript
 *                 industryFillerSupplierId FK 필드 추가.
```

**L13**
```typescript
 */
```

**L14**
```typescript

```

**L15**
```typescript
import type { PartyTypeCode } from './ai';
```

**L16**
```typescript
import type {
```

**L17**
```typescript
  CommunicationChannel,
```

**L18**
```typescript
  CommunicationDirection,
```

**L19**
```typescript
  CommunicationStatus,
```

**L20**
```typescript
} from './inbox';
```

**L21**
```typescript

```

**L22**
```typescript
/** parties.tier CHECK 제약과 일치. */
```

**L23**
```typescript
export type PartyTier = 'tier_1' | 'tier_2' | 'tier_3' | 'cold';
```

**L24**
```typescript

```

**L25**
```typescript
/** parties.status CHECK 제약과 일치. */
```

**L26**
```typescript
export type PartyStatus = 'active' | 'paused' | 'closed_won' | 'closed_lost' | 'archived';
```

**L27**
```typescript

```

**L28**
```typescript
export interface PartyDetail {
```

**L29**
```typescript
  id: string;
```

**L30**
```typescript
  organizationId: string;
```

**L31**
```typescript
  name: string;
```

**L32**
```typescript
  partyType: PartyTypeCode;
```

**L33**
```typescript
  tier: PartyTier | null;
```

**L34**
```typescript
  status: PartyStatus;
```

**L35**
```typescript
  countryCode: string | null;
```

**L36**
```typescript
  website: string | null;
```

**L37**
```typescript
  /** 산업 분류 태그 (예: "Venture Capital", "Software", "Healthcare") */
```

**L38**
```typescript
  industryTags: string[];
```

**L39**
```typescript
  /** 관심/포커스 태그 (예: "Early Stage", "AI", "Growth") */
```

**L40**
```typescript
  interestTags: string[];
```

**L41**
```typescript
  notes: string | null;
```

**L42**
```typescript
  source: string | null;
```

**L43**
```typescript
  createdAt: string;
```

**L44**
```typescript
  updatedAt: string;
```

**L45**
```typescript

```

**L46**
```typescript
  /** ▼ Phase 6 — industry master DB 연동 FK */
```

**L47**
```typescript
  industryPaperCompanyId: number | null;
```

**L48**
```typescript
  industryFillerSupplierId: number | null;
```

**L49**
```typescript

```

**L50**
```typescript
  /** 통계 — RPC나 별도 COUNT 쿼리로 채움 */
```

**L51**
```typescript
  counts: {
```

**L52**
```typescript
    contacts: number;
```

**L53**
```typescript
    communications: number;
```

**L54**
```typescript
    pendingDrafts: number;
```

**L55**
```typescript
    openEngagements: number;
```

**L56**
```typescript
    openTasks: number;
```

**L57**
```typescript
  };
```

**L58**
```typescript
}
```

**L59**
```typescript

```

**L60**
```typescript
/** 활동 타임라인 한 항목 — communications + tasks 통합. */
```

**L61**
```typescript
export type TimelineItem =
```

**L62**
```typescript
  | TimelineCommunicationItem
```

**L63**
```typescript
  | TimelineTaskItem;
```

**L64**
```typescript

```

**L65**
```typescript
export interface TimelineCommunicationItem {
```

**L66**
```typescript
  kind: 'communication';
```

**L67**
```typescript
  id: string;
```

**L68**
```typescript
  occurredAt: string;
```

**L69**
```typescript
  channel: CommunicationChannel;
```

**L70**
```typescript
  direction: CommunicationDirection;
```

**L71**
```typescript
  status: CommunicationStatus;
```

**L72**
```typescript
  subject: string | null;
```

**L73**
```typescript
  bodyPreview: string;
```

**L74**
```typescript
  fromAddress: string | null;
```

**L75**
```typescript
  aiGenerated: boolean;
```

**L76**
```typescript
}
```

**L77**
```typescript

```

**L78**
```typescript
export interface TimelineTaskItem {
```

**L79**
```typescript
  kind: 'task';
```

**L80**
```typescript
  id: string;
```

**L81**
```typescript
  occurredAt: string;     // created_at or completed_at
```

**L82**
```typescript
  event: 'created' | 'completed';
```

**L83**
```typescript
  title: string;
```

**L84**
```typescript
  status: string;
```

**L85**
```typescript
  priority: string | null;
```

**L86**
```typescript
  dueAt: string | null;
```

**L87**
```typescript
}
```

**L88**
```typescript

```

**L89**
```typescript
export interface PartyContact {
```

**L90**
```typescript
  id: string;
```

**L91**
```typescript
  fullName: string | null;
```

**L92**
```typescript
  email: string | null;
```

**L93**
```typescript
  jobTitle: string | null;
```

**L94**
```typescript
  phone: string | null;
```

**L95**
```typescript
  isPrimary: boolean;
```

**L96**
```typescript
}
```

**L97**
```typescript

```

**L98**
```typescript
export interface PartyEngagement {
```

**L99**
```typescript
  id: string;
```

**L100**
```typescript
  name: string;
```

**L101**
```typescript
  status: string;
```

**L102**
```typescript
  stage: string | null;
```

**L103**
```typescript
  valueAmount: number | null;
```

**L104**
```typescript
  valueCurrency: string;
```

**L105**
```typescript
  closeDate: string | null;
```

**L106**
```typescript
  updatedAt: string;
```

**L107**
```typescript
}
```

**L108**
```typescript

```

**L109**
```typescript
export interface PartyTask {
```

**L110**
```typescript
  id: string;
```

**L111**
```typescript
  title: string;
```

**L112**
```typescript
  status: string;
```

**L113**
```typescript
  priority: string | null;
```

**L114**
```typescript
  dueAt: string | null;
```

**L115**
```typescript
  createdAt: string;
```

**L116**
```typescript
}
```

**L117**
```typescript

```

**L118**
```typescript
export interface PartyDetailFull {
```

**L119**
```typescript
  party: PartyDetail;
```

**L120**
```typescript
  contacts: PartyContact[];
```

**L121**
```typescript
  engagements: PartyEngagement[];
```

**L122**
```typescript
  tasks: PartyTask[];
```

**L123**
```typescript
  timeline: TimelineItem[];
```

**L124**
```typescript
}
```

### `src\types\party-type.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/party-type.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 두 차원의 party 분류:
```

**L5**
```typescript
 *
```

**L6**
```typescript
 *   PartyType  - 비즈니스 카테고리 (urm.party_types 기반)
```

**L7**
```typescript
 *     investor, paper_mill, filler_supplier, buyer, customer, partner, government_grant
```

**L8**
```typescript
 *
```

**L9**
```typescript
 *   PartyKind  - 법인 형태 (app.party_kind enum 기반)
```

**L10**
```typescript
 *     company, organization, individual, fund, government
```

**L11**
```typescript
 *
```

**L12**
```typescript
 * Naming policy (2026-05-25 Phase C):
```

**L13**
```typescript
 *   - TS type 이름: PartyType, PartyKind (PascalCase)
```

**L14**
```typescript
 *   - TS property / variable / form field: partyType, partyKind (camelCase, React/Next.js 컨벤션)
```

**L15**
```typescript
 *   - DB column: party_type, party_kind (snake_case)
```

**L16**
```typescript
 *
```

**L17**
```typescript
 * Source of truth:
```

**L18**
```typescript
 *   - urm.party_types (7 rows) ← PartyType
```

**L19**
```typescript
 *   - app.party_kind enum (5 values) ← PartyKind
```

**L20**
```typescript
 */
```

**L21**
```typescript

```

**L22**
```typescript
// ============================================================
```

**L23**
```typescript
// PartyType - 비즈니스 카테고리
```

**L24**
```typescript
// ============================================================
```

**L25**
```typescript

```

**L26**
```typescript
export type PartyType =
```

**L27**
```typescript
  | 'investor'
```

**L28**
```typescript
  | 'paper_mill'
```

**L29**
```typescript
  | 'filler_supplier'
```

**L30**
```typescript
  | 'buyer'
```

**L31**
```typescript
  | 'customer'
```

**L32**
```typescript
  | 'partner'
```

**L33**
```typescript
  | 'government_grant';
```

**L34**
```typescript

```

**L35**
```typescript
/** Legacy alias. 새 코드는 PartyType 직접 사용. */
```

**L36**
```typescript
export type PartyTypeCode = PartyType;
```

**L37**
```typescript

```

**L38**
```typescript
/** 전체 PartyType 배열. */
```

**L39**
```typescript
export const PARTY_TYPES: readonly PartyType[] = [
```

**L40**
```typescript
  'investor',
```

**L41**
```typescript
  'paper_mill',
```

**L42**
```typescript
  'filler_supplier',
```

**L43**
```typescript
  'buyer',
```

**L44**
```typescript
  'customer',
```

**L45**
```typescript
  'partner',
```

**L46**
```typescript
  'government_grant',
```

**L47**
```typescript
] as const;
```

**L48**
```typescript

```

**L49**
```typescript
/** Legacy alias. */
```

**L50**
```typescript
export const PARTY_TYPE_CODES: readonly PartyType[] = PARTY_TYPES;
```

**L51**
```typescript

```

**L52**
```typescript
/**
```

**L53**
```typescript
 * urm.party_types.id (smallint) ↔ code 매핑.
```

**L54**
```typescript
 */
```

**L55**
```typescript
export const PARTY_TYPE_ID_BY_CODE: Record<PartyType, number> = {
```

**L56**
```typescript
  investor: 1,
```

**L57**
```typescript
  paper_mill: 2,
```

**L58**
```typescript
  filler_supplier: 3,
```

**L59**
```typescript
  buyer: 4,
```

**L60**
```typescript
  customer: 5,
```

**L61**
```typescript
  partner: 6,
```

**L62**
```typescript
  government_grant: 7,
```

**L63**
```typescript
};
```

**L64**
```typescript

```

**L65**
```typescript
export const PARTY_TYPE_CODE_BY_ID: Record<number, PartyType> = {
```

**L66**
```typescript
  1: 'investor',
```

**L67**
```typescript
  2: 'paper_mill',
```

**L68**
```typescript
  3: 'filler_supplier',
```

**L69**
```typescript
  4: 'buyer',
```

**L70**
```typescript
  5: 'customer',
```

**L71**
```typescript
  6: 'partner',
```

**L72**
```typescript
  7: 'government_grant',
```

**L73**
```typescript
};
```

**L74**
```typescript

```

**L75**
```typescript
/** 다국어 표시명. */
```

**L76**
```typescript
export const PARTY_TYPE_DISPLAY: Record<
```

**L77**
```typescript
  PartyType,
```

**L78**
```typescript
  { en: string; ko: string; ja: string }
```

**L79**
```typescript
> = {
```

**L80**
```typescript
  investor: { en: 'Investor', ko: '투자자', ja: '投資家' },
```

**L81**
```typescript
  paper_mill: { en: 'Paper Mill', ko: '제지사', ja: '製紙会社' },
```

**L82**
```typescript
  filler_supplier: {
```

**L83**
```typescript
    en: 'Filler Supplier',
```

**L84**
```typescript
    ko: '광물공급사',
```

**L85**
```typescript
    ja: 'フィラーサプライヤー',
```

**L86**
```typescript
  },
```

**L87**
```typescript
  buyer: { en: 'Buyer', ko: '구매사', ja: '購買会社' },
```

**L88**
```typescript
  customer: { en: 'Customer', ko: '고객사', ja: '顧客' },
```

**L89**
```typescript
  partner: { en: 'Partner', ko: '협력사', ja: 'パートナー' },
```

**L90**
```typescript
  government_grant: {
```

**L91**
```typescript
    en: 'Government Grant',
```

**L92**
```typescript
    ko: '정부지원',
```

**L93**
```typescript
    ja: '政府補助',
```

**L94**
```typescript
  },
```

**L95**
```typescript
};
```

**L96**
```typescript

```

**L97**
```typescript
/** Type guard. */
```

**L98**
```typescript
export function isPartyType(v: unknown): v is PartyType {
```

**L99**
```typescript
  return typeof v === 'string' && PARTY_TYPES.includes(v as PartyType);
```

**L100**
```typescript
}
```

**L101**
```typescript

```

**L102**
```typescript
export const isPartyTypeCode = isPartyType;
```

**L103**
```typescript

```

**L104**
```typescript
export function moduleToPartyType(
```

**L105**
```typescript
  legacy: string | null | undefined,
```

**L106**
```typescript
): PartyType | null {
```

**L107**
```typescript
  if (!legacy) return null;
```

**L108**
```typescript
  if (isPartyType(legacy)) return legacy;
```

**L109**
```typescript
  return null;
```

**L110**
```typescript
}
```

**L111**
```typescript

```

**L112**
```typescript
export function partyTypeToModule(code: PartyType): string | null {
```

**L113**
```typescript
  if (code === 'buyer' || code === 'government_grant') return null;
```

**L114**
```typescript
  return code;
```

**L115**
```typescript
}
```

**L116**
```typescript

```

**L117**
```typescript
// ============================================================
```

**L118**
```typescript
// PartyKind - 법인 형태
```

**L119**
```typescript
// ============================================================
```

**L120**
```typescript

```

**L121**
```typescript
export type PartyKind =
```

**L122**
```typescript
  | 'company'
```

**L123**
```typescript
  | 'organization'
```

**L124**
```typescript
  | 'individual'
```

**L125**
```typescript
  | 'fund'
```

**L126**
```typescript
  | 'government';
```

**L127**
```typescript

```

**L128**
```typescript
export const PARTY_KINDS: readonly PartyKind[] = [
```

**L129**
```typescript
  'company',
```

**L130**
```typescript
  'organization',
```

**L131**
```typescript
  'individual',
```

**L132**
```typescript
  'fund',
```

**L133**
```typescript
  'government',
```

**L134**
```typescript
] as const;
```

**L135**
```typescript

```

**L136**
```typescript
export const PARTY_KIND_DISPLAY: Record<
```

**L137**
```typescript
  PartyKind,
```

**L138**
```typescript
  { en: string; ko: string; ja: string }
```

**L139**
```typescript
> = {
```

**L140**
```typescript
  company: { en: 'Company', ko: '회사', ja: '会社' },
```

**L141**
```typescript
  organization: { en: 'Organization', ko: '단체', ja: '団体' },
```

**L142**
```typescript
  individual: { en: 'Individual', ko: '개인', ja: '個人' },
```

**L143**
```typescript
  fund: { en: 'Fund', ko: '펀드', ja: 'ファンド' },
```

**L144**
```typescript
  government: { en: 'Government', ko: '정부', ja: '政府' },
```

**L145**
```typescript
};
```

**L146**
```typescript

```

**L147**
```typescript
export function isPartyKind(v: unknown): v is PartyKind {
```

**L148**
```typescript
  return typeof v === 'string' && PARTY_KINDS.includes(v as PartyKind);
```

**L149**
```typescript
}
```

### `src\types\phase21.ts`

**L1**
```typescript
// src/types/phase21.ts
```

**L2**
```typescript
// Phase 21a ??Email Tracking types
```

**L3**
```typescript

```

**L4**
```typescript
export interface EmailTracking {
```

**L5**
```typescript
  id: string;
```

**L6**
```typescript
  org_id: string;
```

**L7**
```typescript
  draft_id: string | null;
```

**L8**
```typescript
  party_id: string | null;
```

**L9**
```typescript
  contact_id: string | null;
```

**L10**
```typescript
  communication_id: string | null;
```

**L11**
```typescript
  subject: string | null;
```

**L12**
```typescript
  sent_to: string;
```

**L13**
```typescript
  open_token: string;
```

**L14**
```typescript
  sent_at: string;
```

**L15**
```typescript
  first_opened_at: string | null;
```

**L16**
```typescript
  open_count: number;
```

**L17**
```typescript
  click_count: number;
```

**L18**
```typescript
  created_at: string;
```

**L19**
```typescript
}
```

**L20**
```typescript

```

**L21**
```typescript
export interface EmailTrackingLink {
```

**L22**
```typescript
  id: string;
```

**L23**
```typescript
  tracking_id: string;
```

**L24**
```typescript
  token: string;
```

**L25**
```typescript
  original_url: string;
```

**L26**
```typescript
  click_count: number;
```

**L27**
```typescript
}
```

**L28**
```typescript

```

**L29**
```typescript
export interface EmailTrackingEvent {
```

**L30**
```typescript
  id: string;
```

**L31**
```typescript
  tracking_id: string;
```

**L32**
```typescript
  link_id: string | null;
```

**L33**
```typescript
  event_type: string;
```

**L34**
```typescript
  url: string | null;
```

**L35**
```typescript
  ip: string | null;
```

**L36**
```typescript
  user_agent: string | null;
```

**L37**
```typescript
  created_at: string;
```

**L38**
```typescript
}
```

**L39**
```typescript

```

**L40**
```typescript
export interface TrackingPayload {
```

**L41**
```typescript
  tracking_id: string;
```

**L42**
```typescript
  open_token: string;
```

**L43**
```typescript
  links: Array<{ token: string; url: string }>;
```

**L44**
```typescript
}
```

**L45**
```typescript

```

**L46**
```typescript
/** Returned by get_tracking_for_drafts RPC */
```

**L47**
```typescript
export interface DraftTrackingSummary {
```

**L48**
```typescript
  draft_id: string;
```

**L49**
```typescript
  tracking_id: string;
```

**L50**
```typescript
  open_count: number;
```

**L51**
```typescript
  click_count: number;
```

**L52**
```typescript
  first_opened_at: string | null;
```

**L53**
```typescript
  sent_at: string;
```

**L54**
```typescript
}
```

### `src\types\phase21b.ts`

**L1**
```typescript
// src/types/phase21b.ts
```

**L2**
```typescript
// Phase 21b ??Email Sequence Types
```

**L3**
```typescript

```

**L4**
```typescript
export type SequenceStatus    = 'active' | 'paused' | 'archived';
```

**L5**
```typescript
export type EnrollmentStatus  = 'active' | 'paused' | 'completed' | 'cancelled';
```

**L6**
```typescript
export type SequenceSendStatus = 'sent' | 'failed' | 'skipped';
```

**L7**
```typescript

```

**L8**
```typescript
// ?�?� DB rows ?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
```

**L9**
```typescript

```

**L10**
```typescript
export interface EmailSequence {
```

**L11**
```typescript
  id:                 string;
```

**L12**
```typescript
  organization_id:             string;
```

**L13**
```typescript
  name:               string;
```

**L14**
```typescript
  description:        string | null;
```

**L15**
```typescript
  status:             SequenceStatus;
```

**L16**
```typescript
  step_count:         number;
```

**L17**
```typescript
  active_enrollments: number;
```

**L18**
```typescript
  total_sends:        number;
```

**L19**
```typescript
  created_at:         string;
```

**L20**
```typescript
}
```

**L21**
```typescript

```

**L22**
```typescript
export interface EmailSequenceStep {
```

**L23**
```typescript
  id:          string;
```

**L24**
```typescript
  sequence_id: string;
```

**L25**
```typescript
  step_order:  number;
```

**L26**
```typescript
  day_offset:  number;
```

**L27**
```typescript
  subject:     string;
```

**L28**
```typescript
  body_text:   string;
```

**L29**
```typescript
  created_at:  string;
```

**L30**
```typescript
  updated_at:  string;
```

**L31**
```typescript
}
```

**L32**
```typescript

```

**L33**
```typescript
export interface EmailSequenceWithSteps
```

**L34**
```typescript
  extends Omit<EmailSequence, 'step_count' | 'active_enrollments' | 'total_sends'> {
```

**L35**
```typescript
  steps: EmailSequenceStep[];
```

**L36**
```typescript
}
```

**L37**
```typescript

```

**L38**
```typescript
export interface PartyEnrollmentSummary {
```

**L39**
```typescript
  id:              string;
```

**L40**
```typescript
  sequence_id:     string;
```

**L41**
```typescript
  sequence_name:   string;
```

**L42**
```typescript
  status:          EnrollmentStatus;
```

**L43**
```typescript
  next_step_order: number;
```

**L44**
```typescript
  total_steps:     number;
```

**L45**
```typescript
  next_send_at:    string | null;
```

**L46**
```typescript
  enrolled_at:     string;
```

**L47**
```typescript
  sends_count:     number;
```

**L48**
```typescript
}
```

**L49**
```typescript

```

**L50**
```typescript
export interface DueEnrollmentRow {
```

**L51**
```typescript
  enrollment_id:   string;
```

**L52**
```typescript
  organization_id:          string;
```

**L53**
```typescript
  sequence_id:     string;
```

**L54**
```typescript
  party_id:        string | null;
```

**L55**
```typescript
  contact_id:      string | null;
```

**L56**
```typescript
  enrolled_by:     string | null;
```

**L57**
```typescript
  enrolled_at:     string;
```

**L58**
```typescript
  next_step_order: number;
```

**L59**
```typescript
  step_id:         string;
```

**L60**
```typescript
  step_day_offset: number;
```

**L61**
```typescript
  step_subject:    string;
```

**L62**
```typescript
  step_body_text:  string;
```

**L63**
```typescript
  is_last_step:    boolean;
```

**L64**
```typescript
}
```

**L65**
```typescript

```

**L66**
```typescript
// ?�?� Processor result ?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
```

**L67**
```typescript

```

**L68**
```typescript
export interface ProcessorResult {
```

**L69**
```typescript
  enrollment_id: string;
```

**L70**
```typescript
  status:        'sent' | 'skipped' | 'error';
```

**L71**
```typescript
  to?:           string;
```

**L72**
```typescript
  reason?:       string;
```

**L73**
```typescript
  error?:        string;
```

**L74**
```typescript
}
```

**L75**
```typescript

```

**L76**
```typescript
// ?�?� Form / draft types ?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�
```

**L77**
```typescript

```

**L78**
```typescript
export interface StepDraft {
```

**L79**
```typescript
  /** undefined = brand new step (no DB id yet) */
```

**L80**
```typescript
  id?:         string;
```

**L81**
```typescript
  step_order:  number;
```

**L82**
```typescript
  day_offset:  number;
```

**L83**
```typescript
  subject:     string;
```

**L84**
```typescript
  body_text:   string;
```

**L85**
```typescript
}
```

**L86**
```typescript

```

**L87**
```typescript
export interface SequenceDraft {
```

**L88**
```typescript
  name:        string;
```

**L89**
```typescript
  description: string;
```

**L90**
```typescript
  steps:       StepDraft[];
```

**L91**
```typescript
}
```

### `src\types\phase22a.ts`

**L1**
```typescript
// src/types/phase22a.ts
```

**L2**
```typescript
// ============================================================
```

**L3**
```typescript
// Phase 22a — Communications Timeline + Compose Dialog Types
```

**L4**
```typescript
// ============================================================
```

**L5**
```typescript

```

**L6**
```typescript
export type EmailDirection = "outbound" | "inbound";
```

**L7**
```typescript

```

**L8**
```typescript
export type EmailStatus =
```

**L9**
```typescript
  | "draft"
```

**L10**
```typescript
  | "queued"
```

**L11**
```typescript
  | "sending"
```

**L12**
```typescript
  | "sent"
```

**L13**
```typescript
  | "delivered"
```

**L14**
```typescript
  | "failed"
```

**L15**
```typescript
  | "received"
```

**L16**
```typescript
  | "bounced";
```

**L17**
```typescript

```

**L18**
```typescript
export type ComposeMode = "manual" | "template" | "ai";
```

**L19**
```typescript

```

**L20**
```typescript
export type ReplyIntent =
```

**L21**
```typescript
  | "interested"
```

**L22**
```typescript
  | "not_now"
```

**L23**
```typescript
  | "objection"
```

**L24**
```typescript
  | "unsubscribe"
```

**L25**
```typescript
  | "wrong_person"
```

**L26**
```typescript
  | "question"
```

**L27**
```typescript
  | "auto_reply"
```

**L28**
```typescript
  | "unknown";
```

**L29**
```typescript

```

**L30**
```typescript
export interface AIClassification {
```

**L31**
```typescript
  intent?: ReplyIntent;
```

**L32**
```typescript
  confidence?: number;
```

**L33**
```typescript
  summary?: string;
```

**L34**
```typescript
  language?: "ko" | "en" | "ja" | string;
```

**L35**
```typescript
  sentiment?: "positive" | "neutral" | "negative";
```

**L36**
```typescript
  competitors_mentioned?: string[];
```

**L37**
```typescript
  topics?: string[];
```

**L38**
```typescript
  suggested_action?: string;
```

**L39**
```typescript
  [key: string]: unknown;
```

**L40**
```typescript
}
```

**L41**
```typescript

```

**L42**
```typescript
export interface CommunicationTimelineItem {
```

**L43**
```typescript
  id: string;
```

**L44**
```typescript
  thread_id: string | null;
```

**L45**
```typescript
  in_reply_to: string | null;
```

**L46**
```typescript
  message_id: string | null;
```

**L47**
```typescript
  direction: EmailDirection;
```

**L48**
```typescript
  subject: string | null;
```

**L49**
```typescript
  body_html: string | null;
```

**L50**
```typescript
  body_plain: string | null;
```

**L51**
```typescript
  body_summary: string | null;
```

**L52**
```typescript
  from_address: string | null;
```

**L53**
```typescript
  from_name: string | null;
```

**L54**
```typescript
  to_addresses: string[];
```

**L55**
```typescript
  status: string;
```

**L56**
```typescript
  occurred_at: string;
```

**L57**
```typescript
  sent_at: string | null;
```

**L58**
```typescript
  opened_at: string | null;
```

**L59**
```typescript
  clicked_at: string | null;
```

**L60**
```typescript
  replied_at: string | null;
```

**L61**
```typescript
  received_at: string | null;
```

**L62**
```typescript
  ai_classification: AIClassification | null;
```

**L63**
```typescript
  ai_generated: boolean;
```

**L64**
```typescript
  contact_id: string | null;
```

**L65**
```typescript
  contact_name: string | null;
```

**L66**
```typescript
  contact_email: string | null;
```

**L67**
```typescript
  template_id: string | null;
```

**L68**
```typescript
  is_starred: boolean;
```

**L69**
```typescript
  thread_position: number;
```

**L70**
```typescript
}
```

**L71**
```typescript

```

**L72**
```typescript
export interface PartyCommunicationStats {
```

**L73**
```typescript
  total: number;
```

**L74**
```typescript
  sent: number;
```

**L75**
```typescript
  received: number;
```

**L76**
```typescript
  opened: number;
```

**L77**
```typescript
  replied: number;
```

**L78**
```typescript
  threads: number;
```

**L79**
```typescript
}
```

**L80**
```typescript

```

**L81**
```typescript
export interface ThreadContext {
```

**L82**
```typescript
  thread: Array<{
```

**L83**
```typescript
    id: string;
```

**L84**
```typescript
    direction: EmailDirection;
```

**L85**
```typescript
    subject: string;
```

**L86**
```typescript
    body_plain: string;
```

**L87**
```typescript
    from_address: string;
```

**L88**
```typescript
    from_name: string;
```

**L89**
```typescript
    occurred_at: string;
```

**L90**
```typescript
    ai_classification: AIClassification | null;
```

**L91**
```typescript
  }>;
```

**L92**
```typescript
  party: {
```

**L93**
```typescript
    id: string;
```

**L94**
```typescript
    name: string;
```

**L95**
```typescript
    country_code: string | null;
```

**L96**
```typescript
    industry_tags: string[] | null;
```

**L97**
```typescript
    tier: string | null;
```

**L98**
```typescript
    module: string | null;
```

**L99**
```typescript
    party_type: string | null;
```

**L100**
```typescript
  } | null;
```

**L101**
```typescript
  contact: {
```

**L102**
```typescript
    id: string;
```

**L103**
```typescript
    given_name: string | null;
```

**L104**
```typescript
    family_name: string | null;
```

**L105**
```typescript
    email: string | null;
```

**L106**
```typescript
    role_title: string | null;
```

**L107**
```typescript
    decision_role: string | null;
```

**L108**
```typescript
  } | null;
```

**L109**
```typescript
}
```

**L110**
```typescript

```

**L111**
```typescript
export interface TemplateForCompose {
```

**L112**
```typescript
  id: string;
```

**L113**
```typescript
  name: string;
```

**L114**
```typescript
  category: string | null;
```

**L115**
```typescript
  subject: string | null;
```

**L116**
```typescript
  body_plain: string | null;
```

**L117**
```typescript
  body_html: string | null;
```

**L118**
```typescript
  module: string | null;
```

**L119**
```typescript
}
```

**L120**
```typescript

```

**L121**
```typescript
export interface ComposeEmailInput {
```

**L122**
```typescript
  party_id: string | null;
```

**L123**
```typescript
  contact_id: string | null;
```

**L124**
```typescript
  to_addresses: string[];
```

**L125**
```typescript
  subject: string;
```

**L126**
```typescript
  body_html: string;
```

**L127**
```typescript
  body_plain: string;
```

**L128**
```typescript
  in_reply_to?: string | null;
```

**L129**
```typescript
  template_id?: string | null;
```

**L130**
```typescript
  ai_generated?: boolean;
```

**L131**
```typescript
  send_now?: boolean;  // if false, save as draft
```

**L132**
```typescript
}
```

**L133**
```typescript

```

**L134**
```typescript
export interface AIReplyRequest {
```

**L135**
```typescript
  in_reply_to_communication_id: string;
```

**L136**
```typescript
  user_instruction?: string;  // optional tone/intent hint
```

**L137**
```typescript
  target_language?: "ko" | "en" | "ja";  // optional override
```

**L138**
```typescript
}
```

**L139**
```typescript

```

**L140**
```typescript
export interface AIComposeRequest {
```

**L141**
```typescript
  party_id: string;
```

**L142**
```typescript
  contact_id: string | null;
```

**L143**
```typescript
  user_instruction: string;  // e.g. "Introduce our PCC product"
```

**L144**
```typescript
  target_language?: "ko" | "en" | "ja";
```

**L145**
```typescript
}
```

**L146**
```typescript

```

**L147**
```typescript
export interface AIComposeResponse {
```

**L148**
```typescript
  subject: string;
```

**L149**
```typescript
  body_plain: string;
```

**L150**
```typescript
  body_html: string;
```

**L151**
```typescript
  language_detected: string;
```

**L152**
```typescript
  reasoning?: string;
```

**L153**
```typescript
}
```

### `src\types\task.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * types/task.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 태스크 목록 + 상세의 데이터 모델.
```

**L5**
```typescript
 */
```

**L6**
```typescript

```

**L7**
```typescript
import type { PartyTypeCode } from './ai';
```

**L8**
```typescript

```

**L9**
```typescript
/** app.task_status enum. */
```

**L10**
```typescript
export type TaskStatus =
```

**L11**
```typescript
  | 'todo'
```

**L12**
```typescript
  | 'in_progress'
```

**L13**
```typescript
  | 'blocked'
```

**L14**
```typescript
  | 'done'
```

**L15**
```typescript
  | 'cancelled';
```

**L16**
```typescript

```

**L17**
```typescript
/** app.priority_level enum. */
```

**L18**
```typescript
export type TaskPriority = 'low' | 'medium' | 'high' | 'urgent';
```

**L19**
```typescript

```

**L20**
```typescript
/** 목록 한 행 (평탄화). */
```

**L21**
```typescript
export interface TaskRow {
```

**L22**
```typescript
  id: string;
```

**L23**
```typescript
  title: string;
```

**L24**
```typescript
  description: string | null;
```

**L25**
```typescript
  status: TaskStatus;
```

**L26**
```typescript
  priority: TaskPriority;
```

**L27**
```typescript
  dueAt: string | null;
```

**L28**
```typescript
  reminderAt: string | null;
```

**L29**
```typescript
  partyType: PartyTypeCode | null;
```

**L30**
```typescript
  partyId: string | null;
```

**L31**
```typescript
  partyName: string | null;
```

**L32**
```typescript
  partyModule: PartyTypeCode | null;
```

**L33**
```typescript
  engagementId: string | null;
```

**L34**
```typescript
  engagementName: string | null;
```

**L35**
```typescript
  assignedToUserId: string | null;
```

**L36**
```typescript
  createdAt: string;
```

**L37**
```typescript
  completedAt: string | null;
```

**L38**
```typescript
  /** AI가 생성한 태스크인지 (linked_strategy_action_id != null) */
```

**L39**
```typescript
  aiSuggested: boolean;
```

**L40**
```typescript
}
```

**L41**
```typescript

```

**L42**
```typescript
export interface TaskFilters {
```

**L43**
```typescript
  status: TaskStatus | 'all' | 'open'; // 'open' = todo + in_progress + blocked
```

**L44**
```typescript
  priority: TaskPriority | 'all';
```

**L45**
```typescript
  partyType: PartyTypeCode | 'all';
```

**L46**
```typescript
  /** true이면 due_at <= now 이면서 status가 done/cancelled 아닌 것만 */
```

**L47**
```typescript
  overdueOnly: boolean;
```

**L48**
```typescript
  /** 특정 거래처 */
```

**L49**
```typescript
  partyId: string | null;
```

**L50**
```typescript
}
```

**L51**
```typescript

```

**L52**
```typescript
export type TaskSort =
```

**L53**
```typescript
  | 'due_soonest'      // due_at ASC (null 마지막)
```

**L54**
```typescript
  | 'priority'         // urgent > high > medium > low, 같으면 due_at ASC
```

**L55**
```typescript
  | 'newest'           // created_at DESC
```

**L56**
```typescript
  | 'oldest';          // created_at ASC
```

**L57**
```typescript

```

**L58**
```typescript
export interface TaskPagination {
```

**L59**
```typescript
  page: number;
```

**L60**
```typescript
  pageSize: number;
```

**L61**
```typescript
}
```

**L62**
```typescript

```

**L63**
```typescript
export interface TaskListResult {
```

**L64**
```typescript
  rows: TaskRow[];
```

**L65**
```typescript
  totalCount: number;
```

**L66**
```typescript
  filters: TaskFilters;
```

**L67**
```typescript
  sort: TaskSort;
```

**L68**
```typescript
  pagination: TaskPagination;
```

**L69**
```typescript
}
```

**L70**
```typescript

```

**L71**
```typescript
export const DEFAULT_TASK_FILTERS: TaskFilters = {
```

**L72**
```typescript
  status: 'open',
```

**L73**
```typescript
  priority: 'all',
```

**L74**
```typescript
  partyType: 'all',
```

**L75**
```typescript
  overdueOnly: false,
```

**L76**
```typescript
  partyId: null,
```

**L77**
```typescript
};
```

**L78**
```typescript
export const DEFAULT_TASK_SORT: TaskSort = 'due_soonest';
```

**L79**
```typescript
export const TASK_DEFAULT_PAGE_SIZE = 25;
```

**L80**
```typescript
export const TASK_PAGE_SIZE_OPTIONS: readonly number[] = [25, 50, 100] as const;
```

### `src\workers\consultation-worker.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * workers/consultation-worker.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * Postgres LISTEN consultation_created 채널을 구독해 새 consultation에 대해
```

**L5**
```typescript
 * strategy_advisor 에이전트를 호출하고 다음을 생성:
```

**L6**
```typescript
 *   - response_strategies 1행
```

**L7**
```typescript
 *   - strategy_actions N행 (immediate / short_term / long_term)
```

**L8**
```typescript
 *   - immediate 액션은 tasks 자동 생성 + linked_task_id back-link
```

**L9**
```typescript
 *
```

**L10**
```typescript
 * 구조:
```

**L11**
```typescript
 *   - processConsultation(): 단위 테스트 가능한 핵심 로직
```

**L12**
```typescript
 *   - main(): pg LISTEN 루프 + graceful shutdown
```

**L13**
```typescript
 *
```

**L14**
```typescript
 * pg.Client를 직접 사용하는 이유:
```

**L15**
```typescript
 *   Supabase JS는 LISTEN/NOTIFY를 지원하지 않음. SUPABASE_DB_URL로 직접 연결.
```

**L16**
```typescript
 */
```

**L17**
```typescript

```

**L18**
```typescript
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
```

**L19**
```typescript
import pg from 'pg';
```

**L20**
```typescript
import { env } from '../lib/env';
```

**L21**
```typescript
import {
```

**L22**
```typescript
  ClaudeClient,
```

**L23**
```typescript
  ClaudeApiError,
```

**L24**
```typescript
  ClaudeBudgetExceededError,
```

**L25**
```typescript
} from '../lib/ai/claude-client';
```

**L26**
```typescript
import { createShutdownController, isMainEntry } from './runtime';
```

**L27**
```typescript

```

**L28**
```typescript
/* ============================================================
```

**L29**
```typescript
 * 1. 타입
```

**L30**
```typescript
 * ============================================================ */
```

**L31**
```typescript

```

**L32**
```typescript
export interface ConsultationNotification {
```

**L33**
```typescript
  consultation_id: string;
```

**L34**
```typescript
  organization_id: string;
```

**L35**
```typescript
  module?: string;
```

**L36**
```typescript
  priority?: string;
```

**L37**
```typescript
  urgency?: string;
```

**L38**
```typescript
}
```

**L39**
```typescript

```

**L40**
```typescript
export interface ProcessConsultationResult {
```

**L41**
```typescript
  consultationId: string;
```

**L42**
```typescript
  strategyId?: string;
```

**L43**
```typescript
  actionsCreated: number;
```

**L44**
```typescript
  tasksCreated: number;
```

**L45**
```typescript
  status: 'completed' | 'failed';
```

**L46**
```typescript
  errorMessage?: string;
```

**L47**
```typescript
}
```

**L48**
```typescript

```

**L49**
```typescript
export interface ProcessConsultationOptions {
```

**L50**
```typescript
  /** 단위 테스트에서 ClaudeClient를 주입. */
```

**L51**
```typescript
  claudeClient?: ClaudeClient;
```

**L52**
```typescript
  /** 단위 테스트에서 시각 고정. */
```

**L53**
```typescript
  nowProvider?: () => Date;
```

**L54**
```typescript
}
```

**L55**
```typescript

```

**L56**
```typescript
interface StrategyData {
```

**L57**
```typescript
  situation_analysis: string;
```

**L58**
```typescript
  key_signals?: string[];
```

**L59**
```typescript
  recommended_approach: string;
```

**L60**
```typescript
  key_messages?: string[];
```

**L61**
```typescript
  risks_to_avoid?: string[];
```

**L62**
```typescript
  questions_to_ask_internally?: string[];
```

**L63**
```typescript
  confidence_score: number;
```

**L64**
```typescript
  requires_human_review?: boolean;
```

**L65**
```typescript
  requires_legal_review?: boolean;
```

**L66**
```typescript
  requires_finance_review?: boolean;
```

**L67**
```typescript
  actions?: Array<{
```

**L68**
```typescript
    title: string;
```

**L69**
```typescript
    description: string;
```

**L70**
```typescript
    action_type: 'immediate' | 'short_term' | 'long_term';
```

**L71**
```typescript
    priority?: string;
```

**L72**
```typescript
    suggested_due_in_hours?: number;
```

**L73**
```typescript
    suggested_due_in_days?: number;
```

**L74**
```typescript
    rationale?: string;
```

**L75**
```typescript
    sort_order?: number;
```

**L76**
```typescript
  }>;
```

**L77**
```typescript
}
```

**L78**
```typescript

```

**L79**
```typescript
/* ============================================================
```

**L80**
```typescript
 * 2. processConsultation — 핵심 로직 (테스트 표면)
```

**L81**
```typescript
 * ============================================================ */
```

**L82**
```typescript

```

**L83**
```typescript
export async function processConsultation(
```

**L84**
```typescript
  supabase: SupabaseClient,
```

**L85**
```typescript
  notification: ConsultationNotification,
```

**L86**
```typescript
  options: ProcessConsultationOptions = {},
```

**L87**
```typescript
): Promise<ProcessConsultationResult> {
```

**L88**
```typescript
  const { consultation_id: consultationId, organization_id: orgId } = notification;
```

**L89**
```typescript
  const now = options.nowProvider ?? (() => new Date());
```

**L90**
```typescript

```

**L91**
```typescript
  // [1] consultation 조회
```

**L92**
```typescript
  const { data: consultation, error: consultError } = await supabase
```

**L93**
```typescript
    .schema('app')
```

**L94**
```typescript
    .from('consultations')
```

**L95**
```typescript
    .select(
```

**L96**
```typescript
      'id, organization_id, party_id, engagement_id, module, content_raw, content_processed, language, priority, urgency, ai_processing_status',
```

**L97**
```typescript
    )
```

**L98**
```typescript
    .eq('id', consultationId)
```

**L99**
```typescript
    .eq('organization_id', orgId)
```

**L100**
```typescript
    .maybeSingle();
```

**L101**
```typescript

```

**L102**
```typescript
  if (consultError || !consultation) {
```

**L103**
```typescript
    return {
```

**L104**
```typescript
      consultationId,
```

**L105**
```typescript
      actionsCreated: 0,
```

**L106**
```typescript
      tasksCreated: 0,
```

**L107**
```typescript
      status: 'failed',
```

**L108**
```typescript
      errorMessage: consultError?.message ?? 'consultation not found',
```

**L109**
```typescript
    };
```

**L110**
```typescript
  }
```

**L111**
```typescript

```

**L112**
```typescript
  // 멱등성: 이미 처리되었으면 skip
```

**L113**
```typescript
  if (consultation.ai_processing_status === 'completed') {
```

**L114**
```typescript
    return {
```

**L115**
```typescript
      consultationId,
```

**L116**
```typescript
      actionsCreated: 0,
```

**L117**
```typescript
      tasksCreated: 0,
```

**L118**
```typescript
      status: 'completed',
```

**L119**
```typescript
      errorMessage: 'already_completed',
```

**L120**
```typescript
    };
```

**L121**
```typescript
  }
```

**L122**
```typescript

```

**L123**
```typescript
  // [2] processing 마킹
```

**L124**
```typescript
  await supabase
```

**L125**
```typescript
    .schema('app')
```

**L126**
```typescript
    .from('consultations')
```

**L127**
```typescript
    .update({
```

**L128**
```typescript
      ai_processing_status: 'processing',
```

**L129**
```typescript
      ai_processing_started_at: now().toISOString(),
```

**L130**
```typescript
    })
```

**L131**
```typescript
    .eq('id', consultationId)
```

**L132**
```typescript
    .eq('organization_id', orgId);
```

**L133**
```typescript

```

**L134**
```typescript
  try {
```

**L135**
```typescript
    // [3] strategy_advisor 호출
```

**L136**
```typescript
    const claude = options.claudeClient ?? new ClaudeClient(supabase, orgId);
```

**L137**
```typescript
    const inboundMessage =
```

**L138**
```typescript
      (consultation.content_processed as string | null) ??
```

**L139**
```typescript
      (consultation.content_raw as string | null) ??
```

**L140**
```typescript
      '';
```

**L141**
```typescript
    const language = ((consultation.language as string | null) ?? 'ko') as 'ko' | 'en' | 'ja';
```

**L142**
```typescript

```

**L143**
```typescript
    const result = await claude.complete({
```

**L144**
```typescript
      agentRole: 'strategy_advisor',
```

**L145**
```typescript
      inboundMessage,
```

**L146**
```typescript
      partyId: (consultation.party_id as string | null) ?? undefined,
```

**L147**
```typescript
      engagementId: (consultation.engagement_id as string | null) ?? undefined,
```

**L148**
```typescript
      language,
```

**L149**
```typescript
      outputFormat: 'json',
```

**L150**
```typescript
      traceLabel: `consultation:${consultationId}`,
```

**L151**
```typescript
    });
```

**L152**
```typescript

```

**L153**
```typescript
    const strategyData = result.parsedJson as StrategyData | undefined;
```

**L154**
```typescript
    if (!strategyData || typeof strategyData.recommended_approach !== 'string') {
```

**L155**
```typescript
      throw new Error('strategy_advisor returned invalid JSON structure');
```

**L156**
```typescript
    }
```

**L157**
```typescript

```

**L158**
```typescript
    // [4] response_strategies INSERT
```

**L159**
```typescript
    const { data: strategyRow, error: strategyError } = await supabase
```

**L160**
```typescript
      .schema('app')
```

**L161**
```typescript
      .from('response_strategies')
```

**L162**
```typescript
      .insert({
```

**L163**
```typescript
        organization_id: orgId,
```

**L164**
```typescript
        consultation_id: consultationId,
```

**L165**
```typescript
        engagement_id: consultation.engagement_id ?? null,
```

**L166**
```typescript
        party_id: consultation.party_id ?? null,
```

**L167**
```typescript
        module: consultation.module ?? null,
```

**L168**
```typescript
        run_id: result.runId,
```

**L169**
```typescript
        ai_generated: true,
```

**L170**
```typescript
        situation_analysis: strategyData.situation_analysis,
```

**L171**
```typescript
        key_signals: strategyData.key_signals ?? [],
```

**L172**
```typescript
        recommended_approach: strategyData.recommended_approach,
```

**L173**
```typescript
        key_messages: strategyData.key_messages ?? [],
```

**L174**
```typescript
        risks_to_avoid: strategyData.risks_to_avoid ?? [],
```

**L175**
```typescript
        questions_to_ask_internally:
```

**L176**
```typescript
          strategyData.questions_to_ask_internally ?? [],
```

**L177**
```typescript
        confidence_score: strategyData.confidence_score,
```

**L178**
```typescript
        requires_human_review: strategyData.requires_human_review ?? true,
```

**L179**
```typescript
        requires_legal_review: strategyData.requires_legal_review ?? false,
```

**L180**
```typescript
        requires_finance_review: strategyData.requires_finance_review ?? false,
```

**L181**
```typescript
        raw_ai_output: strategyData,
```

**L182**
```typescript
        status: 'draft',
```

**L183**
```typescript
      })
```

**L184**
```typescript
      .select('id')
```

**L185**
```typescript
      .single();
```

**L186**
```typescript

```

**L187**
```typescript
    if (strategyError || !strategyRow) {
```

**L188**
```typescript
      throw new Error(
```

**L189**
```typescript
        `response_strategies INSERT failed: ${strategyError?.message ?? 'unknown'}`,
```

**L190**
```typescript
      );
```

**L191**
```typescript
    }
```

**L192**
```typescript

```

**L193**
```typescript
    const strategyId = strategyRow.id as string;
```

**L194**
```typescript

```

**L195**
```typescript
    // [5] strategy_actions + tasks (immediate)
```

**L196**
```typescript
    let actionsCreated = 0;
```

**L197**
```typescript
    let tasksCreated = 0;
```

**L198**
```typescript
    for (const action of strategyData.actions ?? []) {
```

**L199**
```typescript
      const { data: actionRow, error: actionError } = await supabase
```

**L200**
```typescript
        .schema('app')
```

**L201**
```typescript
        .from('strategy_actions')
```

**L202**
```typescript
        .insert({
```

**L203**
```typescript
          organization_id: orgId,
```

**L204**
```typescript
          strategy_id: strategyId,
```

**L205**
```typescript
          title: action.title,
```

**L206**
```typescript
          description: action.description,
```

**L207**
```typescript
          action_type: action.action_type,
```

**L208**
```typescript
          priority: action.priority ?? 'medium',
```

**L209**
```typescript
          suggested_due_in_hours: action.suggested_due_in_hours ?? null,
```

**L210**
```typescript
          suggested_due_in_days: action.suggested_due_in_days ?? null,
```

**L211**
```typescript
          rationale: action.rationale ?? null,
```

**L212**
```typescript
          sort_order: action.sort_order ?? 0,
```

**L213**
```typescript
        })
```

**L214**
```typescript
        .select('id')
```

**L215**
```typescript
        .single();
```

**L216**
```typescript

```

**L217**
```typescript
      if (actionError || !actionRow) {
```

**L218**
```typescript
        // 단건 액션 실패는 다음 액션에 영향 없음
```

**L219**
```typescript
        // eslint-disable-next-line no-console
```

**L220**
```typescript
        console.error(
```

**L221**
```typescript
          `[consultation-worker] strategy_action INSERT failed:`,
```

**L222**
```typescript
          actionError,
```

**L223**
```typescript
        );
```

**L224**
```typescript
        continue;
```

**L225**
```typescript
      }
```

**L226**
```typescript
      actionsCreated += 1;
```

**L227**
```typescript

```

**L228**
```typescript
      if (action.action_type === 'immediate') {
```

**L229**
```typescript
        const dueAt =
```

**L230**
```typescript
          action.suggested_due_in_hours !== undefined &&
```

**L231**
```typescript
          action.suggested_due_in_hours !== null
```

**L232**
```typescript
            ? new Date(
```

**L233**
```typescript
                now().getTime() + action.suggested_due_in_hours * 3_600_000,
```

**L234**
```typescript
              ).toISOString()
```

**L235**
```typescript
            : null;
```

**L236**
```typescript

```

**L237**
```typescript
        const { data: taskRow } = await supabase
```

**L238**
```typescript
          .schema('app')
```

**L239**
```typescript
          .from('tasks')
```

**L240**
```typescript
          .insert({
```

**L241**
```typescript
            organization_id: orgId,
```

**L242**
```typescript
            party_id: consultation.party_id ?? null,
```

**L243**
```typescript
            engagement_id: consultation.engagement_id ?? null,
```

**L244**
```typescript
            module: consultation.module ?? null,
```

**L245**
```typescript
            title: action.title,
```

**L246**
```typescript
            description: action.description,
```

**L247**
```typescript
            priority: action.priority ?? 'high',
```

**L248**
```typescript
            status: 'todo',
```

**L249**
```typescript
            due_at: dueAt,
```

**L250**
```typescript
            linked_strategy_action_id: actionRow.id,
```

**L251**
```typescript
          })
```

**L252**
```typescript
          .select('id')
```

**L253**
```typescript
          .single();
```

**L254**
```typescript

```

**L255**
```typescript
        if (taskRow) {
```

**L256**
```typescript
          tasksCreated += 1;
```

**L257**
```typescript
          await supabase
```

**L258**
```typescript
            .schema('app')
```

**L259**
```typescript
            .from('strategy_actions')
```

**L260**
```typescript
            .update({ linked_task_id: taskRow.id })
```

**L261**
```typescript
            .eq('id', actionRow.id);
```

**L262**
```typescript
        }
```

**L263**
```typescript
      }
```

**L264**
```typescript
    }
```

**L265**
```typescript

```

**L266**
```typescript
    // [6] consultation 완료 마킹
```

**L267**
```typescript
    await supabase
```

**L268**
```typescript
      .schema('app')
```

**L269**
```typescript
      .from('consultations')
```

**L270**
```typescript
      .update({
```

**L271**
```typescript
        ai_processing_status: 'completed',
```

**L272**
```typescript
        ai_processing_completed_at: now().toISOString(),
```

**L273**
```typescript
      })
```

**L274**
```typescript
      .eq('id', consultationId)
```

**L275**
```typescript
      .eq('organization_id', orgId);
```

**L276**
```typescript

```

**L277**
```typescript
    return {
```

**L278**
```typescript
      consultationId,
```

**L279**
```typescript
      strategyId,
```

**L280**
```typescript
      actionsCreated,
```

**L281**
```typescript
      tasksCreated,
```

**L282**
```typescript
      status: 'completed',
```

**L283**
```typescript
    };
```

**L284**
```typescript
  } catch (err) {
```

**L285**
```typescript
    const errorMessage = err instanceof Error ? err.message : String(err);
```

**L286**
```typescript
    const isBudget = err instanceof ClaudeBudgetExceededError;
```

**L287**
```typescript
    const isApiTransient =
```

**L288**
```typescript
      err instanceof ClaudeApiError &&
```

**L289**
```typescript
      (err.status === undefined || err.status >= 500 || err.status === 429);
```

**L290**
```typescript

```

**L291**
```typescript
    await supabase
```

**L292**
```typescript
      .schema('app')
```

**L293**
```typescript
      .from('consultations')
```

**L294**
```typescript
      .update({
```

**L295**
```typescript
        ai_processing_status: 'failed',
```

**L296**
```typescript
        ai_processing_error_message: errorMessage,
```

**L297**
```typescript
        ai_processing_failed_at: now().toISOString(),
```

**L298**
```typescript
        ai_processing_retryable: isApiTransient && !isBudget,
```

**L299**
```typescript
      })
```

**L300**
```typescript
      .eq('id', consultationId)
```

**L301**
```typescript
      .eq('organization_id', orgId);
```

**L302**
```typescript

```

**L303**
```typescript
    return {
```

**L304**
```typescript
      consultationId,
```

**L305**
```typescript
      actionsCreated: 0,
```

**L306**
```typescript
      tasksCreated: 0,
```

**L307**
```typescript
      status: 'failed',
```

**L308**
```typescript
      errorMessage,
```

**L309**
```typescript
    };
```

**L310**
```typescript
  }
```

**L311**
```typescript
}
```

**L312**
```typescript

```

**L313**
```typescript
/* ============================================================
```

**L314**
```typescript
 * 3. main — pg LISTEN 루프 + graceful shutdown
```

**L315**
```typescript
 * ============================================================ */
```

**L316**
```typescript

```

**L317**
```typescript
async function main(): Promise<void> {
```

**L318**
```typescript
  const supabase = createClient(
```

**L319**
```typescript
    env.NEXT_PUBLIC_SUPABASE_URL,
```

**L320**
```typescript
    env.SUPABASE_SERVICE_ROLE_KEY,
```

**L321**
```typescript
  );
```

**L322**
```typescript

```

**L323**
```typescript
  const pgClient = new pg.Client({ connectionString: env.SUPABASE_DB_URL });
```

**L324**
```typescript
  await pgClient.connect();
```

**L325**
```typescript
  await pgClient.query('LISTEN consultation_created');
```

**L326**
```typescript

```

**L327**
```typescript
  const ctl = createShutdownController('consultation-worker');
```

**L328**
```typescript

```

**L329**
```typescript
  pgClient.on('notification', (msg) => {
```

**L330**
```typescript
    if (ctl.isShuttingDown()) return;
```

**L331**
```typescript
    if (msg.channel !== 'consultation_created' || !msg.payload) return;
```

**L332**
```typescript
    let parsed: ConsultationNotification;
```

**L333**
```typescript
    try {
```

**L334**
```typescript
      parsed = JSON.parse(msg.payload) as ConsultationNotification;
```

**L335**
```typescript
    } catch (err) {
```

**L336**
```typescript
      // eslint-disable-next-line no-console
```

**L337**
```typescript
      console.error('[consultation-worker] payload parse failed:', err);
```

**L338**
```typescript
      return;
```

**L339**
```typescript
    }
```

**L340**
```typescript
    if (!parsed.consultation_id || !parsed.organization_id) return;
```

**L341**
```typescript

```

**L342**
```typescript
    void ctl.track(
```

**L343**
```typescript
      processConsultation(supabase, parsed)
```

**L344**
```typescript
        .then((result) => {
```

**L345**
```typescript
          // eslint-disable-next-line no-console
```

**L346**
```typescript
          console.log(
```

**L347**
```typescript
            `[consultation-worker] processed consultation=${result.consultationId} status=${result.status} actions=${result.actionsCreated} tasks=${result.tasksCreated}`,
```

**L348**
```typescript
          );
```

**L349**
```typescript
        })
```

**L350**
```typescript
        .catch((err) => {
```

**L351**
```typescript
          // eslint-disable-next-line no-console
```

**L352**
```typescript
          console.error(
```

**L353**
```typescript
            `[consultation-worker] processConsultation threw:`,
```

**L354**
```typescript
            err,
```

**L355**
```typescript
          );
```

**L356**
```typescript
        }),
```

**L357**
```typescript
    );
```

**L358**
```typescript
  });
```

**L359**
```typescript

```

**L360**
```typescript
  // eslint-disable-next-line no-console
```

**L361**
```typescript
  console.log('[consultation-worker] listening on consultation_created');
```

**L362**
```typescript

```

**L363**
```typescript
  // 셧다운 시그널이 올 때까지 대기 — sleep(Infinity) 대신 짧은 대기 반복
```

**L364**
```typescript
  while (!ctl.isShuttingDown()) {
```

**L365**
```typescript
    await ctl.sleep(60_000);
```

**L366**
```typescript
  }
```

**L367**
```typescript

```

**L368**
```typescript
  // graceful shutdown
```

**L369**
```typescript
  await ctl.waitForInflight(30_000);
```

**L370**
```typescript
  try {
```

**L371**
```typescript
    await pgClient.query('UNLISTEN consultation_created');
```

**L372**
```typescript
    await pgClient.end();
```

**L373**
```typescript
  } catch (err) {
```

**L374**
```typescript
    // eslint-disable-next-line no-console
```

**L375**
```typescript
    console.warn('[consultation-worker] pg client cleanup error:', err);
```

**L376**
```typescript
  }
```

**L377**
```typescript
  // eslint-disable-next-line no-console
```

**L378**
```typescript
  console.log('[consultation-worker] shutdown complete');
```

**L379**
```typescript
}
```

**L380**
```typescript

```

**L381**
```typescript
if (isMainEntry(import.meta.url)) {
```

**L382**
```typescript
  main().catch((err) => {
```

**L383**
```typescript
    // eslint-disable-next-line no-console
```

**L384**
```typescript
    console.error('[consultation-worker] fatal:', err);
```

**L385**
```typescript
    process.exit(1);
```

**L386**
```typescript
  });
```

**L387**
```typescript
}
```

### `src\workers\draft-expiry-worker.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * workers/draft-expiry-worker.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 만료된 ai.drafts 행의 status를 'expired'로 갱신.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * 호출 방식:
```

**L7**
```typescript
 *   - Vercel Cron (`vercel.json`의 `"schedule": "0 * * * *"`) 매시간 1회
```

**L8**
```typescript
 *   - 또는 stand-alone Node 워커: `tsx src/workers/draft-expiry-worker.ts`
```

**L9**
```typescript
 *
```

**L10**
```typescript
 * SQL 측 함수 ai.expire_stale_drafts()가 다음을 수행:
```

**L11**
```typescript
 *   - WHERE status = 'pending_review' AND expires_at < NOW() AND expired_handled = false
```

**L12**
```typescript
 *   - UPDATE status='expired', expired_handled=true
```

**L13**
```typescript
 *   - 만료된 건수를 (expired_count int, organization_id uuid) 형태로 반환
```

**L14**
```typescript
 */
```

**L15**
```typescript

```

**L16**
```typescript
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
```

**L17**
```typescript
import { env } from '../lib/env';
```

**L18**
```typescript
import { isMainEntry } from './runtime';
```

**L19**
```typescript

```

**L20**
```typescript
export interface ExpireResult {
```

**L21**
```typescript
  expired: number;
```

**L22**
```typescript
  ranAt: string;
```

**L23**
```typescript
}
```

**L24**
```typescript

```

**L25**
```typescript
/**
```

**L26**
```typescript
 * 단위 테스트 가능한 핵심 로직.
```

**L27**
```typescript
 * supabase 클라이언트를 외부에서 주입.
```

**L28**
```typescript
 */
```

**L29**
```typescript
export async function expireStaleDrafts(
```

**L30**
```typescript
  supabase: SupabaseClient,
```

**L31**
```typescript
): Promise<ExpireResult> {
```

**L32**
```typescript
  const ranAt = new Date().toISOString();
```

**L33**
```typescript

```

**L34**
```typescript
  const { data, error } = await supabase
```

**L35**
```typescript
    .schema('ai')
```

**L36**
```typescript
    .rpc('expire_stale_drafts');
```

**L37**
```typescript

```

**L38**
```typescript
  if (error) {
```

**L39**
```typescript
    // eslint-disable-next-line no-console
```

**L40**
```typescript
    console.error('[draft-expiry-worker] rpc failed:', error);
```

**L41**
```typescript
    throw new Error(`expire_stale_drafts RPC failed: ${error.message}`);
```

**L42**
```typescript
  }
```

**L43**
```typescript

```

**L44**
```typescript
  // RPC 응답 형식: RETURNS TABLE (expired_count int, organization_id uuid)
```

**L45**
```typescript
  // → 행 배열로 반환 (organization별 그룹). 모든 행의 expired_count를 합산.
```

**L46**
```typescript
  let expired = 0;
```

**L47**
```typescript
  if (Array.isArray(data)) {
```

**L48**
```typescript
    expired = data.reduce(
```

**L49**
```typescript
      (sum: number, row: unknown) => {
```

**L50**
```typescript
        if (row && typeof row === 'object') {
```

**L51**
```typescript
          const n = (row as { expired_count?: unknown }).expired_count;
```

**L52**
```typescript
          if (typeof n === 'number') return sum + n;
```

**L53**
```typescript
        }
```

**L54**
```typescript
        return sum;
```

**L55**
```typescript
      },
```

**L56**
```typescript
      0,
```

**L57**
```typescript
    );
```

**L58**
```typescript
  } else if (data && typeof data === 'object') {
```

**L59**
```typescript
    // 단일 행 fallback
```

**L60**
```typescript
    const n = (data as { expired_count?: unknown }).expired_count;
```

**L61**
```typescript
    if (typeof n === 'number') expired = n;
```

**L62**
```typescript
  } else if (typeof data === 'number') {
```

**L63**
```typescript
    // scalar fallback
```

**L64**
```typescript
    expired = data;
```

**L65**
```typescript
  }
```

**L66**
```typescript

```

**L67**
```typescript
  // eslint-disable-next-line no-console
```

**L68**
```typescript
  console.log(
```

**L69**
```typescript
    `[draft-expiry-worker] expired ${expired} drafts at ${ranAt}`,
```

**L70**
```typescript
  );
```

**L71**
```typescript

```

**L72**
```typescript
  return { expired, ranAt };
```

**L73**
```typescript
}
```

**L74**
```typescript

```

**L75**
```typescript
async function main(): Promise<void> {
```

**L76**
```typescript
  const supabase = createClient(
```

**L77**
```typescript
    env.NEXT_PUBLIC_SUPABASE_URL,
```

**L78**
```typescript
    env.SUPABASE_SERVICE_ROLE_KEY,
```

**L79**
```typescript
  );
```

**L80**
```typescript
  await expireStaleDrafts(supabase);
```

**L81**
```typescript
}
```

**L82**
```typescript

```

**L83**
```typescript
if (isMainEntry(import.meta.url)) {
```

**L84**
```typescript
  main()
```

**L85**
```typescript
    .then(() => process.exit(0))
```

**L86**
```typescript
    .catch((err) => {
```

**L87**
```typescript
      // eslint-disable-next-line no-console
```

**L88**
```typescript
      console.error('[draft-expiry-worker] fatal:', err);
```

**L89**
```typescript
      process.exit(1);
```

**L90**
```typescript
    });
```

**L91**
```typescript
}
```

### `src\workers\mail-merge-worker.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * workers/mail-merge-worker.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * mail_merge_jobs 테이블을 폴링해 큐에 들어온 잡을 처리:
```

**L5**
```typescript
 *   1. 잡 상태가 queued이고 scheduled_at이 도달한 잡 N건 fetch
```

**L6**
```typescript
 *   2. tabs_campaign_id가 없으면 TABS Mailer createCampaign 호출
```

**L7**
```typescript
 *   3. 잡 상태를 running으로 갱신
```

**L8**
```typescript
 *   4. 통계 동기화 (syncCampaignToMergeJob) — 별도 5분 주기 권장이나 본 워커가 함께 수행
```

**L9**
```typescript
 *   5. 실패 시 exponential backoff retry (max_retries 도달 시 status='failed')
```

**L10**
```typescript
 *
```

**L11**
```typescript
 * 수신자 명단 해석(recipient_filter jsonb → SQL → 발송)은 STEP 7 운영 정보 수령 후
```

**L12**
```typescript
 * 추가. 본 STEP 3에서는 캠페인 등록·상태 동기화에 집중.
```

**L13**
```typescript
 */
```

**L14**
```typescript

```

**L15**
```typescript
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
```

**L16**
```typescript
import { env } from '../lib/env';
```

**L17**
```typescript
import {
```

**L18**
```typescript
  createTabsMailer,
```

**L19**
```typescript
  TabsMailerError,
```

**L20**
```typescript
  TabsMailerNotImplementedError,
```

**L21**
```typescript
  type ITabsMailerClient,
```

**L22**
```typescript
} from '../lib/email/tabs-mailer';
```

**L23**
```typescript
import { evaluateQuietHours } from '../lib/email/quiet-hours';
```

**L24**
```typescript
import {
```

**L25**
```typescript
  mapMailMergeJobRow,
```

**L26**
```typescript
  type MailMergeJobRow,
```

**L27**
```typescript
} from '../types/email';
```

**L28**
```typescript
import { createShutdownController, isMainEntry } from './runtime';
```

**L29**
```typescript

```

**L30**
```typescript
const POLL_INTERVAL_MS = 10_000;
```

**L31**
```typescript
const BATCH_SIZE = 5;
```

**L32**
```typescript
const STATS_SYNC_BATCH_SIZE = 10;
```

**L33**
```typescript

```

**L34**
```typescript
export interface ProcessJobOptions {
```

**L35**
```typescript
  /** 단위 테스트에서 TabsMailer를 주입. */
```

**L36**
```typescript
  mailer?: ITabsMailerClient;
```

**L37**
```typescript
  /** 시각 고정. */
```

**L38**
```typescript
  nowProvider?: () => Date;
```

**L39**
```typescript
}
```

**L40**
```typescript

```

**L41**
```typescript
export interface ProcessJobResult {
```

**L42**
```typescript
  jobId: string;
```

**L43**
```typescript
  status: 'started' | 'rescheduled_quiet_hours' | 'failed' | 'skipped';
```

**L44**
```typescript
  tabsCampaignId?: string;
```

**L45**
```typescript
  errorMessage?: string;
```

**L46**
```typescript
  nextSendAt?: string;
```

**L47**
```typescript
}
```

**L48**
```typescript

```

**L49**
```typescript
/* ============================================================
```

**L50**
```typescript
 * 1. processOneJob — 단일 잡 처리 (테스트 표면)
```

**L51**
```typescript
 * ============================================================ */
```

**L52**
```typescript

```

**L53**
```typescript
export async function processOneJob(
```

**L54**
```typescript
  supabase: SupabaseClient,
```

**L55**
```typescript
  job: MailMergeJobRow,
```

**L56**
```typescript
  options: ProcessJobOptions = {},
```

**L57**
```typescript
): Promise<ProcessJobResult> {
```

**L58**
```typescript
  const now = options.nowProvider ?? (() => new Date());
```

**L59**
```typescript

```

**L60**
```typescript
  // 컴플라이언스: legal 승인이 필요한데 미승인이면 skip
```

**L61**
```typescript
  if (job.requiresLegalApproval && !job.legalApprovedAt) {
```

**L62**
```typescript
    return {
```

**L63**
```typescript
      jobId: job.id,
```

**L64**
```typescript
      status: 'skipped',
```

**L65**
```typescript
      errorMessage: 'legal_approval_pending',
```

**L66**
```typescript
    };
```

**L67**
```typescript
  }
```

**L68**
```typescript

```

**L69**
```typescript
  // Quiet hours 사전 검증 — 진입 시 차단되면 next_send_at으로 미루기
```

**L70**
```typescript
  const quiet = evaluateQuietHours(job.quietHours, now());
```

**L71**
```typescript
  if (quiet.blocked) {
```

**L72**
```typescript
    await supabase
```

**L73**
```typescript
      .schema('app')
```

**L74**
```typescript
      .from('mail_merge_jobs')
```

**L75**
```typescript
      .update({
```

**L76**
```typescript
        scheduled_at: quiet.nextAllowedAt ?? new Date(now().getTime() + 30 * 60_000).toISOString(),
```

**L77**
```typescript
        last_error_message: `quiet_hours_blocked:${quiet.reason ?? 'unknown'}`,
```

**L78**
```typescript
      })
```

**L79**
```typescript
      .eq('id', job.id)
```

**L80**
```typescript
      .eq('organization_id', job.organizationId);
```

**L81**
```typescript

```

**L82**
```typescript
    return {
```

**L83**
```typescript
      jobId: job.id,
```

**L84**
```typescript
      status: 'rescheduled_quiet_hours',
```

**L85**
```typescript
      nextSendAt: quiet.nextAllowedAt,
```

**L86**
```typescript
    };
```

**L87**
```typescript
  }
```

**L88**
```typescript

```

**L89**
```typescript
  const mailer = options.mailer ?? (await createTabsMailer());
```

**L90**
```typescript

```

**L91**
```typescript
  try {
```

**L92**
```typescript
    // 캠페인 미등록이면 등록
```

**L93**
```typescript
    let tabsCampaignId = job.tabsCampaignId;
```

**L94**
```typescript
    if (!tabsCampaignId) {
```

**L95**
```typescript
      const created = await mailer.createCampaign({
```

**L96**
```typescript
        name: job.name,
```

**L97**
```typescript
        description: job.description,
```

**L98**
```typescript
        templateId: job.templateId,
```

**L99**
```typescript
        scheduledAt: job.scheduledAt ? new Date(job.scheduledAt) : undefined,
```

**L100**
```typescript
        recipientCount: job.estimatedRecipientCount ?? 0,
```

**L101**
```typescript
        fromAddress: job.fromAddress,
```

**L102**
```typescript
        fromName: job.fromName,
```

**L103**
```typescript
        replyToAddress: job.replyToAddress,
```

**L104**
```typescript
      });
```

**L105**
```typescript
      tabsCampaignId = created.tabsCampaignId;
```

**L106**
```typescript

```

**L107**
```typescript
      await supabase
```

**L108**
```typescript
        .schema('app')
```

**L109**
```typescript
        .from('mail_merge_jobs')
```

**L110**
```typescript
        .update({
```

**L111**
```typescript
          tabs_campaign_id: tabsCampaignId,
```

**L112**
```typescript
          tabs_campaign_status: 'created',
```

**L113**
```typescript
          status: 'running',
```

**L114**
```typescript
          started_at: now().toISOString(),
```

**L115**
```typescript
        })
```

**L116**
```typescript
        .eq('id', job.id)
```

**L117**
```typescript
        .eq('organization_id', job.organizationId);
```

**L118**
```typescript
    }
```

**L119**
```typescript

```

**L120**
```typescript
    return {
```

**L121**
```typescript
      jobId: job.id,
```

**L122**
```typescript
      status: 'started',
```

**L123**
```typescript
      tabsCampaignId,
```

**L124**
```typescript
    };
```

**L125**
```typescript
  } catch (err) {
```

**L126**
```typescript
    return await handleJobFailure(supabase, job, err, now());
```

**L127**
```typescript
  }
```

**L128**
```typescript
}
```

**L129**
```typescript

```

**L130**
```typescript
/* ============================================================
```

**L131**
```typescript
 * 2. 실패 처리 — exponential backoff
```

**L132**
```typescript
 * ============================================================ */
```

**L133**
```typescript

```

**L134**
```typescript
async function handleJobFailure(
```

**L135**
```typescript
  supabase: SupabaseClient,
```

**L136**
```typescript
  job: MailMergeJobRow,
```

**L137**
```typescript
  err: unknown,
```

**L138**
```typescript
  now: Date,
```

**L139**
```typescript
): Promise<ProcessJobResult> {
```

**L140**
```typescript
  const errorMessage = err instanceof Error ? err.message : String(err);
```

**L141**
```typescript
  const newRetryCount = job.retryCount + 1;
```

**L142**
```typescript
  const isPermanent = err instanceof TabsMailerNotImplementedError;
```

**L143**
```typescript
  const maxRetriesReached = newRetryCount >= job.maxRetries;
```

**L144**
```typescript
  const shouldFail = isPermanent || maxRetriesReached;
```

**L145**
```typescript

```

**L146**
```typescript
  const backoffSec = Math.min(Math.pow(2, newRetryCount) * 60, 3600);
```

**L147**
```typescript
  const rescheduleAt = new Date(now.getTime() + backoffSec * 1000).toISOString();
```

**L148**
```typescript

```

**L149**
```typescript
  await supabase
```

**L150**
```typescript
    .schema('app')
```

**L151**
```typescript
    .from('mail_merge_jobs')
```

**L152**
```typescript
    .update({
```

**L153**
```typescript
      status: shouldFail ? 'failed' : 'queued',
```

**L154**
```typescript
      retry_count: newRetryCount,
```

**L155**
```typescript
      error_message: errorMessage,
```

**L156**
```typescript
      last_error_at: now.toISOString(),
```

**L157**
```typescript
      scheduled_at: shouldFail ? job.scheduledAt : rescheduleAt,
```

**L158**
```typescript
    })
```

**L159**
```typescript
    .eq('id', job.id)
```

**L160**
```typescript
    .eq('organization_id', job.organizationId);
```

**L161**
```typescript

```

**L162**
```typescript
  return {
```

**L163**
```typescript
    jobId: job.id,
```

**L164**
```typescript
    status: 'failed',
```

**L165**
```typescript
    errorMessage,
```

**L166**
```typescript
    nextSendAt: shouldFail ? undefined : rescheduleAt,
```

**L167**
```typescript
  };
```

**L168**
```typescript
}
```

**L169**
```typescript

```

**L170**
```typescript
/* ============================================================
```

**L171**
```typescript
 * 3. processQueueBatch — 큐 일괄 처리
```

**L172**
```typescript
 * ============================================================ */
```

**L173**
```typescript

```

**L174**
```typescript
export async function processQueueBatch(
```

**L175**
```typescript
  supabase: SupabaseClient,
```

**L176**
```typescript
  options: ProcessJobOptions = {},
```

**L177**
```typescript
): Promise<ProcessJobResult[]> {
```

**L178**
```typescript
  const now = options.nowProvider ?? (() => new Date());
```

**L179**
```typescript

```

**L180**
```typescript
  const { data: jobsRaw, error } = await supabase
```

**L181**
```typescript
    .schema('app')
```

**L182**
```typescript
    .from('mail_merge_jobs')
```

**L183**
```typescript
    .select('*')
```

**L184**
```typescript
    .eq('status', 'queued')
```

**L185**
```typescript
    .lte('scheduled_at', now().toISOString())
```

**L186**
```typescript
    .order('scheduled_at', { ascending: true })
```

**L187**
```typescript
    .limit(BATCH_SIZE);
```

**L188**
```typescript

```

**L189**
```typescript
  if (error) {
```

**L190**
```typescript
    // eslint-disable-next-line no-console
```

**L191**
```typescript
    console.error('[mail-merge-worker] queue fetch failed:', error);
```

**L192**
```typescript
    return [];
```

**L193**
```typescript
  }
```

**L194**
```typescript

```

**L195**
```typescript
  if (!jobsRaw || jobsRaw.length === 0) return [];
```

**L196**
```typescript

```

**L197**
```typescript
  const results: ProcessJobResult[] = [];
```

**L198**
```typescript
  for (const raw of jobsRaw) {
```

**L199**
```typescript
    const job = mapMailMergeJobRow(raw as Record<string, unknown>);
```

**L200**
```typescript
    const r = await processOneJob(supabase, job, options);
```

**L201**
```typescript
    results.push(r);
```

**L202**
```typescript
  }
```

**L203**
```typescript
  return results;
```

**L204**
```typescript
}
```

**L205**
```typescript

```

**L206**
```typescript
/* ============================================================
```

**L207**
```typescript
 * 4. syncRunningCampaigns — 진행 중인 캠페인 통계 동기화
```

**L208**
```typescript
 * ============================================================ */
```

**L209**
```typescript

```

**L210**
```typescript
export async function syncRunningCampaigns(
```

**L211**
```typescript
  supabase: SupabaseClient,
```

**L212**
```typescript
  organizationIds: string[],
```

**L213**
```typescript
  options: ProcessJobOptions = {},
```

**L214**
```typescript
): Promise<{ synced: number; failed: number }> {
```

**L215**
```typescript
  if (organizationIds.length === 0) return { synced: 0, failed: 0 };
```

**L216**
```typescript

```

**L217**
```typescript
  const { data: jobsRaw } = await supabase
```

**L218**
```typescript
    .schema('app')
```

**L219**
```typescript
    .from('mail_merge_jobs')
```

**L220**
```typescript
    .select('id, organization_id, tabs_campaign_id')
```

**L221**
```typescript
    .eq('status', 'running')
```

**L222**
```typescript
    .in('organization_id', organizationIds)
```

**L223**
```typescript
    .not('tabs_campaign_id', 'is', null)
```

**L224**
```typescript
    .limit(STATS_SYNC_BATCH_SIZE);
```

**L225**
```typescript

```

**L226**
```typescript
  if (!jobsRaw || jobsRaw.length === 0) return { synced: 0, failed: 0 };
```

**L227**
```typescript

```

**L228**
```typescript
  const mailer = options.mailer ?? (await createTabsMailer());
```

**L229**
```typescript
  let synced = 0;
```

**L230**
```typescript
  let failed = 0;
```

**L231**
```typescript
  for (const j of jobsRaw) {
```

**L232**
```typescript
    try {
```

**L233**
```typescript
      await mailer.syncCampaignToMergeJob(
```

**L234**
```typescript
        supabase,
```

**L235**
```typescript
        j.organization_id as string,
```

**L236**
```typescript
        j.id as string,
```

**L237**
```typescript
      );
```

**L238**
```typescript
      synced += 1;
```

**L239**
```typescript
    } catch (err) {
```

**L240**
```typescript
      failed += 1;
```

**L241**
```typescript
      if (err instanceof TabsMailerNotImplementedError) {
```

**L242**
```typescript
        // 운영 정보 미수령 — 더 이상 시도 안 함
```

**L243**
```typescript
        // eslint-disable-next-line no-console
```

**L244**
```typescript
        console.warn(
```

**L245**
```typescript
          '[mail-merge-worker] sync skipped: TABS spec not implemented',
```

**L246**
```typescript
        );
```

**L247**
```typescript
        break;
```

**L248**
```typescript
      }
```

**L249**
```typescript
      if (err instanceof TabsMailerError) {
```

**L250**
```typescript
        // eslint-disable-next-line no-console
```

**L251**
```typescript
        console.error(
```

**L252**
```typescript
          `[mail-merge-worker] sync failed for job=${j.id}:`,
```

**L253**
```typescript
          err.message,
```

**L254**
```typescript
        );
```

**L255**
```typescript
      }
```

**L256**
```typescript
    }
```

**L257**
```typescript
  }
```

**L258**
```typescript
  return { synced, failed };
```

**L259**
```typescript
}
```

**L260**
```typescript

```

**L261**
```typescript
/* ============================================================
```

**L262**
```typescript
 * 5. main — 폴링 루프 + graceful shutdown
```

**L263**
```typescript
 * ============================================================ */
```

**L264**
```typescript

```

**L265**
```typescript
async function main(): Promise<void> {
```

**L266**
```typescript
  const supabase = createClient(
```

**L267**
```typescript
    env.NEXT_PUBLIC_SUPABASE_URL,
```

**L268**
```typescript
    env.SUPABASE_SERVICE_ROLE_KEY,
```

**L269**
```typescript
  );
```

**L270**
```typescript
  const ctl = createShutdownController('mail-merge-worker');
```

**L271**
```typescript

```

**L272**
```typescript
  // eslint-disable-next-line no-console
```

**L273**
```typescript
  console.log(
```

**L274**
```typescript
    `[mail-merge-worker] starting (poll interval=${POLL_INTERVAL_MS}ms, batch=${BATCH_SIZE})`,
```

**L275**
```typescript
  );
```

**L276**
```typescript

```

**L277**
```typescript
  while (!ctl.isShuttingDown()) {
```

**L278**
```typescript
    try {
```

**L279**
```typescript
      const results = await ctl.track(processQueueBatch(supabase));
```

**L280**
```typescript
      if (results.length > 0) {
```

**L281**
```typescript
        // eslint-disable-next-line no-console
```

**L282**
```typescript
        console.log(
```

**L283**
```typescript
          `[mail-merge-worker] iteration: processed ${results.length} job(s)`,
```

**L284**
```typescript
        );
```

**L285**
```typescript
      }
```

**L286**
```typescript
    } catch (err) {
```

**L287**
```typescript
      // eslint-disable-next-line no-console
```

**L288**
```typescript
      console.error('[mail-merge-worker] iteration error:', err);
```

**L289**
```typescript
    }
```

**L290**
```typescript
    await ctl.sleep(POLL_INTERVAL_MS);
```

**L291**
```typescript
  }
```

**L292**
```typescript

```

**L293**
```typescript
  await ctl.waitForInflight(30_000);
```

**L294**
```typescript
  // eslint-disable-next-line no-console
```

**L295**
```typescript
  console.log('[mail-merge-worker] shutdown complete');
```

**L296**
```typescript
}
```

**L297**
```typescript

```

**L298**
```typescript
if (isMainEntry(import.meta.url)) {
```

**L299**
```typescript
  main().catch((err) => {
```

**L300**
```typescript
    // eslint-disable-next-line no-console
```

**L301**
```typescript
    console.error('[mail-merge-worker] fatal:', err);
```

**L302**
```typescript
    process.exit(1);
```

**L303**
```typescript
  });
```

**L304**
```typescript
}
```

### `src\workers\mailcarrier-worker.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * src/workers/mailcarrier-worker.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * IMAP에서 새 메일을 수신하고 ai.drafts 파이프라인을 트리거하는 워커.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * Phase 2 변경:
```

**L7**
```typescript
 *   - 단일 MAILCARRIER_USERNAME → MAILCARRIER_POLL_KINDS 배열 기반
```

**L8**
```typescript
 *   - kinds 길이만큼 MailCarrierClient 인스턴스 (personal/role/shared)
```

**L9**
```typescript
 *   - 각 client 독립 IDLE 루프 (한 box 장애가 다른 box에 영향 없음)
```

**L10**
```typescript
 *   - graceful shutdown: 모든 client 병렬 stop()
```

**L11**
```typescript
 *   - kinds 빈 값 시 Phase 1 fallback (단일 MAILCARRIER_USERNAME)
```

**L12**
```typescript
 *
```

**L13**
```typescript
 * 흐름:
```

**L14**
```typescript
 *   [1] Supabase service_role 클라이언트 생성 (RLS 우회)
```

**L15**
```typescript
 *   [2] MAILCARRIER_POLL_KINDS에 따라 1~3개 MailCarrierClient 생성 + connect()
```

**L16**
```typescript
 *   [3] 각 client.startListening(onMessage) 병렬 실행
```

**L17**
```typescript
 *   [4] 새 메일 도착 시 → persistInbound → processInbound → ai.drafts INSERT
```

**L18**
```typescript
 *   [5] SIGTERM/SIGINT → 모든 client 병렬 graceful shutdown
```

**L19**
```typescript
 *
```

**L20**
```typescript
 * 실행:
```

**L21**
```typescript
 *   npm run worker:mailcarrier
```

**L22**
```typescript
 *
```

**L23**
```typescript
 * 필수 환경변수:
```

**L24**
```typescript
 *   - SUPABASE_SERVICE_ROLE_KEY
```

**L25**
```typescript
 *   - ANTHROPIC_API_KEY
```

**L26**
```typescript
 *   - MAILCARRIER_HOST / PORT (공통)
```

**L27**
```typescript
 *   - MAILCARRIER_POLL_KINDS (예: "personal,role,shared")
```

**L28**
```typescript
 *   - MAIL_<KIND>_USERNAME / PASSWORD (각 kind별)
```

**L29**
```typescript
 *   - 또는 MAILCARRIER_USERNAME / PASSWORD (POLL_KINDS 빈 값 시 fallback)
```

**L30**
```typescript
 *
```

**L31**
```typescript
 * 비고:
```

**L32**
```typescript
 *   - Phase 1은 단일 조직(MBG Project) 처리.
```

**L33**
```typescript
 *   - 처리 중 에러는 communications.ai_processing_status='failed'로 기록.
```

**L34**
```typescript
 */
```

**L35**
```typescript

```

**L36**
```typescript
import { createClient } from '@supabase/supabase-js';
```

**L37**
```typescript
import { env } from '../lib/env';
```

**L38**
```typescript
import { MailCarrierClient } from '../lib/email/mailcarrier';
```

**L39**
```typescript
import { processInbound } from '../lib/email/processor';
```

**L40**
```typescript
import type { InboundMessageEvent, SendingAddressKind } from '../types/email';
```

**L41**
```typescript
import { createShutdownController, isMainEntry } from './runtime';
```

**L42**
```typescript

```

**L43**
```typescript

```

**L44**
```typescript
// =============================================================================
```

**L45**
```typescript
// PATCH 2: src/workers/mailcarrier-worker.ts
```

**L46**
```typescript
// =============================================================================
```

**L47**
```typescript
// 적용 위치: 파일 최상단 (import문 직후, 메인 로직 위)에 아래 블록 그대로 추가
```

**L48**
```typescript
//
```

**L49**
```typescript
// 핵심 진단 신호:
```

**L50**
```typescript
//   - beforeExit 로그가 뜨면 = event loop가 비었다 = polling loop가 모두 종료된 결정적 신호
```

**L51**
```typescript
//     → 핸드오프의 가설 (B-1) 확정
```

**L52**
```typescript
//   - uncaughtException/unhandledRejection → 비동기 에러가 워커를 죽이려 하는 경우
```

**L53**
```typescript
//   - SIGTERM/SIGINT → 외부에서 종료 (Task Scheduler, Defender, 사용자 등)
```

**L54**
```typescript
//
```

**L55**
```typescript
// 운영 단계 진입 시 주의:
```

**L56**
```typescript
//   - uncaughtException 핸들러에서 process.exit(1)을 호출하도록 변경 필요
```

**L57**
```typescript
//   - 진단 단계에서는 의도적으로 exit 안 함 (어떤 에러가 워커를 죽이려 하는지 보기 위함)
```

**L58**
```typescript
// =============================================================================
```

**L59**
```typescript

```

**L60**
```typescript
// ─── Process-level diagnostics ─────────────────────────────────────────────
```

**L61**
```typescript
process.on('uncaughtException', (err) => {
```

**L62**
```typescript
  console.error('[worker] uncaughtException:', err);
```

**L63**
```typescript
  // 진단 단계: 의도적으로 exit 안 함
```

**L64**
```typescript
  // 운영 단계로 가면 process.exit(1)로 바꿔야 함
```

**L65**
```typescript
});
```

**L66**
```typescript

```

**L67**
```typescript
process.on('unhandledRejection', (reason, promise) => {
```

**L68**
```typescript
  console.error('[worker] unhandledRejection at:', promise, 'reason:', reason);
```

**L69**
```typescript
});
```

**L70**
```typescript

```

**L71**
```typescript
process.on('SIGTERM', () => {
```

**L72**
```typescript
  console.warn('[worker] SIGTERM received — exiting');
```

**L73**
```typescript
  process.exit(0);
```

**L74**
```typescript
});
```

**L75**
```typescript

```

**L76**
```typescript
process.on('SIGINT', () => {
```

**L77**
```typescript
  console.warn('[worker] SIGINT received — exiting');
```

**L78**
```typescript
  process.exit(0);
```

**L79**
```typescript
});
```

**L80**
```typescript

```

**L81**
```typescript
process.on('exit', (code) => {
```

**L82**
```typescript
  console.warn(`[worker] process.on('exit') code=${code}`);
```

**L83**
```typescript
});
```

**L84**
```typescript

```

**L85**
```typescript
process.on('beforeExit', (code) => {
```

**L86**
```typescript
  console.warn(
```

**L87**
```typescript
    `[worker] beforeExit code=${code} — event loop empty, ` +
```

**L88**
```typescript
    `no more work scheduled (this means polling loop has exited)`,
```

**L89**
```typescript
  );
```

**L90**
```typescript
});
```

**L91**
```typescript
// ───────────────────────────────────────────────────────────────────────────
```

**L92**
```typescript

```

**L93**
```typescript

```

**L94**
```typescript

```

**L95**
```typescript
/* ============================================================
```

**L96**
```typescript
 * 1. 조직 ID (Phase 1: 단일 조직 하드코딩)
```

**L97**
```typescript
 * ============================================================ */
```

**L98**
```typescript
const ORG_ID = 'b25de8f2-1020-482f-9012-183f63883169'; // MBG Project
```

**L99**
```typescript

```

**L100**
```typescript
/* ============================================================
```

**L101**
```typescript
 * 2. 메인 워커 루프
```

**L102**
```typescript
 * ============================================================ */
```

**L103**
```typescript

```

**L104**
```typescript
export async function runMailCarrierWorker(): Promise<void> {
```

**L105**
```typescript
  const label = 'mailcarrier-worker';
```

**L106**
```typescript
  const ctl = createShutdownController(label);
```

**L107**
```typescript

```

**L108**
```typescript
  // Supabase service_role (RLS 우회)
```

**L109**
```typescript
  const supabase = createClient(
```

**L110**
```typescript
    env.NEXT_PUBLIC_SUPABASE_URL,
```

**L111**
```typescript
    env.SUPABASE_SERVICE_ROLE_KEY,
```

**L112**
```typescript
    { auth: { persistSession: false, autoRefreshToken: false } },
```

**L113**
```typescript
  );
```

**L114**
```typescript

```

**L115**
```typescript
  // ─ kind 목록 결정 ─
```

**L116**
```typescript
  // MAILCARRIER_POLL_KINDS 비어있으면 Phase 1 fallback (단일 MAILCARRIER_USERNAME)
```

**L117**
```typescript
  const configuredKinds = env.MAILCARRIER_POLL_KINDS;
```

**L118**
```typescript
  const targetKinds: Array<SendingAddressKind | undefined> =
```

**L119**
```typescript
    configuredKinds.length > 0 ? configuredKinds : [undefined];
```

**L120**
```typescript

```

**L121**
```typescript
  // ─ MailCarrierClient 인스턴스 생성 ─
```

**L122**
```typescript
  const carriers: MailCarrierClient[] = [];
```

**L123**
```typescript
  for (const kind of targetKinds) {
```

**L124**
```typescript
    try {
```

**L125**
```typescript
      const carrier = new MailCarrierClient(supabase, ORG_ID, { kind });
```

**L126**
```typescript
      carriers.push(carrier);
```

**L127**
```typescript
    } catch (err) {
```

**L128**
```typescript
      // eslint-disable-next-line no-console
```

**L129**
```typescript
      console.error(
```

**L130**
```typescript
        `[${label}:${kind ?? 'default'}] 자격증명 누락 또는 잘못된 설정:`,
```

**L131**
```typescript
        (err as Error).message,
```

**L132**
```typescript
      );
```

**L133**
```typescript
      // 한 kind 실패 시 다른 kind는 계속
```

**L134**
```typescript
    }
```

**L135**
```typescript
  }
```

**L136**
```typescript

```

**L137**
```typescript
  if (carriers.length === 0) {
```

**L138**
```typescript
    // eslint-disable-next-line no-console
```

**L139**
```typescript
    console.error(
```

**L140**
```typescript
      `[${label}] No valid carriers configured. Check MAILCARRIER_POLL_KINDS or MAILCARRIER_USERNAME/PASSWORD.`,
```

**L141**
```typescript
    );
```

**L142**
```typescript
    process.exit(1);
```

**L143**
```typescript
  }
```

**L144**
```typescript

```

**L145**
```typescript
  // ─ graceful shutdown 설정 ─
```

**L146**
```typescript
  const originalShutdown = ctl.shutdown.bind(ctl);
```

**L147**
```typescript
  const shutdownWithCleanup = async (): Promise<void> => {
```

**L148**
```typescript
    originalShutdown();
```

**L149**
```typescript
    // 모든 carrier 병렬 stop()
```

**L150**
```typescript
    await Promise.all(
```

**L151**
```typescript
      carriers.map(async (c) => {
```

**L152**
```typescript
        try {
```

**L153**
```typescript
          await c.stop();
```

**L154**
```typescript
        } catch (err) {
```

**L155**
```typescript
          // eslint-disable-next-line no-console
```

**L156**
```typescript
          console.error(`[${label}:${c.kind}] stop() error:`, err);
```

**L157**
```typescript
        }
```

**L158**
```typescript
      }),
```

**L159**
```typescript
    );
```

**L160**
```typescript
  };
```

**L161**
```typescript
  process.on('SIGTERM', shutdownWithCleanup);
```

**L162**
```typescript
  process.on('SIGINT', shutdownWithCleanup);
```

**L163**
```typescript

```

**L164**
```typescript
  // ─ 각 carrier 연결 ─
```

**L165**
```typescript
  const connected: MailCarrierClient[] = [];
```

**L166**
```typescript
  for (const carrier of carriers) {
```

**L167**
```typescript
    const tag = `${label}:${carrier.kind}`;
```

**L168**
```typescript
    // eslint-disable-next-line no-console
```

**L169**
```typescript
    console.log(
```

**L170**
```typescript
      `[${tag}] connecting to IMAP ${env.MAILCARRIER_HOST}:${env.MAILCARRIER_PORT} (user=${carrier.username})`,
```

**L171**
```typescript
    );
```

**L172**
```typescript
    try {
```

**L173**
```typescript
      await carrier.connect();
```

**L174**
```typescript
      connected.push(carrier);
```

**L175**
```typescript
      // eslint-disable-next-line no-console
```

**L176**
```typescript
      console.log(
```

**L177**
```typescript
        `[${tag}] connected (folder=${env.MAILCARRIER_INBOX_FOLDER}, mode=${env.MAILCARRIER_USE_IDLE ? 'IDLE' : 'POLL'})`,
```

**L178**
```typescript
      );
```

**L179**
```typescript
    } catch (err) {
```

**L180**
```typescript
      // eslint-disable-next-line no-console
```

**L181**
```typescript
      console.error(`[${tag}] IMAP 연결 실패:`, err);
```

**L182**
```typescript
      // 한 kind 연결 실패해도 다른 kind는 계속
```

**L183**
```typescript
    }
```

**L184**
```typescript
  }
```

**L185**
```typescript

```

**L186**
```typescript
  if (connected.length === 0) {
```

**L187**
```typescript
    // eslint-disable-next-line no-console
```

**L188**
```typescript
    console.error(`[${label}] All IMAP connections failed. Exiting.`);
```

**L189**
```typescript
    process.exit(1);
```

**L190**
```typescript
  }
```

**L191**
```typescript

```

**L192**
```typescript
  // ─ 새 메일 처리 콜백 (carrier별) ─
```

**L193**
```typescript
  const makeOnMessage =
```

**L194**
```typescript
    (carrierKind: SendingAddressKind | 'default') =>
```

**L195**
```typescript
    async (event: InboundMessageEvent): Promise<void> => {
```

**L196**
```typescript
      if (ctl.isShuttingDown()) {
```

**L197**
```typescript
        return;
```

**L198**
```typescript
      }
```

**L199**
```typescript
      const tag = `[${label}:${carrierKind}:${event.communicationId.slice(0, 8)}]`;
```

**L200**
```typescript
      // eslint-disable-next-line no-console
```

**L201**
```typescript
      console.log(
```

**L202**
```typescript
        `${tag} new inbound — from=${event.fromAddress} message_id=${event.messageId}`,
```

**L203**
```typescript
      );
```

**L204**
```typescript
      try {
```

**L205**
```typescript
        await ctl.track(
```

**L206**
```typescript
          (async () => {
```

**L207**
```typescript
            const result = await processInbound(supabase, ORG_ID, event.communicationId);
```

**L208**
```typescript
            // eslint-disable-next-line no-console
```

**L209**
```typescript
            console.log(
```

**L210**
```typescript
              `${tag} processed → draft.id=${result.draftId} ` +
```

**L211**
```typescript
                `category=${result.classification?.category} ` +
```

**L212**
```typescript
                `confidence=${result.classification?.confidence?.toFixed(2)} ` +
```

**L213**
```typescript
                `auto_send=${result.autoSendAllowed}`,
```

**L214**
```typescript
            );
```

**L215**
```typescript
          })(),
```

**L216**
```typescript
        );
```

**L217**
```typescript
      } catch (err) {
```

**L218**
```typescript
        // eslint-disable-next-line no-console
```

**L219**
```typescript
        console.error(`${tag} processInbound 실패:`, err);
```

**L220**
```typescript
      }
```

**L221**
```typescript
    };
```

**L222**
```typescript

```

**L223**
```typescript
  // ─ 모든 carrier startListening 병렬 실행 ─
```

**L224**
```typescript
  // eslint-disable-next-line no-console
```

**L225**
```typescript
  console.log(
```

**L226**
```typescript
    `[${label}] listening on ${connected.length} inbox(es)… (Ctrl+C to stop)`,
```

**L227**
```typescript
  );
```

**L228**
```typescript

```

**L229**
```typescript
  const listeners = connected.map((carrier) => {
```

**L230**
```typescript
    const tag = `${label}:${carrier.kind}`;
```

**L231**
```typescript
    return carrier.startListening(makeOnMessage(carrier.kind)).catch((err) => {
```

**L232**
```typescript
      if (ctl.isShuttingDown()) {
```

**L233**
```typescript
        // eslint-disable-next-line no-console
```

**L234**
```typescript
        console.log(`[${tag}] listener stopped due to shutdown signal`);
```

**L235**
```typescript
      } else {
```

**L236**
```typescript
        // eslint-disable-next-line no-console
```

**L237**
```typescript
        console.error(`[${tag}] listener crashed:`, err);
```

**L238**
```typescript
        // 한 listener crash 시에도 다른 listener는 계속
```

**L239**
```typescript
      }
```

**L240**
```typescript
    });
```

**L241**
```typescript
  });
```

**L242**
```typescript

```

**L243**
```typescript
  // 모든 listener가 종료될 때까지 대기
```

**L244**
```typescript
  await Promise.all(listeners);
```

**L245**
```typescript

```

**L246**
```typescript
  // ─ Graceful shutdown 마무리 ─
```

**L247**
```typescript
  await ctl.waitForInflight(30_000);
```

**L248**
```typescript
  // eslint-disable-next-line no-console
```

**L249**
```typescript
  console.log(`[${label}] shutdown complete`);
```

**L250**
```typescript
}
```

**L251**
```typescript

```

**L252**
```typescript
/* ============================================================
```

**L253**
```typescript
 * 3. CLI 엔트리
```

**L254**
```typescript
 * ============================================================ */
```

**L255**
```typescript
if (isMainEntry(import.meta.url)) {
```

**L256**
```typescript
  runMailCarrierWorker().catch((err) => {
```

**L257**
```typescript
    // eslint-disable-next-line no-console
```

**L258**
```typescript
    console.error('[mailcarrier-worker] fatal:', err);
```

**L259**
```typescript
    process.exit(1);
```

**L260**
```typescript
  });
```

**L261**
```typescript
}
```

### `src\workers\runtime.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * workers/runtime.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 3 워커가 공유하는 graceful shutdown 헬퍼.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * 사용:
```

**L7**
```typescript
 *   const ctl = createShutdownController('mail-merge-worker');
```

**L8**
```typescript
 *   while (!ctl.isShuttingDown()) {
```

**L9**
```typescript
 *     await ctl.track(processOnce());
```

**L10**
```typescript
 *     await ctl.sleep(POLL_INTERVAL_MS);
```

**L11**
```typescript
 *   }
```

**L12**
```typescript
 *   await ctl.waitForInflight();
```

**L13**
```typescript
 *   process.exit(0);
```

**L14**
```typescript
 */
```

**L15**
```typescript

```

**L16**
```typescript
import { fileURLToPath } from 'node:url';
```

**L17**
```typescript

```

**L18**
```typescript
/* ============================================================
```

**L19**
```typescript
 * 1. ShutdownController
```

**L20**
```typescript
 * ============================================================ */
```

**L21**
```typescript

```

**L22**
```typescript
export interface ShutdownController {
```

**L23**
```typescript
  isShuttingDown(): boolean;
```

**L24**
```typescript
  /** Promise를 inflight 추적에 등록. 반환값은 동일 Promise (chain 가능). */
```

**L25**
```typescript
  track<T>(p: Promise<T>): Promise<T>;
```

**L26**
```typescript
  /** 모든 inflight 완료 대기. timeout 초과 시 강제 종료. */
```

**L27**
```typescript
  waitForInflight(timeoutMs?: number): Promise<void>;
```

**L28**
```typescript
  /** 셧다운 신호를 받으면 즉시 깨어나는 sleep. */
```

**L29**
```typescript
  sleep(ms: number): Promise<void>;
```

**L30**
```typescript
  /** 외부에서 강제 셧다운을 트리거 (테스트용). */
```

**L31**
```typescript
  shutdown(): void;
```

**L32**
```typescript
}
```

**L33**
```typescript

```

**L34**
```typescript
export function createShutdownController(label: string): ShutdownController {
```

**L35**
```typescript
  let shuttingDown = false;
```

**L36**
```typescript
  const inflight: Set<Promise<unknown>> = new Set();
```

**L37**
```typescript
  const wakeupResolvers: Array<() => void> = [];
```

**L38**
```typescript

```

**L39**
```typescript
  const triggerWakeup = (): void => {
```

**L40**
```typescript
    while (wakeupResolvers.length > 0) {
```

**L41**
```typescript
      const resolve = wakeupResolvers.shift();
```

**L42**
```typescript
      try {
```

**L43**
```typescript
        resolve?.();
```

**L44**
```typescript
      } catch {
```

**L45**
```typescript
        /* 무시 */
```

**L46**
```typescript
      }
```

**L47**
```typescript
    }
```

**L48**
```typescript
  };
```

**L49**
```typescript

```

**L50**
```typescript
  const onSignal = (sig: NodeJS.Signals): void => {
```

**L51**
```typescript
    if (shuttingDown) return;
```

**L52**
```typescript
    shuttingDown = true;
```

**L53**
```typescript
    // eslint-disable-next-line no-console
```

**L54**
```typescript
    console.log(
```

**L55**
```typescript
      `[${label}] received ${sig}, draining inflight tasks (count=${inflight.size})…`,
```

**L56**
```typescript
    );
```

**L57**
```typescript
    triggerWakeup();
```

**L58**
```typescript
  };
```

**L59**
```typescript

```

**L60**
```typescript
  process.on('SIGTERM', onSignal);
```

**L61**
```typescript
  process.on('SIGINT', onSignal);
```

**L62**
```typescript

```

**L63**
```typescript
  return {
```

**L64**
```typescript
    isShuttingDown: () => shuttingDown,
```

**L65**
```typescript

```

**L66**
```typescript
    track<T>(p: Promise<T>): Promise<T> {
```

**L67**
```typescript
      inflight.add(p);
```

**L68**
```typescript
      const cleanup = (): void => {
```

**L69**
```typescript
        inflight.delete(p);
```

**L70**
```typescript
      };
```

**L71**
```typescript
      p.then(cleanup, cleanup);
```

**L72**
```typescript
      return p;
```

**L73**
```typescript
    },
```

**L74**
```typescript

```

**L75**
```typescript
    async waitForInflight(timeoutMs = 30_000): Promise<void> {
```

**L76**
```typescript
      if (inflight.size === 0) return;
```

**L77**
```typescript
      // eslint-disable-next-line no-console
```

**L78**
```typescript
      console.log(
```

**L79**
```typescript
        `[${label}] waiting for ${inflight.size} inflight task(s) (timeout=${timeoutMs}ms)`,
```

**L80**
```typescript
      );
```

**L81**
```typescript
      const settled = Promise.allSettled([...inflight]);
```

**L82**
```typescript
      const timer = new Promise<'timeout'>((resolve) =>
```

**L83**
```typescript
        setTimeout(() => resolve('timeout'), timeoutMs),
```

**L84**
```typescript
      );
```

**L85**
```typescript
      const result = await Promise.race([settled, timer]);
```

**L86**
```typescript
      if (result === 'timeout') {
```

**L87**
```typescript
        // eslint-disable-next-line no-console
```

**L88**
```typescript
        console.error(
```

**L89**
```typescript
          `[${label}] graceful shutdown timed out, ${inflight.size} task(s) still running`,
```

**L90**
```typescript
        );
```

**L91**
```typescript
      }
```

**L92**
```typescript
    },
```

**L93**
```typescript

```

**L94**
```typescript
    sleep(ms: number): Promise<void> {
```

**L95**
```typescript
      if (shuttingDown) return Promise.resolve();
```

**L96**
```typescript
      return new Promise<void>((resolve) => {
```

**L97**
```typescript
        const timer = setTimeout(() => {
```

**L98**
```typescript
          // wakeupResolvers에서 제거 시도
```

**L99**
```typescript
          const idx = wakeupResolvers.indexOf(resolve);
```

**L100**
```typescript
          if (idx >= 0) wakeupResolvers.splice(idx, 1);
```

**L101**
```typescript
          resolve();
```

**L102**
```typescript
        }, ms);
```

**L103**
```typescript
        wakeupResolvers.push(() => {
```

**L104**
```typescript
          clearTimeout(timer);
```

**L105**
```typescript
          resolve();
```

**L106**
```typescript
        });
```

**L107**
```typescript
      });
```

**L108**
```typescript
    },
```

**L109**
```typescript

```

**L110**
```typescript
    shutdown(): void {
```

**L111**
```typescript
      onSignal('SIGTERM');
```

**L112**
```typescript
    },
```

**L113**
```typescript
  };
```

**L114**
```typescript
}
```

**L115**
```typescript

```

**L116**
```typescript
/* ============================================================
```

**L117**
```typescript
 * 2. Entry-point 가드 (ESM)
```

**L118**
```typescript
 * ----------------------------------------------------------
```

**L119**
```typescript
 * `tsx src/workers/foo.ts` 직접 실행 시 main()을 호출하기 위한 헬퍼.
```

**L120**
```typescript
 * import 시에는 호출되지 않아 단위 테스트가 안전.
```

**L121**
```typescript
 * ============================================================ */
```

**L122**
```typescript
export function isMainEntry(importMetaUrl: string): boolean {
```

**L123**
```typescript
  try {
```

**L124**
```typescript
    const thisFile = fileURLToPath(importMetaUrl);
```

**L125**
```typescript
    const argv1 = process.argv[1] ?? '';
```

**L126**
```typescript
    return thisFile === argv1 || argv1.endsWith(thisFile);
```

**L127**
```typescript
  } catch {
```

**L128**
```typescript
    return false;
```

**L129**
```typescript
  }
```

**L130**
```typescript
}
```

### `src\__tests__\ai\claude-client.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/ai/claude-client.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * ClaudeClient.complete()의 핵심 보장:
```

**L5**
```typescript
 *   1. 일일 예산 초과 시 ClaudeBudgetExceededError throw
```

**L6**
```typescript
 *   2. agent.model이 SUPPORTED_MODELS에 없으면 ClaudeInvalidModelError throw
```

**L7**
```typescript
 *   3. 429/5xx에 exponential backoff, 두 번째 시도부터 fallback 모델 사용
```

**L8**
```typescript
 *   4. 4xx (재시도 불가)는 즉시 throw + ai.runs status='failed' 기록
```

**L9**
```typescript
 *   5. 성공 시 ai.runs status='success' 기록 + cost 계산 정확
```

**L10**
```typescript
 *   6. PII 마스킹 적용 후 응답에서 복원
```

**L11**
```typescript
 *   7. JSON output_format 시 parsedJson 채움
```

**L12**
```typescript
 */
```

**L13**
```typescript

```

**L14**
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

**L15**
```typescript
import Anthropic from '@anthropic-ai/sdk';
```

**L16**
```typescript
import {
```

**L17**
```typescript
  ClaudeClient,
```

**L18**
```typescript
  ClaudeApiError,
```

**L19**
```typescript
  ClaudeBudgetExceededError,
```

**L20**
```typescript
  ClaudeInvalidModelError,
```

**L21**
```typescript
  ClaudeAgentNotFoundError,
```

**L22**
```typescript
} from '../../lib/ai/claude-client';
```

**L23**
```typescript
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
```

**L24**
```typescript

```

**L25**
```typescript
// prompt-renderer는 OpenAI 호출이 있으므로 항상 mock
```

**L26**
```typescript
vi.mock('../../lib/ai/prompt-renderer', () => ({
```

**L27**
```typescript
  renderPrompt: vi.fn(async () => ({
```

**L28**
```typescript
    system: 'You are a classifier.',
```

**L29**
```typescript
    messages: [{ role: 'user', content: '{"inbound":"test"}' }],
```

**L30**
```typescript
    metadata: {
```

**L31**
```typescript
      brandVoiceId: 'bv-1',
```

**L32**
```typescript
      knowledgeChunkIds: ['kc-1', 'kc-2'],
```

**L33**
```typescript
      threadIds: [],
```

**L34**
```typescript
      embeddingTokens: 50,
```

**L35**
```typescript
    },
```

**L36**
```typescript
  })),
```

**L37**
```typescript
}));
```

**L38**
```typescript

```

**L39**
```typescript
interface FakeAnthropicOpts {
```

**L40**
```typescript
  responses?: Array<
```

**L41**
```typescript
    | { type: 'success'; content: string; tokensIn?: number; tokensOut?: number }
```

**L42**
```typescript
    | { type: 'error'; status: number; retryAfter?: number; message?: string }
```

**L43**
```typescript
  >;
```

**L44**
```typescript
}
```

**L45**
```typescript

```

**L46**
```typescript
function buildFakeAnthropic(opts: FakeAnthropicOpts): Anthropic {
```

**L47**
```typescript
  const responses = [...(opts.responses ?? [])];
```

**L48**
```typescript
  return {
```

**L49**
```typescript
    messages: {
```

**L50**
```typescript
      create: vi.fn(async () => {
```

**L51**
```typescript
        const r = responses.shift();
```

**L52**
```typescript
        if (!r) throw new Error('no more fake responses configured');
```

**L53**
```typescript
        if (r.type === 'error') {
```

**L54**
```typescript
          // 실제 Anthropic.APIError 인스턴스 — instanceof 검사 통과
```

**L55**
```typescript
          const headers = new Headers();
```

**L56**
```typescript
          if (r.retryAfter !== undefined) {
```

**L57**
```typescript
            headers.set('retry-after', String(r.retryAfter));
```

**L58**
```typescript
          }
```

**L59**
```typescript
          throw new Anthropic.APIError(
```

**L60**
```typescript
            r.status,
```

**L61**
```typescript
            undefined,
```

**L62**
```typescript
            r.message ?? `HTTP ${r.status}`,
```

**L63**
```typescript
            headers,
```

**L64**
```typescript
          );
```

**L65**
```typescript
        }
```

**L66**
```typescript
        return {
```

**L67**
```typescript
          id: 'msg_test',
```

**L68**
```typescript
          type: 'message',
```

**L69**
```typescript
          role: 'assistant',
```

**L70**
```typescript
          content: [{ type: 'text', text: r.content }],
```

**L71**
```typescript
          model: 'claude-haiku-4-5-20251001',
```

**L72**
```typescript
          stop_reason: 'end_turn',
```

**L73**
```typescript
          usage: {
```

**L74**
```typescript
            input_tokens: r.tokensIn ?? 100,
```

**L75**
```typescript
            output_tokens: r.tokensOut ?? 50,
```

**L76**
```typescript
          },
```

**L77**
```typescript
        };
```

**L78**
```typescript
      }),
```

**L79**
```typescript
    },
```

**L80**
```typescript
  } as unknown as Anthropic;
```

**L81**
```typescript
}
```

**L82**
```typescript

```

**L83**
```typescript
const orgId = 'org-1';
```

**L84**
```typescript

```

**L85**
```typescript
const haikuAgentRow = {
```

**L86**
```typescript
  id: 'agent-classifier-1',
```

**L87**
```typescript
  organization_id: orgId,
```

**L88**
```typescript
  role: 'classifier',
```

**L89**
```typescript
  name: 'Email Classifier',
```

**L90**
```typescript
  model: 'claude-haiku-4-5-20251001',
```

**L91**
```typescript
  fallback_model: 'claude-sonnet-4-6',
```

**L92**
```typescript
  temperature: 0.2,
```

**L93**
```typescript
  max_tokens: 1024,
```

**L94**
```typescript
  output_format: 'structured',
```

**L95**
```typescript
  system_prompt: 'You are a classifier.',
```

**L96**
```typescript
  applicable_modules: ['investor', 'paper_mill'],
```

**L97**
```typescript
  applicable_languages: ['ko', 'en', 'ja'],
```

**L98**
```typescript
  require_pii_masking: true,
```

**L99**
```typescript
  knowledge_collection: null,
```

**L100**
```typescript
  is_active: true,
```

**L101**
```typescript
  version: 1,
```

**L102**
```typescript
};
```

**L103**
```typescript

```

**L104**
```typescript
function buildSupabase(opts: {
```

**L105**
```typescript
  todayCost?: number;
```

**L106**
```typescript
  monthCost?: number;
```

**L107**
```typescript
  agentRow?: object | null;
```

**L108**
```typescript
  runInsertId?: string;
```

**L109**
```typescript
}): MockSupabase {
```

**L110**
```typescript
  // Daily cost = 호출 1: today rows, Monthly cost = 호출 2: month rows
```

**L111**
```typescript
  // 본 mock은 두 호출 모두 같은 결과 반환 (테스트에서 cost를 분리해야 할 때는
```

**L112**
```typescript
  // selectList를 동적으로 다른 응답 줘야 함)
```

**L113**
```typescript
  const todayRows = Array.from(
```

**L114**
```typescript
    { length: Math.min(opts.todayCost ?? 0, 100) > 0 ? 1 : 0 },
```

**L115**
```typescript
    () => ({ cost_usd: opts.todayCost ?? 0 }),
```

**L116**
```typescript
  );
```

**L117**
```typescript
  void opts.monthCost;
```

**L118**
```typescript
  return buildSupabaseMock({
```

**L119**
```typescript
    'ai.runs': {
```

**L120**
```typescript
      selectList: { data: todayRows },
```

**L121**
```typescript
      insertSingle: { data: { id: opts.runInsertId ?? 'run-1' } },
```

**L122**
```typescript
    },
```

**L123**
```typescript
    'ai.agents': {
```

**L124**
```typescript
      selectMaybeSingle: { data: opts.agentRow !== undefined ? opts.agentRow : haikuAgentRow },
```

**L125**
```typescript
    },
```

**L126**
```typescript
  });
```

**L127**
```typescript
}
```

**L128**
```typescript

```

**L129**
```typescript
describe('ClaudeClient — model validation', () => {
```

**L130**
```typescript
  it('throws ClaudeInvalidModelError when agent.model is unsupported', async () => {
```

**L131**
```typescript
    const supabase = buildSupabase({
```

**L132**
```typescript
      agentRow: { ...haikuAgentRow, model: 'claude-3-haiku' }, // 구버전!
```

**L133**
```typescript
    });
```

**L134**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L135**
```typescript
      anthropicClient: buildFakeAnthropic({ responses: [] }),
```

**L136**
```typescript
      enableMonthlyDowngrade: false,
```

**L137**
```typescript
    });
```

**L138**
```typescript

```

**L139**
```typescript
    await expect(
```

**L140**
```typescript
      client.complete({
```

**L141**
```typescript
        agentRole: 'classifier',
```

**L142**
```typescript
        inboundMessage: 'test',
```

**L143**
```typescript
        outputFormat: 'json',
```

**L144**
```typescript
      }),
```

**L145**
```typescript
    ).rejects.toBeInstanceOf(ClaudeInvalidModelError);
```

**L146**
```typescript
  });
```

**L147**
```typescript

```

**L148**
```typescript
  it('throws ClaudeAgentNotFoundError when no active agent', async () => {
```

**L149**
```typescript
    const supabase = buildSupabase({ agentRow: null });
```

**L150**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L151**
```typescript
      anthropicClient: buildFakeAnthropic({ responses: [] }),
```

**L152**
```typescript
      enableMonthlyDowngrade: false,
```

**L153**
```typescript
    });
```

**L154**
```typescript

```

**L155**
```typescript
    await expect(
```

**L156**
```typescript
      client.complete({
```

**L157**
```typescript
        agentRole: 'classifier',
```

**L158**
```typescript
        inboundMessage: 'test',
```

**L159**
```typescript
      }),
```

**L160**
```typescript
    ).rejects.toBeInstanceOf(ClaudeAgentNotFoundError);
```

**L161**
```typescript
  });
```

**L162**
```typescript
});
```

**L163**
```typescript

```

**L164**
```typescript
describe('ClaudeClient — budget enforcement', () => {
```

**L165**
```typescript
  it('throws ClaudeBudgetExceededError when daily limit exceeded', async () => {
```

**L166**
```typescript
    // setupFiles의 MAX_DAILY_AI_COST_USD=10. todayCost=15 → 초과
```

**L167**
```typescript
    const supabase = buildSupabase({ todayCost: 15 });
```

**L168**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L169**
```typescript
      anthropicClient: buildFakeAnthropic({ responses: [] }),
```

**L170**
```typescript
      enableMonthlyDowngrade: false,
```

**L171**
```typescript
    });
```

**L172**
```typescript

```

**L173**
```typescript
    await expect(
```

**L174**
```typescript
      client.complete({
```

**L175**
```typescript
        agentRole: 'classifier',
```

**L176**
```typescript
        inboundMessage: 'test',
```

**L177**
```typescript
      }),
```

**L178**
```typescript
    ).rejects.toBeInstanceOf(ClaudeBudgetExceededError);
```

**L179**
```typescript
  });
```

**L180**
```typescript
});
```

**L181**
```typescript

```

**L182**
```typescript
describe('ClaudeClient — successful call', () => {
```

**L183**
```typescript
  let supabase: MockSupabase;
```

**L184**
```typescript

```

**L185**
```typescript
  beforeEach(() => {
```

**L186**
```typescript
    supabase = buildSupabase({});
```

**L187**
```typescript
  });
```

**L188**
```typescript

```

**L189**
```typescript
  it('records ai.runs with success status and computes cost', async () => {
```

**L190**
```typescript
    const fake = buildFakeAnthropic({
```

**L191**
```typescript
      responses: [
```

**L192**
```typescript
        {
```

**L193**
```typescript
          type: 'success',
```

**L194**
```typescript
          content: '{"category":"information_request","confidence":0.95}',
```

**L195**
```typescript
          tokensIn: 1000,
```

**L196**
```typescript
          tokensOut: 500,
```

**L197**
```typescript
        },
```

**L198**
```typescript
      ],
```

**L199**
```typescript
    });
```

**L200**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L201**
```typescript
      anthropicClient: fake,
```

**L202**
```typescript
      enableMonthlyDowngrade: false,
```

**L203**
```typescript
    });
```

**L204**
```typescript

```

**L205**
```typescript
    const result = await client.complete({
```

**L206**
```typescript
      agentRole: 'classifier',
```

**L207**
```typescript
      inboundMessage: '안녕하세요, 가격이 궁금합니다.',
```

**L208**
```typescript
      outputFormat: 'json',
```

**L209**
```typescript
      language: 'ko',
```

**L210**
```typescript
    });
```

**L211**
```typescript

```

**L212**
```typescript
    expect(result.runId).toBe('run-1');
```

**L213**
```typescript
    expect(result.model).toBe('claude-haiku-4-5-20251001');
```

**L214**
```typescript
    expect(result.tokensIn).toBe(1000);
```

**L215**
```typescript
    expect(result.tokensOut).toBe(500);
```

**L216**
```typescript
    // Haiku: $0.8 in / $4 out per 1M
```

**L217**
```typescript
    // (1000 * 0.8 + 500 * 4) / 1_000_000 = 0.0008 + 0.002 = 0.0028
```

**L218**
```typescript
    expect(result.costUsd).toBeCloseTo(0.0028, 6);
```

**L219**
```typescript

```

**L220**
```typescript
    // parsedJson 채워짐
```

**L221**
```typescript
    expect(result.parsedJson).toEqual({
```

**L222**
```typescript
      category: 'information_request',
```

**L223**
```typescript
      confidence: 0.95,
```

**L224**
```typescript
    });
```

**L225**
```typescript

```

**L226**
```typescript
    // ai.runs INSERT — DB 컬럼명·매핑 검증
```

**L227**
```typescript
    const runInserts = supabase.__calls.insert.filter(
```

**L228**
```typescript
      (c) => c.schema === 'ai' && c.table === 'runs',
```

**L229**
```typescript
    );
```

**L230**
```typescript
    expect(runInserts).toHaveLength(1);
```

**L231**
```typescript
    const payload = runInserts[0]?.payload as Record<string, unknown>;
```

**L232**
```typescript
    // RunStatus 'success' → DB 'completed'
```

**L233**
```typescript
    expect(payload.status).toBe('completed');
```

**L234**
```typescript
    expect(payload.model_used).toBe('claude-haiku-4-5-20251001');
```

**L235**
```typescript
    expect(payload.input_tokens).toBe(1000);
```

**L236**
```typescript
    expect(payload.output_tokens).toBe(500);
```

**L237**
```typescript
    expect(payload.pii_masked).toBe(true);
```

**L238**
```typescript
    // brand_voice_id·knowledge_chunk_ids는 metadata jsonb로 이동
```

**L239**
```typescript
    const meta = payload.metadata as Record<string, unknown>;
```

**L240**
```typescript
    expect(meta.brand_voice_id).toBe('bv-1');
```

**L241**
```typescript
    expect(meta.knowledge_chunk_ids).toEqual(['kc-1', 'kc-2']);
```

**L242**
```typescript
    // completed_at도 채워짐 (status !== 'running')
```

**L243**
```typescript
    expect(typeof payload.completed_at).toBe('string');
```

**L244**
```typescript
  });
```

**L245**
```typescript

```

**L246**
```typescript
  it('strips ```json fence from response', async () => {
```

**L247**
```typescript
    const fake = buildFakeAnthropic({
```

**L248**
```typescript
      responses: [
```

**L249**
```typescript
        {
```

**L250**
```typescript
          type: 'success',
```

**L251**
```typescript
          content: '```json\n{"category":"meeting_scheduling","confidence":0.9}\n```',
```

**L252**
```typescript
        },
```

**L253**
```typescript
      ],
```

**L254**
```typescript
    });
```

**L255**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L256**
```typescript
      anthropicClient: fake,
```

**L257**
```typescript
      enableMonthlyDowngrade: false,
```

**L258**
```typescript
    });
```

**L259**
```typescript
    const result = await client.complete({
```

**L260**
```typescript
      agentRole: 'classifier',
```

**L261**
```typescript
      inboundMessage: 'meeting?',
```

**L262**
```typescript
      outputFormat: 'json',
```

**L263**
```typescript
    });
```

**L264**
```typescript
    expect((result.parsedJson as Record<string, unknown>)?.category).toBe(
```

**L265**
```typescript
      'meeting_scheduling',
```

**L266**
```typescript
    );
```

**L267**
```typescript
  });
```

**L268**
```typescript

```

**L269**
```typescript
  it('restores PII tokens in response content', async () => {
```

**L270**
```typescript
    const fake = buildFakeAnthropic({
```

**L271**
```typescript
      responses: [
```

**L272**
```typescript
        {
```

**L273**
```typescript
          type: 'success',
```

**L274**
```typescript
          // AI가 마스킹된 토큰을 그대로 출력했다고 가정
```

**L275**
```typescript
          content: 'Phone {{PII_001}} verified.',
```

**L276**
```typescript
        },
```

**L277**
```typescript
      ],
```

**L278**
```typescript
    });
```

**L279**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L280**
```typescript
      anthropicClient: fake,
```

**L281**
```typescript
      enableMonthlyDowngrade: false,
```

**L282**
```typescript
    });
```

**L283**
```typescript

```

**L284**
```typescript
    const result = await client.complete({
```

**L285**
```typescript
      agentRole: 'classifier',
```

**L286**
```typescript
      inboundMessage: '연락처: 010-1234-5678 입니다',
```

**L287**
```typescript
      outputFormat: 'text',
```

**L288**
```typescript
    });
```

**L289**
```typescript
    // 토큰이 원문(010-1234-5678)으로 복원되어야 함
```

**L290**
```typescript
    expect(result.content).toContain('010-1234-5678');
```

**L291**
```typescript
    expect(result.content).not.toContain('{{PII_001}}');
```

**L292**
```typescript
  });
```

**L293**
```typescript
});
```

**L294**
```typescript

```

**L295**
```typescript
describe('ClaudeClient — retry logic', () => {
```

**L296**
```typescript
  let supabase: MockSupabase;
```

**L297**
```typescript

```

**L298**
```typescript
  beforeEach(() => {
```

**L299**
```typescript
    supabase = buildSupabase({});
```

**L300**
```typescript
  });
```

**L301**
```typescript

```

**L302**
```typescript
  it('retries on 429 then succeeds', async () => {
```

**L303**
```typescript
    const fake = buildFakeAnthropic({
```

**L304**
```typescript
      responses: [
```

**L305**
```typescript
        { type: 'error', status: 429, retryAfter: 0 },
```

**L306**
```typescript
        { type: 'success', content: '{"ok":true}' },
```

**L307**
```typescript
      ],
```

**L308**
```typescript
    });
```

**L309**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L310**
```typescript
      anthropicClient: fake,
```

**L311**
```typescript
      enableMonthlyDowngrade: false,
```

**L312**
```typescript
    });
```

**L313**
```typescript

```

**L314**
```typescript
    const result = await client.complete({
```

**L315**
```typescript
      agentRole: 'classifier',
```

**L316**
```typescript
      inboundMessage: 'hi',
```

**L317**
```typescript
      outputFormat: 'json',
```

**L318**
```typescript
    });
```

**L319**
```typescript
    expect(result.parsedJson).toEqual({ ok: true });
```

**L320**
```typescript
    expect((fake.messages.create as ReturnType<typeof vi.fn>).mock.calls).toHaveLength(2);
```

**L321**
```typescript

```

**L322**
```typescript
    // ai.runs INSERT는 1회 (성공 시점만), retry_count=1
```

**L323**
```typescript
    const runInserts = supabase.__calls.insert.filter(
```

**L324**
```typescript
      (c) => c.schema === 'ai' && c.table === 'runs',
```

**L325**
```typescript
    );
```

**L326**
```typescript
    expect(runInserts).toHaveLength(1);
```

**L327**
```typescript
    const payload = runInserts[0]?.payload as Record<string, unknown>;
```

**L328**
```typescript
    expect(payload.status).toBe('completed');
```

**L329**
```typescript
    const meta = payload.metadata as Record<string, unknown>;
```

**L330**
```typescript
    expect(meta.retry_count).toBe(1);
```

**L331**
```typescript
  });
```

**L332**
```typescript

```

**L333**
```typescript
  it('switches to fallback model on second retry attempt', async () => {
```

**L334**
```typescript
    const fake = buildFakeAnthropic({
```

**L335**
```typescript
      responses: [
```

**L336**
```typescript
        { type: 'error', status: 503 }, // attempt 0
```

**L337**
```typescript
        { type: 'error', status: 503 }, // attempt 1 → fallback 적용
```

**L338**
```typescript
        { type: 'success', content: 'ok' }, // attempt 2 — fallback model로 성공
```

**L339**
```typescript
      ],
```

**L340**
```typescript
    });
```

**L341**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L342**
```typescript
      anthropicClient: fake,
```

**L343**
```typescript
      enableMonthlyDowngrade: false,
```

**L344**
```typescript
    });
```

**L345**
```typescript

```

**L346**
```typescript
    const result = await client.complete({
```

**L347**
```typescript
      agentRole: 'classifier',
```

**L348**
```typescript
      inboundMessage: 'hi',
```

**L349**
```typescript
    });
```

**L350**
```typescript
    // 두 번째 재시도부터 fallback 모델(sonnet) 사용
```

**L351**
```typescript
    expect(result.model).toBe('claude-sonnet-4-6');
```

**L352**
```typescript

```

**L353**
```typescript
    const runInserts = supabase.__calls.insert.filter(
```

**L354**
```typescript
      (c) => c.schema === 'ai' && c.table === 'runs',
```

**L355**
```typescript
    );
```

**L356**
```typescript
    expect(runInserts).toHaveLength(1);
```

**L357**
```typescript
    expect((runInserts[0]?.payload as Record<string, unknown>).status).toBe('completed');
```

**L358**
```typescript
  });
```

**L359**
```typescript

```

**L360**
```typescript
  it('does NOT retry on 4xx and records failure', async () => {
```

**L361**
```typescript
    const fake = buildFakeAnthropic({
```

**L362**
```typescript
      responses: [{ type: 'error', status: 400, message: 'Bad Request' }],
```

**L363**
```typescript
    });
```

**L364**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L365**
```typescript
      anthropicClient: fake,
```

**L366**
```typescript
      enableMonthlyDowngrade: false,
```

**L367**
```typescript
    });
```

**L368**
```typescript

```

**L369**
```typescript
    await expect(
```

**L370**
```typescript
      client.complete({
```

**L371**
```typescript
        agentRole: 'classifier',
```

**L372**
```typescript
        inboundMessage: 'hi',
```

**L373**
```typescript
      }),
```

**L374**
```typescript
    ).rejects.toBeInstanceOf(ClaudeApiError);
```

**L375**
```typescript

```

**L376**
```typescript
    expect((fake.messages.create as ReturnType<typeof vi.fn>).mock.calls).toHaveLength(1);
```

**L377**
```typescript

```

**L378**
```typescript
    // ai.runs INSERT — DB status='failed' (도메인 'failed' 그대로), error_status는 metadata
```

**L379**
```typescript
    const runInserts = supabase.__calls.insert.filter(
```

**L380**
```typescript
      (c) => c.schema === 'ai' && c.table === 'runs',
```

**L381**
```typescript
    );
```

**L382**
```typescript
    expect(runInserts).toHaveLength(1);
```

**L383**
```typescript
    const payload = runInserts[0]?.payload as Record<string, unknown>;
```

**L384**
```typescript
    expect(payload.status).toBe('failed');
```

**L385**
```typescript
    const meta = payload.metadata as Record<string, unknown>;
```

**L386**
```typescript
    expect(meta.error_status).toBe(400);
```

**L387**
```typescript
  });
```

**L388**
```typescript

```

**L389**
```typescript
  it('gives up after 3 attempts on persistent 5xx', async () => {
```

**L390**
```typescript
    const fake = buildFakeAnthropic({
```

**L391**
```typescript
      responses: [
```

**L392**
```typescript
        { type: 'error', status: 500 },
```

**L393**
```typescript
        { type: 'error', status: 500 },
```

**L394**
```typescript
        { type: 'error', status: 500 },
```

**L395**
```typescript
      ],
```

**L396**
```typescript
    });
```

**L397**
```typescript
    const client = new ClaudeClient(supabase as never, orgId, {
```

**L398**
```typescript
      anthropicClient: fake,
```

**L399**
```typescript
      enableMonthlyDowngrade: false,
```

**L400**
```typescript
    });
```

**L401**
```typescript

```

**L402**
```typescript
    await expect(
```

**L403**
```typescript
      client.complete({
```

**L404**
```typescript
        agentRole: 'classifier',
```

**L405**
```typescript
        inboundMessage: 'hi',
```

**L406**
```typescript
      }),
```

**L407**
```typescript
    ).rejects.toBeInstanceOf(ClaudeApiError);
```

**L408**
```typescript

```

**L409**
```typescript
    expect((fake.messages.create as ReturnType<typeof vi.fn>).mock.calls).toHaveLength(3);
```

**L410**
```typescript

```

**L411**
```typescript
    const runInserts = supabase.__calls.insert.filter(
```

**L412**
```typescript
      (c) => c.schema === 'ai' && c.table === 'runs',
```

**L413**
```typescript
    );
```

**L414**
```typescript
    const payload = runInserts[0]?.payload as Record<string, unknown>;
```

**L415**
```typescript
    expect(payload.status).toBe('failed');
```

**L416**
```typescript
    const meta = payload.metadata as Record<string, unknown>;
```

**L417**
```typescript
    expect(meta.retry_count).toBe(3);
```

**L418**
```typescript
  });
```

**L419**
```typescript
}, 30_000);
```

### `src\__tests__\email\auto-send-gate.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/email/auto-send-gate.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * auto-send-gate의 10단계 평가를 단계별로 검증.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * 시나리오:
```

**L7**
```typescript
 *   - global flag 비활성화 → global_disabled
```

**L8**
```typescript
 *   - rule 없음 → no_rule_defined
```

**L9**
```typescript
 *   - is_blocked → rule_blocked
```

**L10**
```typescript
 *   - module 불일치 → module_not_allowed
```

**L11**
```typescript
 *   - confidence 미달 → confidence_below_threshold
```

**L12**
```typescript
 *   - human 강제 → requires_human_approval / drafter_requires_human
```

**L13**
```typescript
 *   - risk_flags 존재 → risk_flags_present
```

**L14**
```typescript
 *   - blocked keyword 매칭 → blocked_keyword:xxx
```

**L15**
```typescript
 *   - daily limit 초과 → daily_limit_reached
```

**L16**
```typescript
 *   - 모든 통과 → allowed=true
```

**L17**
```typescript
 *
```

**L18**
```typescript
 * env.AI_AUTO_SEND_ENABLED는 setupFiles에서 false로 주입되어 있으므로,
```

**L19**
```typescript
 * "통과" 케이스는 vi.stubEnv 또는 직접 env 모듈 mock으로 우회한다.
```

**L20**
```typescript
 */
```

**L21**
```typescript

```

**L22**
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

**L23**
```typescript
import { evaluateAutoSend, matchBlockedKeyword } from '../../lib/email/auto-send-gate';
```

**L24**
```typescript
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
```

**L25**
```typescript
import type { ClassificationOutput } from '../../types/classification';
```

**L26**
```typescript

```

**L27**
```typescript
// 기본 통과 가능한 분류 결과
```

**L28**
```typescript
const baseClassification: ClassificationOutput = {
```

**L29**
```typescript
  category: 'simple_acknowledgment',
```

**L30**
```typescript
  urgency: 'low',
```

**L31**
```typescript
  sentiment: 'positive',
```

**L32**
```typescript
  requiresHuman: false,
```

**L33**
```typescript
  confidence: 0.97,
```

**L34**
```typescript
  rationale: 'simple ack',
```

**L35**
```typescript
  riskFlags: [],
```

**L36**
```typescript
  detectedLanguage: 'ko',
```

**L37**
```typescript
};
```

**L38**
```typescript

```

**L39**
```typescript
const baseRule = {
```

**L40**
```typescript
  id: 'rule-1',
```

**L41**
```typescript
  organization_id: 'org-1',
```

**L42**
```typescript
  classification_category: 'simple_acknowledgment',
```

**L43**
```typescript
  is_blocked: false,
```

**L44**
```typescript
  block_reason: null,
```

**L45**
```typescript
  min_confidence: 0.95,
```

**L46**
```typescript
  requires_human_approval: false,
```

**L47**
```typescript
  allowed_modules: ['investor', 'paper_mill'],
```

**L48**
```typescript
  blocked_keywords_in_body: [],
```

**L49**
```typescript
  daily_limit: 0,
```

**L50**
```typescript
  hourly_limit: 0,
```

**L51**
```typescript
  per_party_daily_limit: 0,
```

**L52**
```typescript
  requires_calendar_data: false,
```

**L53**
```typescript
  is_active: true,
```

**L54**
```typescript
};
```

**L55**
```typescript

```

**L56**
```typescript
describe('matchBlockedKeyword', () => {
```

**L57**
```typescript
  it('returns matched keyword (regex)', () => {
```

**L58**
```typescript
    expect(matchBlockedKeyword('we offer 5% discount', ['discount'])).toBe('discount');
```

**L59**
```typescript
    expect(matchBlockedKeyword('payment due today', ['\\bpayment\\b', 'invoice'])).toBe('\\bpayment\\b');
```

**L60**
```typescript
  });
```

**L61**
```typescript

```

**L62**
```typescript
  it('returns null when no match', () => {
```

**L63**
```typescript
    expect(matchBlockedKeyword('hello there', ['discount', 'invoice'])).toBeNull();
```

**L64**
```typescript
  });
```

**L65**
```typescript

```

**L66**
```typescript
  it('falls back to substring on invalid regex', () => {
```

**L67**
```typescript
    // ( 는 단독으로 잘못된 정규식 → substring 매칭으로 fallback
```

**L68**
```typescript
    expect(matchBlockedKeyword('special (discount) inside', ['('])).toBe('(');
```

**L69**
```typescript
  });
```

**L70**
```typescript

```

**L71**
```typescript
  it('case-insensitive', () => {
```

**L72**
```typescript
    expect(matchBlockedKeyword('Hello DISCOUNT here', ['discount'])).toBe('discount');
```

**L73**
```typescript
  });
```

**L74**
```typescript
});
```

**L75**
```typescript

```

**L76**
```typescript
/* --------------------------------------------------------------------
```

**L77**
```typescript
 * 다음 describe는 env 모듈을 mock해서 AI_AUTO_SEND_ENABLED=true 환경에서
```

**L78**
```typescript
 * 각 단계를 격리 검증한다.
```

**L79**
```typescript
 * "global_disabled" 경로는 evaluateAutoSend 첫 줄의 단순 조건이므로
```

**L80**
```typescript
 * 별도 단위 테스트 없이 스킵 — 통합 테스트에서 검증.
```

**L81**
```typescript
 * ------------------------------------------------------------------ */
```

**L82**
```typescript

```

**L83**
```typescript
vi.mock('../../lib/env', async () => {
```

**L84**
```typescript
  const real = await vi.importActual<typeof import('../../lib/env')>(
```

**L85**
```typescript
    '../../lib/env',
```

**L86**
```typescript
  );
```

**L87**
```typescript
  return {
```

**L88**
```typescript
    ...real,
```

**L89**
```typescript
    env: { ...real.env, AI_AUTO_SEND_ENABLED: true },
```

**L90**
```typescript
  };
```

**L91**
```typescript
});
```

**L92**
```typescript

```

**L93**
```typescript
describe('evaluateAutoSend (with AI_AUTO_SEND_ENABLED=true)', () => {
```

**L94**
```typescript
  let supabase: MockSupabase;
```

**L95**
```typescript

```

**L96**
```typescript
  beforeEach(() => {
```

**L97**
```typescript
    supabase = buildSupabaseMock();
```

**L98**
```typescript
  });
```

**L99**
```typescript

```

**L100**
```typescript
  it('blocks when no rule defined for category', async () => {
```

**L101**
```typescript
    supabase = buildSupabaseMock({
```

**L102**
```typescript
      'ai.auto_send_rules': { selectMaybeSingle: { data: null } },
```

**L103**
```typescript
    });
```

**L104**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L105**
```typescript
      organizationId: 'org-1',
```

**L106**
```typescript
      classification: baseClassification,
```

**L107**
```typescript
      draftBody: 'thanks',
```

**L108**
```typescript
    });
```

**L109**
```typescript
    expect(result.allowed).toBe(false);
```

**L110**
```typescript
    expect(result.reasons).toContain('no_rule_defined');
```

**L111**
```typescript
  });
```

**L112**
```typescript

```

**L113**
```typescript
  it('blocks when rule.is_blocked=true', async () => {
```

**L114**
```typescript
    supabase = buildSupabaseMock({
```

**L115**
```typescript
      'ai.auto_send_rules': {
```

**L116**
```typescript
        selectMaybeSingle: {
```

**L117**
```typescript
          data: { ...baseRule, is_blocked: true, block_reason: 'policy' },
```

**L118**
```typescript
        },
```

**L119**
```typescript
      },
```

**L120**
```typescript
    });
```

**L121**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L122**
```typescript
      organizationId: 'org-1',
```

**L123**
```typescript
      partyType: 'investor',
```

**L124**
```typescript
      classification: baseClassification,
```

**L125**
```typescript
      draftBody: 'thanks',
```

**L126**
```typescript
    });
```

**L127**
```typescript
    expect(result.allowed).toBe(false);
```

**L128**
```typescript
    expect(result.reasons).toContain('rule_blocked');
```

**L129**
```typescript
    expect(result.ruleId).toBe('rule-1');
```

**L130**
```typescript
  });
```

**L131**
```typescript

```

**L132**
```typescript
  it('blocks when module not in allowed_modules', async () => {
```

**L133**
```typescript
    supabase = buildSupabaseMock({
```

**L134**
```typescript
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
```

**L135**
```typescript
    });
```

**L136**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L137**
```typescript
      organizationId: 'org-1',
```

**L138**
```typescript
      partyType: 'partner', // not in ['investor','paper_mill']
```

**L139**
```typescript
      classification: baseClassification,
```

**L140**
```typescript
      draftBody: 'thanks',
```

**L141**
```typescript
    });
```

**L142**
```typescript
    expect(result.allowed).toBe(false);
```

**L143**
```typescript
    expect(result.reasons).toContain('module_not_allowed');
```

**L144**
```typescript
  });
```

**L145**
```typescript

```

**L146**
```typescript
  it('blocks when confidence below min_confidence', async () => {
```

**L147**
```typescript
    supabase = buildSupabaseMock({
```

**L148**
```typescript
      'ai.auto_send_rules': {
```

**L149**
```typescript
        selectMaybeSingle: { data: { ...baseRule, min_confidence: 0.95 } },
```

**L150**
```typescript
      },
```

**L151**
```typescript
    });
```

**L152**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L153**
```typescript
      organizationId: 'org-1',
```

**L154**
```typescript
      partyType: 'investor',
```

**L155**
```typescript
      classification: { ...baseClassification, confidence: 0.85 },
```

**L156**
```typescript
      draftBody: 'thanks',
```

**L157**
```typescript
    });
```

**L158**
```typescript
    expect(result.allowed).toBe(false);
```

**L159**
```typescript
    expect(result.reasons).toContain('confidence_below_threshold');
```

**L160**
```typescript
  });
```

**L161**
```typescript

```

**L162**
```typescript
  it('blocks when classification.requiresHuman=true', async () => {
```

**L163**
```typescript
    supabase = buildSupabaseMock({
```

**L164**
```typescript
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
```

**L165**
```typescript
    });
```

**L166**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L167**
```typescript
      organizationId: 'org-1',
```

**L168**
```typescript
      partyType: 'investor',
```

**L169**
```typescript
      classification: { ...baseClassification, requiresHuman: true },
```

**L170**
```typescript
      draftBody: 'thanks',
```

**L171**
```typescript
    });
```

**L172**
```typescript
    expect(result.allowed).toBe(false);
```

**L173**
```typescript
    expect(result.reasons).toContain('requires_human_approval');
```

**L174**
```typescript
  });
```

**L175**
```typescript

```

**L176**
```typescript
  it('blocks when drafterRequiresHuman=true', async () => {
```

**L177**
```typescript
    supabase = buildSupabaseMock({
```

**L178**
```typescript
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
```

**L179**
```typescript
    });
```

**L180**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L181**
```typescript
      organizationId: 'org-1',
```

**L182**
```typescript
      partyType: 'investor',
```

**L183**
```typescript
      classification: baseClassification,
```

**L184**
```typescript
      draftBody: 'thanks',
```

**L185**
```typescript
      drafterRequiresHuman: true,
```

**L186**
```typescript
    });
```

**L187**
```typescript
    expect(result.allowed).toBe(false);
```

**L188**
```typescript
    expect(result.reasons).toContain('drafter_requires_human');
```

**L189**
```typescript
  });
```

**L190**
```typescript

```

**L191**
```typescript
  it('blocks when riskFlags is non-empty', async () => {
```

**L192**
```typescript
    supabase = buildSupabaseMock({
```

**L193**
```typescript
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
```

**L194**
```typescript
    });
```

**L195**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L196**
```typescript
      organizationId: 'org-1',
```

**L197**
```typescript
      partyType: 'investor',
```

**L198**
```typescript
      classification: { ...baseClassification, riskFlags: ['valuation_topic'] },
```

**L199**
```typescript
      draftBody: 'thanks',
```

**L200**
```typescript
    });
```

**L201**
```typescript
    expect(result.allowed).toBe(false);
```

**L202**
```typescript
    expect(result.reasons).toContain('risk_flags_present');
```

**L203**
```typescript
  });
```

**L204**
```typescript

```

**L205**
```typescript
  it('blocks when blocked keyword found in body', async () => {
```

**L206**
```typescript
    supabase = buildSupabaseMock({
```

**L207**
```typescript
      'ai.auto_send_rules': {
```

**L208**
```typescript
        selectMaybeSingle: {
```

**L209**
```typescript
          data: { ...baseRule, blocked_keywords_in_body: ['valuation', 'NDA'] },
```

**L210**
```typescript
        },
```

**L211**
```typescript
      },
```

**L212**
```typescript
    });
```

**L213**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L214**
```typescript
      organizationId: 'org-1',
```

**L215**
```typescript
      partyType: 'investor',
```

**L216**
```typescript
      classification: baseClassification,
```

**L217**
```typescript
      draftBody: 'Our valuation is around $5M.',
```

**L218**
```typescript
    });
```

**L219**
```typescript
    expect(result.allowed).toBe(false);
```

**L220**
```typescript
    expect(result.reasons.some((r) => r.startsWith('blocked_keyword:'))).toBe(true);
```

**L221**
```typescript
  });
```

**L222**
```typescript

```

**L223**
```typescript
  it('blocks when daily limit reached', async () => {
```

**L224**
```typescript
    supabase = buildSupabaseMock({
```

**L225**
```typescript
      'ai.auto_send_rules': {
```

**L226**
```typescript
        selectMaybeSingle: { data: { ...baseRule, daily_limit: 50 } },
```

**L227**
```typescript
      },
```

**L228**
```typescript
      'app.communications': { selectCount: { count: 50 } },
```

**L229**
```typescript
    });
```

**L230**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L231**
```typescript
      organizationId: 'org-1',
```

**L232**
```typescript
      partyType: 'investor',
```

**L233**
```typescript
      classification: baseClassification,
```

**L234**
```typescript
      draftBody: 'thanks',
```

**L235**
```typescript
    });
```

**L236**
```typescript
    expect(result.allowed).toBe(false);
```

**L237**
```typescript
    expect(result.reasons).toContain('daily_limit_reached');
```

**L238**
```typescript
  });
```

**L239**
```typescript

```

**L240**
```typescript
  it('blocks when hourly limit reached', async () => {
```

**L241**
```typescript
    supabase = buildSupabaseMock({
```

**L242**
```typescript
      'ai.auto_send_rules': {
```

**L243**
```typescript
        selectMaybeSingle: { data: { ...baseRule, hourly_limit: 5 } },
```

**L244**
```typescript
      },
```

**L245**
```typescript
      'app.communications': { selectCount: { count: 5 } },
```

**L246**
```typescript
    });
```

**L247**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L248**
```typescript
      organizationId: 'org-1',
```

**L249**
```typescript
      partyType: 'investor',
```

**L250**
```typescript
      classification: baseClassification,
```

**L251**
```typescript
      draftBody: 'thanks',
```

**L252**
```typescript
    });
```

**L253**
```typescript
    expect(result.allowed).toBe(false);
```

**L254**
```typescript
    expect(result.reasons).toContain('hourly_limit_reached');
```

**L255**
```typescript
  });
```

**L256**
```typescript

```

**L257**
```typescript
  it('blocks when per-party daily limit reached', async () => {
```

**L258**
```typescript
    supabase = buildSupabaseMock({
```

**L259**
```typescript
      'ai.auto_send_rules': {
```

**L260**
```typescript
        selectMaybeSingle: { data: { ...baseRule, per_party_daily_limit: 3 } },
```

**L261**
```typescript
      },
```

**L262**
```typescript
      'app.communications': { selectCount: { count: 3 } },
```

**L263**
```typescript
    });
```

**L264**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L265**
```typescript
      organizationId: 'org-1',
```

**L266**
```typescript
      partyType: 'investor',
```

**L267**
```typescript
      partyId: 'party-x',
```

**L268**
```typescript
      classification: baseClassification,
```

**L269**
```typescript
      draftBody: 'thanks',
```

**L270**
```typescript
    });
```

**L271**
```typescript
    expect(result.allowed).toBe(false);
```

**L272**
```typescript
    expect(result.reasons).toContain('per_party_daily_limit_reached');
```

**L273**
```typescript
  });
```

**L274**
```typescript

```

**L275**
```typescript
  it('blocks meeting_scheduling when calendar not connected', async () => {
```

**L276**
```typescript
    supabase = buildSupabaseMock({
```

**L277**
```typescript
      'ai.auto_send_rules': {
```

**L278**
```typescript
        selectMaybeSingle: {
```

**L279**
```typescript
          data: {
```

**L280**
```typescript
            ...baseRule,
```

**L281**
```typescript
            classification_category: 'meeting_scheduling',
```

**L282**
```typescript
            requires_calendar_data: true,
```

**L283**
```typescript
          },
```

**L284**
```typescript
        },
```

**L285**
```typescript
      },
```

**L286**
```typescript
      'app.organizations': {
```

**L287**
```typescript
        selectMaybeSingle: { data: { settings: { calendar_connected: false } } },
```

**L288**
```typescript
      },
```

**L289**
```typescript
    });
```

**L290**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L291**
```typescript
      organizationId: 'org-1',
```

**L292**
```typescript
      partyType: 'investor',
```

**L293**
```typescript
      classification: { ...baseClassification, category: 'meeting_scheduling' },
```

**L294**
```typescript
      draftBody: 'I can meet on Tuesday at 14:00 KST',
```

**L295**
```typescript
    });
```

**L296**
```typescript
    expect(result.allowed).toBe(false);
```

**L297**
```typescript
    expect(result.reasons).toContain('calendar_data_required');
```

**L298**
```typescript
  });
```

**L299**
```typescript

```

**L300**
```typescript
  it('allows when all checks pass', async () => {
```

**L301**
```typescript
    supabase = buildSupabaseMock({
```

**L302**
```typescript
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
```

**L303**
```typescript
      'app.communications': { selectCount: { count: 0 } },
```

**L304**
```typescript
    });
```

**L305**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L306**
```typescript
      organizationId: 'org-1',
```

**L307**
```typescript
      partyType: 'investor',
```

**L308**
```typescript
      classification: baseClassification,
```

**L309**
```typescript
      draftBody: 'thanks for the info',
```

**L310**
```typescript
    });
```

**L311**
```typescript
    expect(result.allowed).toBe(true);
```

**L312**
```typescript
    expect(result.reasons).toEqual([]);
```

**L313**
```typescript
    expect(result.ruleId).toBe('rule-1');
```

**L314**
```typescript
  });
```

**L315**
```typescript

```

**L316**
```typescript
  it('returns rule_lookup_error when DB fails', async () => {
```

**L317**
```typescript
    supabase = buildSupabaseMock({
```

**L318**
```typescript
      'ai.auto_send_rules': {
```

**L319**
```typescript
        selectMaybeSingle: { data: null, error: { message: 'connection lost' } },
```

**L320**
```typescript
      },
```

**L321**
```typescript
    });
```

**L322**
```typescript
    const result = await evaluateAutoSend(supabase as never, {
```

**L323**
```typescript
      organizationId: 'org-1',
```

**L324**
```typescript
      classification: baseClassification,
```

**L325**
```typescript
      draftBody: 'thanks',
```

**L326**
```typescript
    });
```

**L327**
```typescript
    expect(result.allowed).toBe(false);
```

**L328**
```typescript
    expect(result.reasons).toContain('rule_lookup_error');
```

**L329**
```typescript
  });
```

**L330**
```typescript
});
```

### `src\__tests__\email\header-parser.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/email/header-parser.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 순수 함수 위주 테스트:
```

**L5**
```typescript
 *   - parseInboundMessage: 헤더 추출, URM 헤더, fallback footer
```

**L6**
```typescript
 *   - findThreadId: 3단계 우선순위 (urm_header → in_reply_to → references)
```

**L7**
```typescript
 *   - matchSenderToContactAndParty: 정확 매칭, 도메인 매칭, generic 도메인 제외
```

**L8**
```typescript
 */
```

**L9**
```typescript

```

**L10**
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

**L11**
```typescript
import type { ParsedMail } from 'mailparser';
```

**L12**
```typescript
import {
```

**L13**
```typescript
  parseInboundMessage,
```

**L14**
```typescript
  extractUrmHeadersFromHtmlFooter,
```

**L15**
```typescript
  hasAnyUrmHeader,
```

**L16**
```typescript
  findThreadId,
```

**L17**
```typescript
  matchSenderToContactAndParty,
```

**L18**
```typescript
} from '../../lib/email/header-parser';
```

**L19**
```typescript
import { URM_HEADER_NAMES } from '../../types/email';
```

**L20**
```typescript
import { buildSupabaseMock } from '../setup/supabase-mock';
```

**L21**
```typescript

```

**L22**
```typescript
// ParsedMail 헬퍼 — mailparser는 내부적으로 Map 기반 headers + value 배열 사용
```

**L23**
```typescript
function makeParsedMail(
```

**L24**
```typescript
  overrides: Partial<ParsedMail> & { headerEntries?: Array<[string, unknown]> } = {},
```

**L25**
```typescript
): ParsedMail {
```

**L26**
```typescript
  const headers = new Map<string, unknown>(overrides.headerEntries ?? []);
```

**L27**
```typescript
  return {
```

**L28**
```typescript
    headers,
```

**L29**
```typescript
    headerLines: [],
```

**L30**
```typescript
    attachments: [],
```

**L31**
```typescript
    text: overrides.text ?? '',
```

**L32**
```typescript
    html: overrides.html ?? false,
```

**L33**
```typescript
    subject: overrides.subject,
```

**L34**
```typescript
    messageId: overrides.messageId,
```

**L35**
```typescript
    inReplyTo: overrides.inReplyTo,
```

**L36**
```typescript
    references: overrides.references,
```

**L37**
```typescript
    from: overrides.from,
```

**L38**
```typescript
    to: overrides.to,
```

**L39**
```typescript
    cc: overrides.cc,
```

**L40**
```typescript
    replyTo: overrides.replyTo,
```

**L41**
```typescript
    date: overrides.date,
```

**L42**
```typescript
  } as ParsedMail;
```

**L43**
```typescript
}
```

**L44**
```typescript

```

**L45**
```typescript
describe('parseInboundMessage', () => {
```

**L46**
```typescript
  it('extracts message-id, subject, from, to, references', () => {
```

**L47**
```typescript
    const parsed = makeParsedMail({
```

**L48**
```typescript
      messageId: '<abc@ex.com>',
```

**L49**
```typescript
      subject: 'Hello',
```

**L50**
```typescript
      from: {
```

**L51**
```typescript
        text: 'A B <a@b.com>',
```

**L52**
```typescript
        html: '',
```

**L53**
```typescript
        value: [{ name: 'A B', address: 'a@b.com' }],
```

**L54**
```typescript
      },
```

**L55**
```typescript
      to: {
```

**L56**
```typescript
        text: 'c@d.com',
```

**L57**
```typescript
        html: '',
```

**L58**
```typescript
        value: [{ name: '', address: 'c@d.com' }],
```

**L59**
```typescript
      },
```

**L60**
```typescript
      inReplyTo: '<prev@ex.com>',
```

**L61**
```typescript
      references: ['<r1@ex.com>', '<r2@ex.com>'],
```

**L62**
```typescript
      date: new Date('2026-01-15T10:00:00Z'),
```

**L63**
```typescript
    });
```

**L64**
```typescript

```

**L65**
```typescript
    const result = parseInboundMessage(parsed);
```

**L66**
```typescript

```

**L67**
```typescript
    expect(result.messageId).toBe('<abc@ex.com>');
```

**L68**
```typescript
    expect(result.subject).toBe('Hello');
```

**L69**
```typescript
    expect(result.from).toEqual({ name: 'A B', address: 'a@b.com' });
```

**L70**
```typescript
    expect(result.to).toEqual([{ name: '', address: 'c@d.com' }]);
```

**L71**
```typescript
    expect(result.inReplyTo).toBe('<prev@ex.com>');
```

**L72**
```typescript
    expect(result.references).toEqual(['<r1@ex.com>', '<r2@ex.com>']);
```

**L73**
```typescript
    expect(result.date.toISOString()).toBe('2026-01-15T10:00:00.000Z');
```

**L74**
```typescript
  });
```

**L75**
```typescript

```

**L76**
```typescript
  it('parses references string format ("<r1> <r2>")', () => {
```

**L77**
```typescript
    const parsed = makeParsedMail({
```

**L78**
```typescript
      messageId: '<x@x>',
```

**L79**
```typescript
      references: '<r1@a> <r2@a>  <r3@a>',
```

**L80**
```typescript
    } as Partial<ParsedMail>);
```

**L81**
```typescript
    const result = parseInboundMessage(parsed);
```

**L82**
```typescript
    expect(result.references).toEqual(['<r1@a>', '<r2@a>', '<r3@a>']);
```

**L83**
```typescript
  });
```

**L84**
```typescript

```

**L85**
```typescript
  it('falls back gracefully when fields are missing', () => {
```

**L86**
```typescript
    const parsed = makeParsedMail({});
```

**L87**
```typescript
    const result = parseInboundMessage(parsed);
```

**L88**
```typescript

```

**L89**
```typescript
    expect(result.messageId).toMatch(/^<unknown-\d+@local>$/);
```

**L90**
```typescript
    expect(result.subject).toBe('(no subject)');
```

**L91**
```typescript
    expect(result.from.address).toBe('unknown@unknown');
```

**L92**
```typescript
    expect(result.to).toEqual([]);
```

**L93**
```typescript
    expect(result.references).toEqual([]);
```

**L94**
```typescript
    expect(result.date).toBeInstanceOf(Date);
```

**L95**
```typescript
  });
```

**L96**
```typescript

```

**L97**
```typescript
  it('extracts X-URM-* headers from headers Map', () => {
```

**L98**
```typescript
    const parsed = makeParsedMail({
```

**L99**
```typescript
      messageId: '<x>',
```

**L100**
```typescript
      headerEntries: [
```

**L101**
```typescript
        [URM_HEADER_NAMES.engagementId, 'eng-123'],
```

**L102**
```typescript
        [URM_HEADER_NAMES.communicationId, 'comm-456'],
```

**L103**
```typescript
        [URM_HEADER_NAMES.autoSend, 'true'],
```

**L104**
```typescript
        [URM_HEADER_NAMES.brandVoiceId, 'bv-789'],
```

**L105**
```typescript
      ],
```

**L106**
```typescript
    });
```

**L107**
```typescript
    const result = parseInboundMessage(parsed);
```

**L108**
```typescript
    expect(result.urmHeaders).toEqual({
```

**L109**
```typescript
      engagementId: 'eng-123',
```

**L110**
```typescript
      communicationId: 'comm-456',
```

**L111**
```typescript
      autoSend: true,
```

**L112**
```typescript
      brandVoiceId: 'bv-789',
```

**L113**
```typescript
    });
```

**L114**
```typescript
  });
```

**L115**
```typescript

```

**L116**
```typescript
  it('parses X-URM-Auto-Send=false correctly', () => {
```

**L117**
```typescript
    const parsed = makeParsedMail({
```

**L118**
```typescript
      messageId: '<x>',
```

**L119**
```typescript
      headerEntries: [[URM_HEADER_NAMES.autoSend, 'false']],
```

**L120**
```typescript
    });
```

**L121**
```typescript
    const result = parseInboundMessage(parsed);
```

**L122**
```typescript
    expect(result.urmHeaders.autoSend).toBe(false);
```

**L123**
```typescript
  });
```

**L124**
```typescript

```

**L125**
```typescript
  it('falls back to invisible HTML footer when headers are absent', () => {
```

**L126**
```typescript
    const parsed = makeParsedMail({
```

**L127**
```typescript
      messageId: '<x>',
```

**L128**
```typescript
      html: '<div>body</div><!-- urm:c=comm-aaa;auto=1;e=eng-bbb;bv=bv-ccc -->',
```

**L129**
```typescript
    });
```

**L130**
```typescript
    const result = parseInboundMessage(parsed);
```

**L131**
```typescript
    expect(result.urmHeaders).toEqual({
```

**L132**
```typescript
      communicationId: 'comm-aaa',
```

**L133**
```typescript
      autoSend: true,
```

**L134**
```typescript
      engagementId: 'eng-bbb',
```

**L135**
```typescript
      brandVoiceId: 'bv-ccc',
```

**L136**
```typescript
    });
```

**L137**
```typescript
  });
```

**L138**
```typescript

```

**L139**
```typescript
  it('header takes precedence over HTML footer', () => {
```

**L140**
```typescript
    const parsed = makeParsedMail({
```

**L141**
```typescript
      messageId: '<x>',
```

**L142**
```typescript
      headerEntries: [[URM_HEADER_NAMES.communicationId, 'comm-from-header']],
```

**L143**
```typescript
      html: '<!-- urm:c=comm-from-footer -->',
```

**L144**
```typescript
    });
```

**L145**
```typescript
    const result = parseInboundMessage(parsed);
```

**L146**
```typescript
    expect(result.urmHeaders.communicationId).toBe('comm-from-header');
```

**L147**
```typescript
  });
```

**L148**
```typescript
});
```

**L149**
```typescript

```

**L150**
```typescript
describe('extractUrmHeadersFromHtmlFooter', () => {
```

**L151**
```typescript
  it('parses footer with all fields', () => {
```

**L152**
```typescript
    const r = extractUrmHeadersFromHtmlFooter(
```

**L153**
```typescript
      '<!-- urm:c=cc;auto=1;e=ee;bv=bb -->',
```

**L154**
```typescript
    );
```

**L155**
```typescript
    expect(r).toEqual({
```

**L156**
```typescript
      communicationId: 'cc',
```

**L157**
```typescript
      autoSend: true,
```

**L158**
```typescript
      engagementId: 'ee',
```

**L159**
```typescript
      brandVoiceId: 'bb',
```

**L160**
```typescript
    });
```

**L161**
```typescript
  });
```

**L162**
```typescript

```

**L163**
```typescript
  it('handles auto=0 as false', () => {
```

**L164**
```typescript
    const r = extractUrmHeadersFromHtmlFooter('<!-- urm:c=x;auto=0 -->');
```

**L165**
```typescript
    expect(r.autoSend).toBe(false);
```

**L166**
```typescript
  });
```

**L167**
```typescript

```

**L168**
```typescript
  it('returns empty object when footer is absent', () => {
```

**L169**
```typescript
    expect(extractUrmHeadersFromHtmlFooter('<div>no footer</div>')).toEqual({});
```

**L170**
```typescript
  });
```

**L171**
```typescript
});
```

**L172**
```typescript

```

**L173**
```typescript
describe('hasAnyUrmHeader', () => {
```

**L174**
```typescript
  it('returns true if any field is set', () => {
```

**L175**
```typescript
    expect(hasAnyUrmHeader({ communicationId: 'x' })).toBe(true);
```

**L176**
```typescript
    expect(hasAnyUrmHeader({ autoSend: false })).toBe(true);
```

**L177**
```typescript
  });
```

**L178**
```typescript
  it('returns false for empty object', () => {
```

**L179**
```typescript
    expect(hasAnyUrmHeader({})).toBe(false);
```

**L180**
```typescript
  });
```

**L181**
```typescript
});
```

**L182**
```typescript

```

**L183**
```typescript
describe('findThreadId — priority order', () => {
```

**L184**
```typescript
  const orgId = 'org-1';
```

**L185**
```typescript

```

**L186**
```typescript
  it('[1] matches by X-URM-Communication-Id first', async () => {
```

**L187**
```typescript
    const sb = buildSupabaseMock({
```

**L188**
```typescript
      'app.communications': {
```

**L189**
```typescript
        selectMaybeSingle: { data: { thread_id: 'thread-from-urm', engagement_id: 'eng-1' } },
```

**L190**
```typescript
      },
```

**L191**
```typescript
    });
```

**L192**
```typescript
    const result = await findThreadId(sb as never, orgId, {
```

**L193**
```typescript
      messageId: '<x>',
```

**L194**
```typescript
      references: [],
```

**L195**
```typescript
      from: { address: 'a@b' },
```

**L196**
```typescript
      to: [],
```

**L197**
```typescript
      subject: '',
```

**L198**
```typescript
      date: new Date(),
```

**L199**
```typescript
      urmHeaders: { communicationId: 'comm-99' },
```

**L200**
```typescript
    });
```

**L201**
```typescript
    expect(result.threadId).toBe('thread-from-urm');
```

**L202**
```typescript
    expect(result.matchedBy).toBe('urm_header');
```

**L203**
```typescript
    expect(result.matchedEngagementId).toBe('eng-1');
```

**L204**
```typescript
  });
```

**L205**
```typescript

```

**L206**
```typescript
  it('[2] falls back to In-Reply-To when URM header is missing', async () => {
```

**L207**
```typescript
    const sb = buildSupabaseMock({
```

**L208**
```typescript
      'app.communications': {
```

**L209**
```typescript
        selectMaybeSingle: { data: { id: 'c-1', thread_id: 'thread-irt', engagement_id: null } },
```

**L210**
```typescript
      },
```

**L211**
```typescript
    });
```

**L212**
```typescript
    const result = await findThreadId(sb as never, orgId, {
```

**L213**
```typescript
      messageId: '<x>',
```

**L214**
```typescript
      inReplyTo: '<prev@ex>',
```

**L215**
```typescript
      references: [],
```

**L216**
```typescript
      from: { address: 'a@b' },
```

**L217**
```typescript
      to: [],
```

**L218**
```typescript
      subject: '',
```

**L219**
```typescript
      date: new Date(),
```

**L220**
```typescript
      urmHeaders: {},
```

**L221**
```typescript
    });
```

**L222**
```typescript
    expect(result.threadId).toBe('thread-irt');
```

**L223**
```typescript
    expect(result.matchedBy).toBe('in_reply_to');
```

**L224**
```typescript
  });
```

**L225**
```typescript

```

**L226**
```typescript
  it('[3] falls back to References (reverse) when In-Reply-To misses', async () => {
```

**L227**
```typescript
    let calls = 0;
```

**L228**
```typescript
    const sb = buildSupabaseMock({
```

**L229**
```typescript
      'app.communications': {
```

**L230**
```typescript
        selectMaybeSingle: { data: null },
```

**L231**
```typescript
      },
```

**L232**
```typescript
    });
```

**L233**
```typescript
    // overwrite maybeSingle to return null first, then matched
```

**L234**
```typescript
    const originalSchema = sb.schema;
```

**L235**
```typescript
    sb.schema = vi.fn((schemaName: string) => ({
```

**L236**
```typescript
      from: (table: string) => {
```

**L237**
```typescript
        const orig = originalSchema(schemaName).from(table) as Record<string, unknown>;
```

**L238**
```typescript
        const builder: Record<string, unknown> = { ...orig };
```

**L239**
```typescript
        builder.maybeSingle = vi.fn(() => {
```

**L240**
```typescript
          calls += 1;
```

**L241**
```typescript
          // 첫 두 번(In-Reply-To는 미리 매칭 시도되지만 본 케이스는 없음;
```

**L242**
```typescript
          // references 역순 r2 → 매칭 성공 가정)
```

**L243**
```typescript
          if (calls === 1) {
```

**L244**
```typescript
            return Promise.resolve({
```

**L245**
```typescript
              data: { id: 'c-2', thread_id: 'thread-ref', engagement_id: 'eng-2' },
```

**L246**
```typescript
              error: null,
```

**L247**
```typescript
            });
```

**L248**
```typescript
          }
```

**L249**
```typescript
          return Promise.resolve({ data: null, error: null });
```

**L250**
```typescript
        });
```

**L251**
```typescript
        // chain 메서드들도 모두 builder 반환
```

**L252**
```typescript
        for (const m of ['select', 'eq', 'is', 'order', 'limit']) {
```

**L253**
```typescript
          builder[m] = vi.fn(() => builder);
```

**L254**
```typescript
        }
```

**L255**
```typescript
        return builder;
```

**L256**
```typescript
      },
```

**L257**
```typescript
    })) as unknown as typeof sb.schema;
```

**L258**
```typescript

```

**L259**
```typescript
    const result = await findThreadId(sb as never, orgId, {
```

**L260**
```typescript
      messageId: '<x>',
```

**L261**
```typescript
      references: ['<r1@a>', '<r2@a>'],
```

**L262**
```typescript
      from: { address: 'a@b' },
```

**L263**
```typescript
      to: [],
```

**L264**
```typescript
      subject: '',
```

**L265**
```typescript
      date: new Date(),
```

**L266**
```typescript
      urmHeaders: {},
```

**L267**
```typescript
    });
```

**L268**
```typescript
    expect(result.threadId).toBe('thread-ref');
```

**L269**
```typescript
    expect(result.matchedBy).toBe('references');
```

**L270**
```typescript
  });
```

**L271**
```typescript

```

**L272**
```typescript
  it('returns null when nothing matches', async () => {
```

**L273**
```typescript
    const sb = buildSupabaseMock({
```

**L274**
```typescript
      'app.communications': { selectMaybeSingle: { data: null } },
```

**L275**
```typescript
    });
```

**L276**
```typescript
    const result = await findThreadId(sb as never, orgId, {
```

**L277**
```typescript
      messageId: '<x>',
```

**L278**
```typescript
      references: [],
```

**L279**
```typescript
      from: { address: 'a@b' },
```

**L280**
```typescript
      to: [],
```

**L281**
```typescript
      subject: '',
```

**L282**
```typescript
      date: new Date(),
```

**L283**
```typescript
      urmHeaders: {},
```

**L284**
```typescript
    });
```

**L285**
```typescript
    expect(result.threadId).toBeNull();
```

**L286**
```typescript
    expect(result.matchedBy).toBe('none');
```

**L287**
```typescript
  });
```

**L288**
```typescript
});
```

**L289**
```typescript

```

**L290**
```typescript
describe('matchSenderToContactAndParty', () => {
```

**L291**
```typescript
  const orgId = 'org-1';
```

**L292**
```typescript

```

**L293**
```typescript
  beforeEach(() => {
```

**L294**
```typescript
    vi.clearAllMocks();
```

**L295**
```typescript
  });
```

**L296**
```typescript

```

**L297**
```typescript
  it('returns "none" for empty/unknown address', async () => {
```

**L298**
```typescript
    const sb = buildSupabaseMock();
```

**L299**
```typescript
    const r1 = await matchSenderToContactAndParty(sb as never, orgId, '');
```

**L300**
```typescript
    expect(r1.matchedBy).toBe('none');
```

**L301**
```typescript
    const r2 = await matchSenderToContactAndParty(
```

**L302**
```typescript
      sb as never,
```

**L303**
```typescript
      orgId,
```

**L304**
```typescript
      'unknown@unknown',
```

**L305**
```typescript
    );
```

**L306**
```typescript
    expect(r2.matchedBy).toBe('none');
```

**L307**
```typescript
  });
```

**L308**
```typescript

```

**L309**
```typescript
  it('matches by exact contact email', async () => {
```

**L310**
```typescript
    const sb = buildSupabaseMock({
```

**L311**
```typescript
      'app.contacts': {
```

**L312**
```typescript
        selectMaybeSingle: { data: { id: 'contact-1', party_id: 'party-1' } },
```

**L313**
```typescript
      },
```

**L314**
```typescript
    });
```

**L315**
```typescript
    const r = await matchSenderToContactAndParty(
```

**L316**
```typescript
      sb as never,
```

**L317**
```typescript
      orgId,
```

**L318**
```typescript
      'CEO@AcmeCorp.com',
```

**L319**
```typescript
    );
```

**L320**
```typescript
    expect(r.matchedBy).toBe('contact_email');
```

**L321**
```typescript
    expect(r.contactId).toBe('contact-1');
```

**L322**
```typescript
    expect(r.partyId).toBe('party-1');
```

**L323**
```typescript
  });
```

**L324**
```typescript

```

**L325**
```typescript
  it('returns "none" for generic email domains (gmail, naver)', async () => {
```

**L326**
```typescript
    const sb = buildSupabaseMock({
```

**L327**
```typescript
      'app.contacts': { selectMaybeSingle: { data: null } },
```

**L328**
```typescript
    });
```

**L329**
```typescript
    const r1 = await matchSenderToContactAndParty(
```

**L330**
```typescript
      sb as never,
```

**L331**
```typescript
      orgId,
```

**L332**
```typescript
      'random@gmail.com',
```

**L333**
```typescript
    );
```

**L334**
```typescript
    expect(r1.matchedBy).toBe('none');
```

**L335**
```typescript
    const r2 = await matchSenderToContactAndParty(
```

**L336**
```typescript
      sb as never,
```

**L337**
```typescript
      orgId,
```

**L338**
```typescript
      'random@naver.com',
```

**L339**
```typescript
    );
```

**L340**
```typescript
    expect(r2.matchedBy).toBe('none');
```

**L341**
```typescript
  });
```

**L342**
```typescript

```

**L343**
```typescript
  it('falls back to party email domain match for non-generic domains', async () => {
```

**L344**
```typescript
    let callCount = 0;
```

**L345**
```typescript
    const sb = buildSupabaseMock();
```

**L346**
```typescript
    sb.schema = vi.fn((schemaName: string) => ({
```

**L347**
```typescript
      from: (_table: string) => {
```

**L348**
```typescript
        const builder: Record<string, unknown> = {};
```

**L349**
```typescript
        for (const m of ['select', 'eq', 'is', 'like', 'order', 'limit']) {
```

**L350**
```typescript
          builder[m] = vi.fn(() => builder);
```

**L351**
```typescript
        }
```

**L352**
```typescript
        builder.maybeSingle = vi.fn(() => {
```

**L353**
```typescript
          callCount += 1;
```

**L354**
```typescript
          if (callCount === 1) {
```

**L355**
```typescript
            // 첫 호출 (정확 매칭) — null
```

**L356**
```typescript
            return Promise.resolve({ data: null, error: null });
```

**L357**
```typescript
          }
```

**L358**
```typescript
          // 두 번째 호출 (도메인 매칭) — 매칭됨
```

**L359**
```typescript
          return Promise.resolve({
```

**L360**
```typescript
            data: { id: 'contact-x', party_id: 'party-x' },
```

**L361**
```typescript
            error: null,
```

**L362**
```typescript
          });
```

**L363**
```typescript
        });
```

**L364**
```typescript
        return builder;
```

**L365**
```typescript
      },
```

**L366**
```typescript
    })) as unknown as typeof sb.schema;
```

**L367**
```typescript

```

**L368**
```typescript
    const r = await matchSenderToContactAndParty(
```

**L369**
```typescript
      sb as never,
```

**L370**
```typescript
      orgId,
```

**L371**
```typescript
      'someone@acmecorp.com',
```

**L372**
```typescript
    );
```

**L373**
```typescript
    expect(r.matchedBy).toBe('party_email_domain');
```

**L374**
```typescript
    expect(r.partyId).toBe('party-x');
```

**L375**
```typescript
  });
```

**L376**
```typescript
});
```

### `src\__tests__\email\mailcarrier.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/email/mailcarrier.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 단위 테스트 — IMAP I/O는 IImapClient·ParserFn 인터페이스로 추상화되어 있어
```

**L5**
```typescript
 * 모두 fake로 교체. Supabase는 buildSupabaseMock으로 응답 주입.
```

**L6**
```typescript
 *
```

**L7**
```typescript
 * 테스트 시나리오:
```

**L8**
```typescript
 *   1. persistInbound — 신규 메시지 정상 INSERT
```

**L9**
```typescript
 *   2. persistInbound — Message-ID 중복 시 null 반환 (멱등성)
```

**L10**
```typescript
 *   3. persistInbound — 첨부파일 Storage 업로드 + attachments INSERT
```

**L11**
```typescript
 *   4. persistInbound — PII 마스킹된 body로 저장
```

**L12**
```typescript
 *   5. sanitizeFilename — 경로 구분자·제어문자 제거
```

**L13**
```typescript
 *   6. fetchAndProcessNew — onMessage 호출 + Seen 플래그
```

**L14**
```typescript
 */
```

**L15**
```typescript

```

**L16**
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

**L17**
```typescript
import { Buffer } from 'node:buffer';
```

**L18**
```typescript
import type { ParsedMail } from 'mailparser';
```

**L19**
```typescript
import {
```

**L20**
```typescript
  MailCarrierClient,
```

**L21**
```typescript
  sanitizeFilename,
```

**L22**
```typescript
  type IImapClient,
```

**L23**
```typescript
  type ParserFn,
```

**L24**
```typescript
} from '../../lib/email/mailcarrier';
```

**L25**
```typescript
import type { InboundMessageEvent } from '../../types/email';
```

**L26**
```typescript
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
```

**L27**
```typescript

```

**L28**
```typescript
// ParsedMail 헬퍼
```

**L29**
```typescript
function makeParsedMail(
```

**L30**
```typescript
  overrides: Partial<ParsedMail> & { headerEntries?: Array<[string, unknown]> } = {},
```

**L31**
```typescript
): ParsedMail {
```

**L32**
```typescript
  return {
```

**L33**
```typescript
    headers: new Map<string, unknown>(overrides.headerEntries ?? []),
```

**L34**
```typescript
    headerLines: [],
```

**L35**
```typescript
    attachments: overrides.attachments ?? [],
```

**L36**
```typescript
    text: overrides.text ?? '',
```

**L37**
```typescript
    html: overrides.html ?? false,
```

**L38**
```typescript
    subject: overrides.subject,
```

**L39**
```typescript
    messageId: overrides.messageId,
```

**L40**
```typescript
    inReplyTo: overrides.inReplyTo,
```

**L41**
```typescript
    references: overrides.references,
```

**L42**
```typescript
    from: overrides.from,
```

**L43**
```typescript
    to: overrides.to,
```

**L44**
```typescript
    cc: overrides.cc,
```

**L45**
```typescript
    replyTo: overrides.replyTo,
```

**L46**
```typescript
    date: overrides.date,
```

**L47**
```typescript
  } as ParsedMail;
```

**L48**
```typescript
}
```

**L49**
```typescript

```

**L50**
```typescript
function makeFakeImap(): IImapClient {
```

**L51**
```typescript
  return {
```

**L52**
```typescript
    connect: vi.fn(() => Promise.resolve()),
```

**L53**
```typescript
    logout: vi.fn(() => Promise.resolve()),
```

**L54**
```typescript
    mailboxOpen: vi.fn(() => Promise.resolve(null)),
```

**L55**
```typescript
    getMailboxLock: vi.fn(() =>
```

**L56**
```typescript
      Promise.resolve({ release: () => undefined }),
```

**L57**
```typescript
    ),
```

**L58**
```typescript
    fetch: vi.fn(() => emptyAsyncIterable()),
```

**L59**
```typescript
    messageFlagsAdd: vi.fn(() => Promise.resolve(null)),
```

**L60**
```typescript
    idle: vi.fn(() => Promise.resolve(null)),
```

**L61**
```typescript
  } as IImapClient;
```

**L62**
```typescript
}
```

**L63**
```typescript

```

**L64**
```typescript
function emptyAsyncIterable(): AsyncIterable<never> {
```

**L65**
```typescript
  return {
```

**L66**
```typescript
    [Symbol.asyncIterator]() {
```

**L67**
```typescript
      return {
```

**L68**
```typescript
        next: () => Promise.resolve({ done: true, value: undefined } as IteratorResult<never>),
```

**L69**
```typescript
      };
```

**L70**
```typescript
    },
```

**L71**
```typescript
  };
```

**L72**
```typescript
}
```

**L73**
```typescript

```

**L74**
```typescript
function asyncIterableFrom<T>(items: T[]): AsyncIterable<T> {
```

**L75**
```typescript
  return {
```

**L76**
```typescript
    [Symbol.asyncIterator]() {
```

**L77**
```typescript
      let i = 0;
```

**L78**
```typescript
      return {
```

**L79**
```typescript
        next: (): Promise<IteratorResult<T>> => {
```

**L80**
```typescript
          if (i >= items.length) return Promise.resolve({ done: true, value: undefined as never });
```

**L81**
```typescript
          const value = items[i++] as T;
```

**L82**
```typescript
          return Promise.resolve({ done: false, value });
```

**L83**
```typescript
        },
```

**L84**
```typescript
      };
```

**L85**
```typescript
    },
```

**L86**
```typescript
  };
```

**L87**
```typescript
}
```

**L88**
```typescript

```

**L89**
```typescript
const orgId = 'org-1';
```

**L90**
```typescript

```

**L91**
```typescript
describe('MailCarrierClient.persistInbound', () => {
```

**L92**
```typescript
  let supabase: MockSupabase;
```

**L93**
```typescript
  let client: MailCarrierClient;
```

**L94**
```typescript
  let parser: ParserFn;
```

**L95**
```typescript

```

**L96**
```typescript
  beforeEach(() => {
```

**L97**
```typescript
    parser = vi.fn();
```

**L98**
```typescript
    supabase = buildSupabaseMock({
```

**L99**
```typescript
      // 1차: communications duplicate check → null (신규)
```

**L100**
```typescript
      'app.communications': {
```

**L101**
```typescript
        selectMaybeSingle: { data: null },
```

**L102**
```typescript
        insertSingle: { data: { id: 'comm-new-1' } },
```

**L103**
```typescript
      },
```

**L104**
```typescript
      'app.contacts': {
```

**L105**
```typescript
        selectMaybeSingle: { data: null },
```

**L106**
```typescript
      },
```

**L107**
```typescript
      'app.attachments': {
```

**L108**
```typescript
        insertSingle: { data: { id: 'att-1' } },
```

**L109**
```typescript
      },
```

**L110**
```typescript
    });
```

**L111**
```typescript
    client = new MailCarrierClient(supabase as never, orgId, {
```

**L112**
```typescript
      imapClient: makeFakeImap(),
```

**L113**
```typescript
      parser,
```

**L114**
```typescript
    });
```

**L115**
```typescript
  });
```

**L116**
```typescript

```

**L117**
```typescript
  it('inserts a new communication with masked body', async () => {
```

**L118**
```typescript
    const parsed = makeParsedMail({
```

**L119**
```typescript
      messageId: '<new@ex.com>',
```

**L120**
```typescript
      subject: 'My phone is 010-1234-5678',
```

**L121**
```typescript
      from: {
```

**L122**
```typescript
        text: '',
```

**L123**
```typescript
        html: '',
```

**L124**
```typescript
        value: [{ name: 'Alice', address: 'alice@acmecorp.com' }],
```

**L125**
```typescript
      },
```

**L126**
```typescript
      to: { text: '', html: '', value: [{ name: '', address: 'me@org.com' }] },
```

**L127**
```typescript
      text: '내 번호는 010-1234-5678 입니다.',
```

**L128**
```typescript
      date: new Date('2026-02-01T09:00:00Z'),
```

**L129**
```typescript
    });
```

**L130**
```typescript

```

**L131**
```typescript
    const event = await client.persistInbound(parsed);
```

**L132**
```typescript

```

**L133**
```typescript
    expect(event).not.toBeNull();
```

**L134**
```typescript
    expect(event?.communicationId).toBe('comm-new-1');
```

**L135**
```typescript
    expect(event?.messageId).toBe('<new@ex.com>');
```

**L136**
```typescript
    expect(event?.bodyText).toContain('{{PII_001}}'); // 전화번호 마스킹됨
```

**L137**
```typescript
    expect(event?.bodyText).not.toContain('010-1234-5678');
```

**L138**
```typescript
    expect(event?.piiCategories).toContain('phone_kr');
```

**L139**
```typescript

```

**L140**
```typescript
    // INSERT 호출 검증
```

**L141**
```typescript
    const insertCalls = supabase.__calls.insert.filter(
```

**L142**
```typescript
      (c) => c.schema === 'app' && c.table === 'communications',
```

**L143**
```typescript
    );
```

**L144**
```typescript
    expect(insertCalls).toHaveLength(1);
```

**L145**
```typescript
    const payload = insertCalls[0]?.payload as Record<string, unknown>;
```

**L146**
```typescript
    expect(payload.message_id).toBe('<new@ex.com>');
```

**L147**
```typescript
    expect(payload.direction).toBe('inbound');
```

**L148**
```typescript
    expect(payload.channel).toBe('email');
```

**L149**
```typescript
    expect(payload.from_address).toBe('alice@acmecorp.com');
```

**L150**
```typescript
    expect((payload.body_plain as string)).not.toContain('010-1234-5678');
```

**L151**
```typescript
    expect((payload.external_data as Record<string, unknown>).pii_masked).toBe(true);
```

**L152**
```typescript
  });
```

**L153**
```typescript

```

**L154**
```typescript
  it('returns null when Message-ID already exists (idempotency)', async () => {
```

**L155**
```typescript
    const sbDup = buildSupabaseMock({
```

**L156**
```typescript
      'app.communications': {
```

**L157**
```typescript
        selectMaybeSingle: {
```

**L158**
```typescript
          data: { id: 'existing-comm', organization_id: orgId, thread_id: 'thread-1' },
```

**L159**
```typescript
        },
```

**L160**
```typescript
      },
```

**L161**
```typescript
    });
```

**L162**
```typescript
    const dupClient = new MailCarrierClient(sbDup as never, orgId, {
```

**L163**
```typescript
      imapClient: makeFakeImap(),
```

**L164**
```typescript
      parser: vi.fn(),
```

**L165**
```typescript
    });
```

**L166**
```typescript
    const parsed = makeParsedMail({
```

**L167**
```typescript
      messageId: '<dup@ex.com>',
```

**L168**
```typescript
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
```

**L169**
```typescript
      to: { text: '', html: '', value: [{ name: '', address: 'me@org.com' }] },
```

**L170**
```typescript
    });
```

**L171**
```typescript

```

**L172**
```typescript
    const event = await dupClient.persistInbound(parsed);
```

**L173**
```typescript

```

**L174**
```typescript
    expect(event).toBeNull();
```

**L175**
```typescript
    // INSERT는 호출되지 않았어야 함
```

**L176**
```typescript
    const inserts = sbDup.__calls.insert.filter(
```

**L177**
```typescript
      (c) => c.table === 'communications',
```

**L178**
```typescript
    );
```

**L179**
```typescript
    expect(inserts).toHaveLength(0);
```

**L180**
```typescript
  });
```

**L181**
```typescript

```

**L182**
```typescript
  it('uses thread match engagement_id when found', async () => {
```

**L183**
```typescript
    const sb = buildSupabaseMock({
```

**L184**
```typescript
      'app.communications': {
```

**L185**
```typescript
        selectMaybeSingle: {
```

**L186**
```typescript
          data: { thread_id: 'matched-thread', engagement_id: 'matched-eng' },
```

**L187**
```typescript
        },
```

**L188**
```typescript
        insertSingle: { data: { id: 'comm-thread-1' } },
```

**L189**
```typescript
      },
```

**L190**
```typescript
    });
```

**L191**
```typescript
    // duplicate check가 첫 호출로 null을 반환해야 하므로,
```

**L192**
```typescript
    // chain을 단순하게 만들어 첫 maybeSingle은 null, 다음은 thread match.
```

**L193**
```typescript
    let mbCalls = 0;
```

**L194**
```typescript
    const origSchema = sb.schema;
```

**L195**
```typescript
    sb.schema = vi.fn((schemaName: string) => ({
```

**L196**
```typescript
      from: (table: string) => {
```

**L197**
```typescript
        const orig = origSchema(schemaName).from(table) as Record<string, unknown>;
```

**L198**
```typescript
        const b: Record<string, unknown> = { ...orig };
```

**L199**
```typescript
        b.maybeSingle = vi.fn(() => {
```

**L200**
```typescript
          mbCalls += 1;
```

**L201**
```typescript
          if (table === 'communications' && mbCalls === 1) {
```

**L202**
```typescript
            return Promise.resolve({ data: null, error: null });
```

**L203**
```typescript
          }
```

**L204**
```typescript
          if (table === 'communications' && mbCalls === 2) {
```

**L205**
```typescript
            return Promise.resolve({
```

**L206**
```typescript
              data: { thread_id: 'matched-thread', engagement_id: 'matched-eng' },
```

**L207**
```typescript
              error: null,
```

**L208**
```typescript
            });
```

**L209**
```typescript
          }
```

**L210**
```typescript
          // contacts 매칭 — null
```

**L211**
```typescript
          return Promise.resolve({ data: null, error: null });
```

**L212**
```typescript
        });
```

**L213**
```typescript
        b.single = vi.fn(() => Promise.resolve({ data: { id: 'comm-thread-1' }, error: null }));
```

**L214**
```typescript
        for (const m of ['select', 'eq', 'is', 'like', 'order', 'limit', 'insert']) {
```

**L215**
```typescript
          b[m] = vi.fn(() => b);
```

**L216**
```typescript
        }
```

**L217**
```typescript
        b.update = vi.fn(() => Promise.resolve({ error: null }));
```

**L218**
```typescript
        return b;
```

**L219**
```typescript
      },
```

**L220**
```typescript
    })) as unknown as typeof sb.schema;
```

**L221**
```typescript

```

**L222**
```typescript
    const c = new MailCarrierClient(sb as never, orgId, {
```

**L223**
```typescript
      imapClient: makeFakeImap(),
```

**L224**
```typescript
      parser: vi.fn(),
```

**L225**
```typescript
    });
```

**L226**
```typescript
    const parsed = makeParsedMail({
```

**L227**
```typescript
      messageId: '<reply-to-thread@ex.com>',
```

**L228**
```typescript
      from: { text: '', html: '', value: [{ name: '', address: 'x@x.com' }] },
```

**L229**
```typescript
      to: { text: '', html: '', value: [] },
```

**L230**
```typescript
      headerEntries: [['x-urm-communication-id', 'prev-comm']],
```

**L231**
```typescript
    });
```

**L232**
```typescript

```

**L233**
```typescript
    const event = await c.persistInbound(parsed);
```

**L234**
```typescript
    expect(event?.threadId).toBe('matched-thread');
```

**L235**
```typescript
  });
```

**L236**
```typescript

```

**L237**
```typescript
  it('persists attachments to Storage and attachments table', async () => {
```

**L238**
```typescript
    const parsed = makeParsedMail({
```

**L239**
```typescript
      messageId: '<att@ex.com>',
```

**L240**
```typescript
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
```

**L241**
```typescript
      to: { text: '', html: '', value: [] },
```

**L242**
```typescript
      attachments: [
```

**L243**
```typescript
        {
```

**L244**
```typescript
          filename: 'invoice.pdf',
```

**L245**
```typescript
          contentType: 'application/pdf',
```

**L246**
```typescript
          content: Buffer.from('fake pdf bytes'),
```

**L247**
```typescript
          contentDisposition: 'attachment',
```

**L248**
```typescript
          size: 14,
```

**L249**
```typescript
        } as never,
```

**L250**
```typescript
      ],
```

**L251**
```typescript
    });
```

**L252**
```typescript

```

**L253**
```typescript
    await client.persistInbound(parsed);
```

**L254**
```typescript

```

**L255**
```typescript
    // Storage upload 호출 검증
```

**L256**
```typescript
    const storageFromCalls = (supabase.storage.from as ReturnType<typeof vi.fn>).mock.calls;
```

**L257**
```typescript
    expect(storageFromCalls.length).toBeGreaterThan(0);
```

**L258**
```typescript

```

**L259**
```typescript
    // attachments INSERT 검증
```

**L260**
```typescript
    const attInserts = supabase.__calls.insert.filter(
```

**L261**
```typescript
      (c) => c.schema === 'app' && c.table === 'attachments',
```

**L262**
```typescript
    );
```

**L263**
```typescript
    expect(attInserts).toHaveLength(1);
```

**L264**
```typescript
    const payload = attInserts[0]?.payload as Record<string, unknown>;
```

**L265**
```typescript
    expect(payload.entity_type).toBe('communication');
```

**L266**
```typescript
    expect(payload.entity_id).toBe('comm-new-1');
```

**L267**
```typescript
    expect(payload.file_name).toBe('invoice.pdf');
```

**L268**
```typescript
    expect(payload.mime_type).toBe('application/pdf');
```

**L269**
```typescript
    expect(payload.file_size_bytes).toBe(14);
```

**L270**
```typescript
    expect(payload.content_hash_sha256).toMatch(/^[a-f0-9]{64}$/);
```

**L271**
```typescript
  });
```

**L272**
```typescript

```

**L273**
```typescript
  it('skips attachments larger than 25MB', async () => {
```

**L274**
```typescript
    const huge = Buffer.alloc(30 * 1024 * 1024);
```

**L275**
```typescript
    const parsed = makeParsedMail({
```

**L276**
```typescript
      messageId: '<huge@ex.com>',
```

**L277**
```typescript
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
```

**L278**
```typescript
      to: { text: '', html: '', value: [] },
```

**L279**
```typescript
      attachments: [
```

**L280**
```typescript
        {
```

**L281**
```typescript
          filename: 'huge.bin',
```

**L282**
```typescript
          contentType: 'application/octet-stream',
```

**L283**
```typescript
          content: huge,
```

**L284**
```typescript
          size: huge.length,
```

**L285**
```typescript
        } as never,
```

**L286**
```typescript
      ],
```

**L287**
```typescript
    });
```

**L288**
```typescript
    await client.persistInbound(parsed);
```

**L289**
```typescript
    // attachments INSERT는 일어나지 않아야 함
```

**L290**
```typescript
    const attInserts = supabase.__calls.insert.filter(
```

**L291**
```typescript
      (c) => c.table === 'attachments',
```

**L292**
```typescript
    );
```

**L293**
```typescript
    expect(attInserts).toHaveLength(0);
```

**L294**
```typescript
  });
```

**L295**
```typescript
});
```

**L296**
```typescript

```

**L297**
```typescript
describe('MailCarrierClient.fetchAndProcessNew', () => {
```

**L298**
```typescript
  it('invokes onMessage callback and marks Seen', async () => {
```

**L299**
```typescript
    const supabase = buildSupabaseMock({
```

**L300**
```typescript
      'app.communications': {
```

**L301**
```typescript
        selectMaybeSingle: { data: null },
```

**L302**
```typescript
        insertSingle: { data: { id: 'comm-fetch-1' } },
```

**L303**
```typescript
      },
```

**L304**
```typescript
      'app.contacts': { selectMaybeSingle: { data: null } },
```

**L305**
```typescript
    });
```

**L306**
```typescript

```

**L307**
```typescript
    const fakeRaw = Buffer.from('raw rfc822');
```

**L308**
```typescript
    const parsed = makeParsedMail({
```

**L309**
```typescript
      messageId: '<fetch@ex.com>',
```

**L310**
```typescript
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
```

**L311**
```typescript
      to: { text: '', html: '', value: [] },
```

**L312**
```typescript
      text: 'hello',
```

**L313**
```typescript
    });
```

**L314**
```typescript

```

**L315**
```typescript
    const imap = makeFakeImap();
```

**L316**
```typescript
    (imap.fetch as ReturnType<typeof vi.fn>).mockReturnValue(
```

**L317**
```typescript
      asyncIterableFrom([
```

**L318**
```typescript
        { source: fakeRaw, uid: 42, envelope: {} } as never,
```

**L319**
```typescript
      ]),
```

**L320**
```typescript
    );
```

**L321**
```typescript

```

**L322**
```typescript
    const parser: ParserFn = vi.fn(() => Promise.resolve(parsed));
```

**L323**
```typescript
    const onMessage = vi.fn<(event: InboundMessageEvent) => Promise<void>>(() => Promise.resolve());
```

**L324**
```typescript

```

**L325**
```typescript
    const client = new MailCarrierClient(supabase as never, orgId, {
```

**L326**
```typescript
      imapClient: imap,
```

**L327**
```typescript
      parser,
```

**L328**
```typescript
    });
```

**L329**
```typescript

```

**L330**
```typescript
    await client.fetchAndProcessNew(onMessage);
```

**L331**
```typescript

```

**L332**
```typescript
    expect(parser).toHaveBeenCalledWith(fakeRaw);
```

**L333**
```typescript
    expect(onMessage).toHaveBeenCalledTimes(1);
```

**L334**
```typescript
    const passed = onMessage.mock.calls[0]?.[0] as unknown as { messageId: string };
```

**L335**
```typescript
    expect(passed?.messageId).toBe('<fetch@ex.com>');
```

**L336**
```typescript
    expect(imap.messageFlagsAdd).toHaveBeenCalledWith(42, ['\\Seen']);
```

**L337**
```typescript
  });
```

**L338**
```typescript

```

**L339**
```typescript
  it('continues processing remaining messages when one fails', async () => {
```

**L340**
```typescript
    const supabase = buildSupabaseMock({
```

**L341**
```typescript
      'app.communications': {
```

**L342**
```typescript
        selectMaybeSingle: { data: null },
```

**L343**
```typescript
        insertSingle: { data: { id: 'comm-second' } },
```

**L344**
```typescript
      },
```

**L345**
```typescript
      'app.contacts': { selectMaybeSingle: { data: null } },
```

**L346**
```typescript
    });
```

**L347**
```typescript

```

**L348**
```typescript
    const imap = makeFakeImap();
```

**L349**
```typescript
    (imap.fetch as ReturnType<typeof vi.fn>).mockReturnValue(
```

**L350**
```typescript
      asyncIterableFrom([
```

**L351**
```typescript
        { source: Buffer.from('msg1'), uid: 1 } as never,
```

**L352**
```typescript
        { source: Buffer.from('msg2'), uid: 2 } as never,
```

**L353**
```typescript
      ]),
```

**L354**
```typescript
    );
```

**L355**
```typescript
    const parser: ParserFn = vi
```

**L356**
```typescript
      .fn()
```

**L357**
```typescript
      .mockRejectedValueOnce(new Error('parse fail'))
```

**L358**
```typescript
      .mockResolvedValueOnce(
```

**L359**
```typescript
        makeParsedMail({
```

**L360**
```typescript
          messageId: '<ok@x>',
```

**L361**
```typescript
          from: { text: '', html: '', value: [{ name: '', address: 'a@b' }] },
```

**L362**
```typescript
          to: { text: '', html: '', value: [] },
```

**L363**
```typescript
        }),
```

**L364**
```typescript
      );
```

**L365**
```typescript
    const onMessage = vi.fn<(event: InboundMessageEvent) => Promise<void>>(() => Promise.resolve());
```

**L366**
```typescript

```

**L367**
```typescript
    const client = new MailCarrierClient(supabase as never, orgId, {
```

**L368**
```typescript
      imapClient: imap,
```

**L369**
```typescript
      parser,
```

**L370**
```typescript
    });
```

**L371**
```typescript

```

**L372**
```typescript
    await client.fetchAndProcessNew(onMessage);
```

**L373**
```typescript

```

**L374**
```typescript
    // 두 번째 메시지는 정상 처리됨
```

**L375**
```typescript
    expect(onMessage).toHaveBeenCalledTimes(1);
```

**L376**
```typescript
    expect(imap.messageFlagsAdd).toHaveBeenCalledWith(2, ['\\Seen']);
```

**L377**
```typescript
  });
```

**L378**
```typescript
});
```

**L379**
```typescript

```

**L380**
```typescript
describe('sanitizeFilename', () => {
```

**L381**
```typescript
  it('replaces path separators with underscore', () => {
```

**L382**
```typescript
    expect(sanitizeFilename('a/b/c.pdf')).toBe('a_b_c.pdf');
```

**L383**
```typescript
    expect(sanitizeFilename('a\\b\\c.pdf')).toBe('a_b_c.pdf');
```

**L384**
```typescript
  });
```

**L385**
```typescript
  it('strips leading/trailing whitespace and dots', () => {
```

**L386**
```typescript
    expect(sanitizeFilename('  ..invoice.pdf..  ')).toBe('invoice.pdf');
```

**L387**
```typescript
  });
```

**L388**
```typescript
  it('preserves Korean and Japanese characters', () => {
```

**L389**
```typescript
    expect(sanitizeFilename('계약서.pdf')).toBe('계약서.pdf');
```

**L390**
```typescript
    expect(sanitizeFilename('請求書.pdf')).toBe('請求書.pdf');
```

**L391**
```typescript
  });
```

**L392**
```typescript
  it('truncates very long names while preserving extension', () => {
```

**L393**
```typescript
    const long = 'x'.repeat(300) + '.pdf';
```

**L394**
```typescript
    const out = sanitizeFilename(long);
```

**L395**
```typescript
    expect(out.length).toBeLessThanOrEqual(180);
```

**L396**
```typescript
    expect(out.endsWith('.pdf')).toBe(true);
```

**L397**
```typescript
  });
```

**L398**
```typescript
  it('falls back when name is empty after sanitization', () => {
```

**L399**
```typescript
    const out = sanitizeFilename('   ...   ');
```

**L400**
```typescript
    expect(out).toMatch(/^attachment-\d+$/);
```

**L401**
```typescript
  });
```

**L402**
```typescript
});
```

### `src\__tests__\email\processor.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/email/processor.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * processor.ts의 5단계 파이프라인 검증.
```

**L5**
```typescript
 * ClaudeClient는 인터페이스로 추상화되지 않았지만 fake instance를 주입할 수 있도록
```

**L6**
```typescript
 * options.claudeClient를 받는다. 본 테스트에서는 ClaudeClient의 complete()만
```

**L7**
```typescript
 * stub해서 분류기·회신가 응답을 통제한다.
```

**L8**
```typescript
 *
```

**L9**
```typescript
 * 시나리오:
```

**L10**
```typescript
 *   1. 정상 흐름 — 표준 카테고리, 정상 회신, ai.drafts INSERT
```

**L11**
```typescript
 *   2. 비표준 카테고리 → 'other'로 강제 + requires_human=true
```

**L12**
```typescript
 *   3. 회신가 출력 검증 실패 → fallback reply + requires_human=true
```

**L13**
```typescript
 *   4. 회신 본문에 미복원 PII 토큰 → requires_human=true
```

**L14**
```typescript
 *   5. communications에 이미 ai_draft_id 있음 + force=false → 에러
```

**L15**
```typescript
 *   6. ClaudeBudgetExceededError → ai_processing_status='failed'
```

**L16**
```typescript
 */
```

**L17**
```typescript

```

**L18**
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

**L19**
```typescript
import { processInbound, ProcessorError } from '../../lib/email/processor';
```

**L20**
```typescript
import { ClaudeBudgetExceededError } from '../../lib/ai/claude-client';
```

**L21**
```typescript
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
```

**L22**
```typescript
import type {
```

**L23**
```typescript
  ClaudeCompleteInput,
```

**L24**
```typescript
  ClaudeCompleteOutput,
```

**L25**
```typescript
} from '../../types/ai';
```

**L26**
```typescript

```

**L27**
```typescript
// auto-send-gate가 env.AI_AUTO_SEND_ENABLED=false에서 항상 차단하므로
```

**L28**
```typescript
// processor 테스트에서는 차단되더라도 ai.drafts가 정상 생성되는지만 확인.
```

**L29**
```typescript

```

**L30**
```typescript
const orgId = 'org-1';
```

**L31**
```typescript
const commId = 'comm-1';
```

**L32**
```typescript

```

**L33**
```typescript
interface MockClaudeOptions {
```

**L34**
```typescript
  classifierResponse?: object | null;
```

**L35**
```typescript
  drafterResponse?: object | null;
```

**L36**
```typescript
  classifierThrows?: Error;
```

**L37**
```typescript
  drafterThrows?: Error;
```

**L38**
```typescript
}
```

**L39**
```typescript

```

**L40**
```typescript
function buildMockClaude(opts: MockClaudeOptions): {
```

**L41**
```typescript
  complete: ReturnType<typeof vi.fn>;
```

**L42**
```typescript
} {
```

**L43**
```typescript
  const complete = vi.fn(async (input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> => {
```

**L44**
```typescript
    const isClassifier = input.agentRole === 'classifier';
```

**L45**
```typescript
    if (isClassifier && opts.classifierThrows) throw opts.classifierThrows;
```

**L46**
```typescript
    if (!isClassifier && opts.drafterThrows) throw opts.drafterThrows;
```

**L47**
```typescript

```

**L48**
```typescript
    const parsed = isClassifier ? opts.classifierResponse : opts.drafterResponse;
```

**L49**
```typescript
    return {
```

**L50**
```typescript
      content: parsed === null ? '' : JSON.stringify(parsed),
```

**L51**
```typescript
      parsedJson: parsed ?? undefined,
```

**L52**
```typescript
      runId: isClassifier ? 'run-classifier-1' : 'run-drafter-1',
```

**L53**
```typescript
      agentId: isClassifier ? 'agent-classifier-1' : 'agent-drafter-1',
```

**L54**
```typescript
      model: isClassifier
```

**L55**
```typescript
        ? 'claude-haiku-4-5-20251001'
```

**L56**
```typescript
        : 'claude-opus-4-7',
```

**L57**
```typescript
      latencyMs: 1234,
```

**L58**
```typescript
      tokensIn: 500,
```

**L59**
```typescript
      tokensOut: 200,
```

**L60**
```typescript
      costUsd: 0.001,
```

**L61**
```typescript
    };
```

**L62**
```typescript
  });
```

**L63**
```typescript
  return { complete };
```

**L64**
```typescript
}
```

**L65**
```typescript

```

**L66**
```typescript
const validClassification = {
```

**L67**
```typescript
  category: 'information_request',
```

**L68**
```typescript
  urgency: 'medium',
```

**L69**
```typescript
  sentiment: 'neutral',
```

**L70**
```typescript
  requiresHuman: false,
```

**L71**
```typescript
  confidence: 0.92,
```

**L72**
```typescript
  rationale: 'asking about pricing',
```

**L73**
```typescript
  riskFlags: [],
```

**L74**
```typescript
  detectedLanguage: 'ko',
```

**L75**
```typescript
};
```

**L76**
```typescript

```

**L77**
```typescript
const validReply = {
```

**L78**
```typescript
  subject: 'Re: 가격 문의',
```

**L79**
```typescript
  bodyPlain: '가격은 KG당 50달러입니다.',
```

**L80**
```typescript
  bodyHtml: '<p>가격은 KG당 50달러입니다.</p>',
```

**L81**
```typescript
  rationale: 'Direct pricing answer',
```

**L82**
```typescript
  riskFlags: [],
```

**L83**
```typescript
  requiresHumanApproval: false,
```

**L84**
```typescript
  language: 'ko',
```

**L85**
```typescript
};
```

**L86**
```typescript

```

**L87**
```typescript
function buildBaseSupabase(): MockSupabase {
```

**L88**
```typescript
  return buildSupabaseMock({
```

**L89**
```typescript
    'app.communications': {
```

**L90**
```typescript
      selectMaybeSingle: {
```

**L91**
```typescript
        data: {
```

**L92**
```typescript
          id: commId,
```

**L93**
```typescript
          organization_id: orgId,
```

**L94**
```typescript
          party_id: 'party-1',
```

**L95**
```typescript
          contact_id: 'contact-1',
```

**L96**
```typescript
          engagement_id: 'eng-1',
```

**L97**
```typescript
          module: 'paper_mill',
```

**L98**
```typescript
          from_address: 'buyer@acme.com',
```

**L99**
```typescript
          body_plain: '가격이 어떻게 되나요?',
```

**L100**
```typescript
          subject: '가격 문의',
```

**L101**
```typescript
          language_detected: 'ko',
```

**L102**
```typescript
          ai_draft_id: null,
```

**L103**
```typescript
          ai_processing_status: 'pending',
```

**L104**
```typescript
        },
```

**L105**
```typescript
      },
```

**L106**
```typescript
      updateResult: { error: null },
```

**L107**
```typescript
    },
```

**L108**
```typescript
    'app.contacts': {
```

**L109**
```typescript
      selectMaybeSingle: { data: { preferred_language: 'ko' } },
```

**L110**
```typescript
    },
```

**L111**
```typescript
    'app.parties': {
```

**L112**
```typescript
      selectMaybeSingle: { data: { country_code: 'KR' } },
```

**L113**
```typescript
    },
```

**L114**
```typescript
    'ai.drafts': {
```

**L115**
```typescript
      insertSingle: { data: { id: 'draft-1' } },
```

**L116**
```typescript
    },
```

**L117**
```typescript
    'ai.auto_send_rules': {
```

**L118**
```typescript
      selectMaybeSingle: { data: null }, // no_rule_defined → blocked
```

**L119**
```typescript
    },
```

**L120**
```typescript
    'app.organizations': {
```

**L121**
```typescript
      selectMaybeSingle: { data: { settings: {} } },
```

**L122**
```typescript
    },
```

**L123**
```typescript
  });
```

**L124**
```typescript
}
```

**L125**
```typescript

```

**L126**
```typescript
describe('processInbound — happy path', () => {
```

**L127**
```typescript
  let supabase: MockSupabase;
```

**L128**
```typescript

```

**L129**
```typescript
  beforeEach(() => {
```

**L130**
```typescript
    supabase = buildBaseSupabase();
```

**L131**
```typescript
  });
```

**L132**
```typescript

```

**L133**
```typescript
  it('runs classifier, drafter, gate, draft INSERT, communications update', async () => {
```

**L134**
```typescript
    const claude = buildMockClaude({
```

**L135**
```typescript
      classifierResponse: validClassification,
```

**L136**
```typescript
      drafterResponse: validReply,
```

**L137**
```typescript
    });
```

**L138**
```typescript

```

**L139**
```typescript
    const result = await processInbound(supabase as never, orgId, commId, {
```

**L140**
```typescript
      claudeClient: claude as never,
```

**L141**
```typescript
    });
```

**L142**
```typescript

```

**L143**
```typescript
    expect(result.communicationId).toBe(commId);
```

**L144**
```typescript
    expect(result.draftId).toBe('draft-1');
```

**L145**
```typescript
    expect(result.classifierRunId).toBe('run-classifier-1');
```

**L146**
```typescript
    expect(result.drafterRunId).toBe('run-drafter-1');
```

**L147**
```typescript
    expect(result.classification.category).toBe('information_request');
```

**L148**
```typescript
    expect(result.reply.subject).toBe('Re: 가격 문의');
```

**L149**
```typescript
    // env.AI_AUTO_SEND_ENABLED=false (test setup) → 차단
```

**L150**
```typescript
    expect(result.autoSendAllowed).toBe(false);
```

**L151**
```typescript
    expect(result.autoSendBlockedReasons).toContain('global_disabled');
```

**L152**
```typescript

```

**L153**
```typescript
    // claude는 정확히 2번 호출 (classifier + drafter)
```

**L154**
```typescript
    expect(claude.complete).toHaveBeenCalledTimes(2);
```

**L155**
```typescript
    expect(claude.complete.mock.calls[0]?.[0]?.agentRole).toBe('classifier');
```

**L156**
```typescript
    expect(claude.complete.mock.calls[1]?.[0]?.agentRole).toBe('reply_drafter');
```

**L157**
```typescript

```

**L158**
```typescript
    // ai.drafts INSERT 검증
```

**L159**
```typescript
    const draftInserts = supabase.__calls.insert.filter(
```

**L160**
```typescript
      (c) => c.schema === 'ai' && c.table === 'drafts',
```

**L161**
```typescript
    );
```

**L162**
```typescript
    expect(draftInserts).toHaveLength(1);
```

**L163**
```typescript
    const payload = draftInserts[0]?.payload as Record<string, unknown>;
```

**L164**
```typescript
    expect(payload.inbound_communication_id).toBe(commId);
```

**L165**
```typescript
    expect(payload.agent_id).toBe('agent-drafter-1');
```

**L166**
```typescript
    expect(payload.classification_category).toBe('information_request');
```

**L167**
```typescript
    expect(payload.confidence_score).toBe(0.92);
```

**L168**
```typescript
    expect(payload.subject).toBe('Re: 가격 문의');
```

**L169**
```typescript
    expect(payload.classifier_run_id).toBe('run-classifier-1');
```

**L170**
```typescript
    expect(payload.drafter_run_id).toBe('run-drafter-1');
```

**L171**
```typescript
    expect(payload.ai_generated).toBe(true);
```

**L172**
```typescript
    expect(payload.status).toBe('pending_review');
```

**L173**
```typescript
    expect(payload.requires_human_approval).toBe(true); // 게이트 차단되었으므로
```

**L174**
```typescript
    expect(payload.auto_send_eligible).toBe(false);
```

**L175**
```typescript
    expect(payload.language).toBe('ko');
```

**L176**
```typescript
    expect(typeof payload.expires_at).toBe('string');
```

**L177**
```typescript

```

**L178**
```typescript
    // communications UPDATE 검증 (마지막 호출은 ai_draft_id 갱신)
```

**L179**
```typescript
    const updates = supabase.__calls.update.filter(
```

**L180**
```typescript
      (c) => c.schema === 'app' && c.table === 'communications',
```

**L181**
```typescript
    );
```

**L182**
```typescript
    expect(updates.length).toBeGreaterThanOrEqual(2); // processing → completed
```

**L183**
```typescript
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
```

**L184**
```typescript
    expect(lastUpdate.ai_draft_id).toBe('draft-1');
```

**L185**
```typescript
    expect((lastUpdate.ai_classification as Record<string, unknown>).category).toBe(
```

**L186**
```typescript
      'information_request',
```

**L187**
```typescript
    );
```

**L188**
```typescript
  });
```

**L189**
```typescript
});
```

**L190**
```typescript

```

**L191**
```typescript
describe('processInbound — non-standard category enforcement', () => {
```

**L192**
```typescript
  it('forces invalid category to "other" with requires_human=true', async () => {
```

**L193**
```typescript
    const supabase = buildBaseSupabase();
```

**L194**
```typescript
    const claude = buildMockClaude({
```

**L195**
```typescript
      classifierResponse: {
```

**L196**
```typescript
        ...validClassification,
```

**L197**
```typescript
        category: 'material_request', // 비표준!
```

**L198**
```typescript
      },
```

**L199**
```typescript
      drafterResponse: validReply,
```

**L200**
```typescript
    });
```

**L201**
```typescript

```

**L202**
```typescript
    const result = await processInbound(supabase as never, orgId, commId, {
```

**L203**
```typescript
      claudeClient: claude as never,
```

**L204**
```typescript
    });
```

**L205**
```typescript

```

**L206**
```typescript
    expect(result.classification.category).toBe('other');
```

**L207**
```typescript
    expect(result.classification.requiresHuman).toBe(true);
```

**L208**
```typescript
    expect(result.classification.confidence).toBeLessThanOrEqual(0.5);
```

**L209**
```typescript

```

**L210**
```typescript
    const draftInserts = supabase.__calls.insert.filter(
```

**L211**
```typescript
      (c) => c.schema === 'ai' && c.table === 'drafts',
```

**L212**
```typescript
    );
```

**L213**
```typescript
    const payload = draftInserts[0]?.payload as Record<string, unknown>;
```

**L214**
```typescript
    expect(payload.classification_category).toBe('other');
```

**L215**
```typescript
    expect(payload.requires_human_approval).toBe(true);
```

**L216**
```typescript
  });
```

**L217**
```typescript

```

**L218**
```typescript
  it('handles classifier returning malformed JSON', async () => {
```

**L219**
```typescript
    const supabase = buildBaseSupabase();
```

**L220**
```typescript
    const claude = buildMockClaude({
```

**L221**
```typescript
      classifierResponse: null, // parsedJson undefined
```

**L222**
```typescript
      drafterResponse: validReply,
```

**L223**
```typescript
    });
```

**L224**
```typescript

```

**L225**
```typescript
    const result = await processInbound(supabase as never, orgId, commId, {
```

**L226**
```typescript
      claudeClient: claude as never,
```

**L227**
```typescript
    });
```

**L228**
```typescript

```

**L229**
```typescript
    expect(result.classification.category).toBe('other');
```

**L230**
```typescript
    expect(result.classification.requiresHuman).toBe(true);
```

**L231**
```typescript
    expect(result.classification.rationale).toContain('validation failed');
```

**L232**
```typescript
  });
```

**L233**
```typescript
});
```

**L234**
```typescript

```

**L235**
```typescript
describe('processInbound — drafter validation failure', () => {
```

**L236**
```typescript
  it('uses fallback reply with requires_human=true', async () => {
```

**L237**
```typescript
    const supabase = buildBaseSupabase();
```

**L238**
```typescript
    const claude = buildMockClaude({
```

**L239**
```typescript
      classifierResponse: validClassification,
```

**L240**
```typescript
      drafterResponse: { subject: '', bodyPlain: '' }, // invalid
```

**L241**
```typescript
    });
```

**L242**
```typescript

```

**L243**
```typescript
    const result = await processInbound(supabase as never, orgId, commId, {
```

**L244**
```typescript
      claudeClient: claude as never,
```

**L245**
```typescript
    });
```

**L246**
```typescript

```

**L247**
```typescript
    // fallback reply는 ko 언어
```

**L248**
```typescript
    expect(result.reply.language).toBe('ko');
```

**L249**
```typescript
    expect(result.reply.requiresHumanApproval).toBe(true);
```

**L250**
```typescript
    expect(result.reply.bodyPlain).toContain('검토');
```

**L251**
```typescript
    expect(result.reply.rationale).toContain('Fallback');
```

**L252**
```typescript
  });
```

**L253**
```typescript
});
```

**L254**
```typescript

```

**L255**
```typescript
describe('processInbound — unrestored PII tokens', () => {
```

**L256**
```typescript
  it('forces requires_human=true when reply still contains {{PII_xxx}}', async () => {
```

**L257**
```typescript
    const supabase = buildBaseSupabase();
```

**L258**
```typescript
    const claude = buildMockClaude({
```

**L259**
```typescript
      classifierResponse: validClassification,
```

**L260**
```typescript
      drafterResponse: {
```

**L261**
```typescript
        ...validReply,
```

**L262**
```typescript
        bodyPlain: '안녕하세요, {{PII_001}}로 연락드리겠습니다.', // 미복원!
```

**L263**
```typescript
      },
```

**L264**
```typescript
    });
```

**L265**
```typescript

```

**L266**
```typescript
    const result = await processInbound(supabase as never, orgId, commId, {
```

**L267**
```typescript
      claudeClient: claude as never,
```

**L268**
```typescript
    });
```

**L269**
```typescript

```

**L270**
```typescript
    expect(result.reply.requiresHumanApproval).toBe(true);
```

**L271**
```typescript
    expect(result.reply.rationale).toContain('unrestored PII');
```

**L272**
```typescript

```

**L273**
```typescript
    const draftInserts = supabase.__calls.insert.filter(
```

**L274**
```typescript
      (c) => c.schema === 'ai' && c.table === 'drafts',
```

**L275**
```typescript
    );
```

**L276**
```typescript
    const payload = draftInserts[0]?.payload as Record<string, unknown>;
```

**L277**
```typescript
    expect(payload.requires_human_approval).toBe(true);
```

**L278**
```typescript
  });
```

**L279**
```typescript
});
```

**L280**
```typescript

```

**L281**
```typescript
describe('processInbound — already processed', () => {
```

**L282**
```typescript
  it('throws when communication already has ai_draft_id and force=false', async () => {
```

**L283**
```typescript
    const supabase = buildSupabaseMock({
```

**L284**
```typescript
      'app.communications': {
```

**L285**
```typescript
        selectMaybeSingle: {
```

**L286**
```typescript
          data: {
```

**L287**
```typescript
            id: commId,
```

**L288**
```typescript
            organization_id: orgId,
```

**L289**
```typescript
            ai_draft_id: 'existing-draft',
```

**L290**
```typescript
            body_plain: 'x',
```

**L291**
```typescript
            subject: 'y',
```

**L292**
```typescript
          },
```

**L293**
```typescript
        },
```

**L294**
```typescript
      },
```

**L295**
```typescript
    });
```

**L296**
```typescript
    const claude = buildMockClaude({
```

**L297**
```typescript
      classifierResponse: validClassification,
```

**L298**
```typescript
      drafterResponse: validReply,
```

**L299**
```typescript
    });
```

**L300**
```typescript

```

**L301**
```typescript
    await expect(
```

**L302**
```typescript
      processInbound(supabase as never, orgId, commId, {
```

**L303**
```typescript
        claudeClient: claude as never,
```

**L304**
```typescript
      }),
```

**L305**
```typescript
    ).rejects.toThrow(/already has draft/);
```

**L306**
```typescript
  });
```

**L307**
```typescript

```

**L308**
```typescript
  it('processes again when force=true', async () => {
```

**L309**
```typescript
    const supabase = buildSupabaseMock({
```

**L310**
```typescript
      'app.communications': {
```

**L311**
```typescript
        selectMaybeSingle: {
```

**L312**
```typescript
          data: {
```

**L313**
```typescript
            id: commId,
```

**L314**
```typescript
            organization_id: orgId,
```

**L315**
```typescript
            party_id: null,
```

**L316**
```typescript
            engagement_id: null,
```

**L317**
```typescript
            ai_draft_id: 'existing-draft',
```

**L318**
```typescript
            body_plain: 'hello',
```

**L319**
```typescript
            subject: 'sub',
```

**L320**
```typescript
            module: 'paper_mill',
```

**L321**
```typescript
          },
```

**L322**
```typescript
        },
```

**L323**
```typescript
        updateResult: { error: null },
```

**L324**
```typescript
      },
```

**L325**
```typescript
      'ai.drafts': { insertSingle: { data: { id: 'draft-2' } } },
```

**L326**
```typescript
      'ai.auto_send_rules': { selectMaybeSingle: { data: null } },
```

**L327**
```typescript
    });
```

**L328**
```typescript
    const claude = buildMockClaude({
```

**L329**
```typescript
      classifierResponse: validClassification,
```

**L330**
```typescript
      drafterResponse: validReply,
```

**L331**
```typescript
    });
```

**L332**
```typescript

```

**L333**
```typescript
    const result = await processInbound(supabase as never, orgId, commId, {
```

**L334**
```typescript
      claudeClient: claude as never,
```

**L335**
```typescript
      force: true,
```

**L336**
```typescript
    });
```

**L337**
```typescript
    expect(result.draftId).toBe('draft-2');
```

**L338**
```typescript
  });
```

**L339**
```typescript
});
```

**L340**
```typescript

```

**L341**
```typescript
describe('processInbound — error handling', () => {
```

**L342**
```typescript
  it('marks failed when ClaudeBudgetExceededError thrown', async () => {
```

**L343**
```typescript
    const supabase = buildBaseSupabase();
```

**L344**
```typescript
    const claude = buildMockClaude({
```

**L345**
```typescript
      classifierThrows: new ClaudeBudgetExceededError(60, 50, 'daily'),
```

**L346**
```typescript
    });
```

**L347**
```typescript

```

**L348**
```typescript
    await expect(
```

**L349**
```typescript
      processInbound(supabase as never, orgId, commId, {
```

**L350**
```typescript
        claudeClient: claude as never,
```

**L351**
```typescript
      }),
```

**L352**
```typescript
    ).rejects.toBeInstanceOf(ClaudeBudgetExceededError);
```

**L353**
```typescript

```

**L354**
```typescript
    // communications가 failed 상태로 갱신되었는지
```

**L355**
```typescript
    const updates = supabase.__calls.update.filter(
```

**L356**
```typescript
      (c) => c.schema === 'app' && c.table === 'communications',
```

**L357**
```typescript
    );
```

**L358**
```typescript
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
```

**L359**
```typescript
    const ed = lastUpdate.external_data as Record<string, unknown>;
```

**L360**
```typescript
    expect(ed.ai_processing_status).toBe('failed');
```

**L361**
```typescript
    expect(ed.ai_processing_error_class).toBe('ClaudeBudgetExceededError');
```

**L362**
```typescript
    expect(ed.ai_processing_retryable).toBe(false);
```

**L363**
```typescript
  });
```

**L364**
```typescript

```

**L365**
```typescript
  it('throws ProcessorCommunicationNotFoundError for missing comm', async () => {
```

**L366**
```typescript
    const supabase = buildSupabaseMock({
```

**L367**
```typescript
      'app.communications': { selectMaybeSingle: { data: null } },
```

**L368**
```typescript
    });
```

**L369**
```typescript
    await expect(
```

**L370**
```typescript
      processInbound(supabase as never, orgId, 'missing'),
```

**L371**
```typescript
    ).rejects.toThrow(/Communication not found/);
```

**L372**
```typescript
  });
```

**L373**
```typescript

```

**L374**
```typescript
  it('wraps generic DB errors in ProcessorError', async () => {
```

**L375**
```typescript
    const supabase = buildSupabaseMock({
```

**L376**
```typescript
      'app.communications': {
```

**L377**
```typescript
        selectMaybeSingle: { data: null, error: { message: 'pg connection lost' } },
```

**L378**
```typescript
      },
```

**L379**
```typescript
    });
```

**L380**
```typescript
    await expect(
```

**L381**
```typescript
      processInbound(supabase as never, orgId, commId),
```

**L382**
```typescript
    ).rejects.toBeInstanceOf(ProcessorError);
```

**L383**
```typescript
  });
```

**L384**
```typescript
});
```

### `src\__tests__\email\quiet-hours.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/email/quiet-hours.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * Quiet hours 평가 함수 단위 테스트.
```

**L5**
```typescript
 * 모든 시각은 UTC 기준 Date 객체로 직접 생성하고, IANA 타임존 변환은
```

**L6**
```typescript
 * Intl.DateTimeFormat에 위임 — Node 22의 ICU 기본 데이터로 충분.
```

**L7**
```typescript
 */
```

**L8**
```typescript

```

**L9**
```typescript
import { describe, it, expect } from 'vitest';
```

**L10**
```typescript
import {
```

**L11**
```typescript
  evaluateQuietHours,
```

**L12**
```typescript
  getZonedParts,
```

**L13**
```typescript
  parseHHMM,
```

**L14**
```typescript
} from '../../lib/email/quiet-hours';
```

**L15**
```typescript

```

**L16**
```typescript
describe('parseHHMM', () => {
```

**L17**
```typescript
  it('parses valid HH:mm', () => {
```

**L18**
```typescript
    expect(parseHHMM('00:00')).toBe(0);
```

**L19**
```typescript
    expect(parseHHMM('09:30')).toBe(570);
```

**L20**
```typescript
    expect(parseHHMM('23:59')).toBe(23 * 60 + 59);
```

**L21**
```typescript
  });
```

**L22**
```typescript
  it('returns -1 on invalid format', () => {
```

**L23**
```typescript
    expect(parseHHMM('25:00')).toBe(-1);
```

**L24**
```typescript
    expect(parseHHMM('09:60')).toBe(-1);
```

**L25**
```typescript
    expect(parseHHMM('abc')).toBe(-1);
```

**L26**
```typescript
    expect(parseHHMM('')).toBe(-1);
```

**L27**
```typescript
  });
```

**L28**
```typescript
});
```

**L29**
```typescript

```

**L30**
```typescript
describe('getZonedParts', () => {
```

**L31**
```typescript
  it('converts UTC to Asia/Seoul (+9)', () => {
```

**L32**
```typescript
    // UTC 2026-03-15 00:00 → Seoul 2026-03-15 09:00
```

**L33**
```typescript
    const utc = new Date('2026-03-15T00:00:00Z');
```

**L34**
```typescript
    const parts = getZonedParts(utc, 'Asia/Seoul');
```

**L35**
```typescript
    expect(parts.year).toBe(2026);
```

**L36**
```typescript
    expect(parts.month).toBe(3);
```

**L37**
```typescript
    expect(parts.day).toBe(15);
```

**L38**
```typescript
    expect(parts.hour).toBe(9);
```

**L39**
```typescript
    expect(parts.minute).toBe(0);
```

**L40**
```typescript
  });
```

**L41**
```typescript

```

**L42**
```typescript
  it('throws RangeError on invalid timezone', () => {
```

**L43**
```typescript
    expect(() => getZonedParts(new Date(), 'Not/A_TZ')).toThrow();
```

**L44**
```typescript
  });
```

**L45**
```typescript
});
```

**L46**
```typescript

```

**L47**
```typescript
describe('evaluateQuietHours — basic time range', () => {
```

**L48**
```typescript
  const qh = {
```

**L49**
```typescript
    timezone: 'UTC',
```

**L50**
```typescript
    start: '22:00',
```

**L51**
```typescript
    end: '08:00',
```

**L52**
```typescript
    weekends_blocked: false,
```

**L53**
```typescript
  };
```

**L54**
```typescript

```

**L55**
```typescript
  it('blocks at 23:00 UTC (within 22:00-08:00)', () => {
```

**L56**
```typescript
    // 평일 (수요일) 23:00
```

**L57**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T23:00:00Z'));
```

**L58**
```typescript
    expect(v.blocked).toBe(true);
```

**L59**
```typescript
    expect(v.reason).toBe('within_quiet_hours');
```

**L60**
```typescript
  });
```

**L61**
```typescript

```

**L62**
```typescript
  it('blocks at 03:00 UTC (within 22:00-08:00 spanning midnight)', () => {
```

**L63**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T03:00:00Z'));
```

**L64**
```typescript
    expect(v.blocked).toBe(true);
```

**L65**
```typescript
  });
```

**L66**
```typescript

```

**L67**
```typescript
  it('allows at 12:00 UTC (outside quiet hours)', () => {
```

**L68**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T12:00:00Z'));
```

**L69**
```typescript
    expect(v.blocked).toBe(false);
```

**L70**
```typescript
  });
```

**L71**
```typescript

```

**L72**
```typescript
  it('allows exactly at end time (08:00 → 08:00 is allowed)', () => {
```

**L73**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T08:00:00Z'));
```

**L74**
```typescript
    expect(v.blocked).toBe(false);
```

**L75**
```typescript
  });
```

**L76**
```typescript
});
```

**L77**
```typescript

```

**L78**
```typescript
describe('evaluateQuietHours — non-spanning range', () => {
```

**L79**
```typescript
  const qh = {
```

**L80**
```typescript
    timezone: 'UTC',
```

**L81**
```typescript
    start: '12:00',
```

**L82**
```typescript
    end: '13:00',
```

**L83**
```typescript
    weekends_blocked: false,
```

**L84**
```typescript
  };
```

**L85**
```typescript

```

**L86**
```typescript
  it('blocks at 12:30 (within 12:00-13:00)', () => {
```

**L87**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T12:30:00Z'));
```

**L88**
```typescript
    expect(v.blocked).toBe(true);
```

**L89**
```typescript
  });
```

**L90**
```typescript

```

**L91**
```typescript
  it('allows at 13:00 (end is exclusive)', () => {
```

**L92**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T13:00:00Z'));
```

**L93**
```typescript
    expect(v.blocked).toBe(false);
```

**L94**
```typescript
  });
```

**L95**
```typescript
});
```

**L96**
```typescript

```

**L97**
```typescript
describe('evaluateQuietHours — weekend blocking', () => {
```

**L98**
```typescript
  const qh = {
```

**L99**
```typescript
    timezone: 'UTC',
```

**L100**
```typescript
    start: '22:00',
```

**L101**
```typescript
    end: '08:00',
```

**L102**
```typescript
    weekends_blocked: true,
```

**L103**
```typescript
  };
```

**L104**
```typescript

```

**L105**
```typescript
  it('blocks on Saturday at noon', () => {
```

**L106**
```typescript
    // 2026-03-07 is Saturday
```

**L107**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-07T12:00:00Z'));
```

**L108**
```typescript
    expect(v.blocked).toBe(true);
```

**L109**
```typescript
    expect(v.reason).toBe('weekend_blocked');
```

**L110**
```typescript
    expect(v.nextAllowedAt).toBeDefined();
```

**L111**
```typescript
  });
```

**L112**
```typescript

```

**L113**
```typescript
  it('blocks on Sunday at noon', () => {
```

**L114**
```typescript
    // 2026-03-08 is Sunday
```

**L115**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-08T12:00:00Z'));
```

**L116**
```typescript
    expect(v.blocked).toBe(true);
```

**L117**
```typescript
    expect(v.reason).toBe('weekend_blocked');
```

**L118**
```typescript
  });
```

**L119**
```typescript
});
```

**L120**
```typescript

```

**L121**
```typescript
describe('evaluateQuietHours — Asia/Seoul timezone', () => {
```

**L122**
```typescript
  const qh = {
```

**L123**
```typescript
    timezone: 'Asia/Seoul',
```

**L124**
```typescript
    start: '22:00',
```

**L125**
```typescript
    end: '08:00',
```

**L126**
```typescript
    weekends_blocked: false,
```

**L127**
```typescript
  };
```

**L128**
```typescript

```

**L129**
```typescript
  it('blocks at UTC 13:00 (= Seoul 22:00)', () => {
```

**L130**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T13:00:00Z'));
```

**L131**
```typescript
    expect(v.blocked).toBe(true);
```

**L132**
```typescript
  });
```

**L133**
```typescript

```

**L134**
```typescript
  it('allows at UTC 03:00 (= Seoul 12:00)', () => {
```

**L135**
```typescript
    const v = evaluateQuietHours(qh, new Date('2026-03-04T03:00:00Z'));
```

**L136**
```typescript
    expect(v.blocked).toBe(false);
```

**L137**
```typescript
  });
```

**L138**
```typescript
});
```

**L139**
```typescript

```

**L140**
```typescript
describe('evaluateQuietHours — invalid config', () => {
```

**L141**
```typescript
  it('blocks with invalid_config when start is malformed', () => {
```

**L142**
```typescript
    const v = evaluateQuietHours({
```

**L143**
```typescript
      timezone: 'UTC',
```

**L144**
```typescript
      start: '25:00',
```

**L145**
```typescript
      end: '08:00',
```

**L146**
```typescript
      weekends_blocked: false,
```

**L147**
```typescript
    });
```

**L148**
```typescript
    expect(v.blocked).toBe(true);
```

**L149**
```typescript
    expect(v.reason).toBe('invalid_config');
```

**L150**
```typescript
  });
```

**L151**
```typescript

```

**L152**
```typescript
  it('blocks with invalid_timezone when timezone is unknown', () => {
```

**L153**
```typescript
    const v = evaluateQuietHours({
```

**L154**
```typescript
      timezone: 'Not/A_Real_TZ',
```

**L155**
```typescript
      start: '22:00',
```

**L156**
```typescript
      end: '08:00',
```

**L157**
```typescript
      weekends_blocked: false,
```

**L158**
```typescript
    });
```

**L159**
```typescript
    expect(v.blocked).toBe(true);
```

**L160**
```typescript
    expect(v.reason).toBe('invalid_timezone');
```

**L161**
```typescript
  });
```

**L162**
```typescript
});
```

### `src\__tests__\email\tabs-mailer.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/email/tabs-mailer.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * TabsMailerClient (실 SMTP) + TabsMailerMockClient (mock) 양쪽 검증.
```

**L5**
```typescript
 * SMTP transporter는 nodemailer.createTransport stub으로 교체.
```

**L6**
```typescript
 */
```

**L7**
```typescript

```

**L8**
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

**L9**
```typescript
import {
```

**L10**
```typescript
  TabsMailerClient,
```

**L11**
```typescript
  TabsMailerNotImplementedError,
```

**L12**
```typescript
  TabsMailerQuietHoursError,
```

**L13**
```typescript
} from '../../lib/email/tabs-mailer';
```

**L14**
```typescript
import { TabsMailerMockClient } from '../../lib/email/tabs-mailer.mock';
```

**L15**
```typescript
import { URM_HEADER_NAMES, type SendOneInput } from '../../types/email';
```

**L16**
```typescript
import { buildSupabaseMock } from '../setup/supabase-mock';
```

**L17**
```typescript

```

**L18**
```typescript
function makeFakeTransporter(
```

**L19**
```typescript
  sendMailImpl?: (opts: unknown) => Promise<unknown>,
```

**L20**
```typescript
): {
```

**L21**
```typescript
  sendMail: ReturnType<typeof vi.fn>;
```

**L22**
```typescript
  verify: ReturnType<typeof vi.fn>;
```

**L23**
```typescript
  close: ReturnType<typeof vi.fn>;
```

**L24**
```typescript
} {
```

**L25**
```typescript
  return {
```

**L26**
```typescript
    sendMail: vi.fn(
```

**L27**
```typescript
      sendMailImpl ??
```

**L28**
```typescript
        ((opts: unknown) => {
```

**L29**
```typescript
          // nodemailer 응답 모양 모방
```

**L30**
```typescript
          void opts;
```

**L31**
```typescript
          return Promise.resolve({
```

**L32**
```typescript
            messageId: '<smtp-msg-id@local>',
```

**L33**
```typescript
            accepted: ['to@x.com'],
```

**L34**
```typescript
            rejected: [],
```

**L35**
```typescript
            response: '250 OK',
```

**L36**
```typescript
          });
```

**L37**
```typescript
        }),
```

**L38**
```typescript
    ),
```

**L39**
```typescript
    verify: vi.fn(() => Promise.resolve(true)),
```

**L40**
```typescript
    close: vi.fn(),
```

**L41**
```typescript
  };
```

**L42**
```typescript
}
```

**L43**
```typescript

```

**L44**
```typescript
const baseSendInput: SendOneInput = {
```

**L45**
```typescript
  to: { name: 'Bob', address: 'to@x.com' },
```

**L46**
```typescript
  fromName: 'Sender',
```

**L47**
```typescript
  fromAddress: 'sender@org.com',
```

**L48**
```typescript
  subject: 'Hello',
```

**L49**
```typescript
  bodyText: 'Plain body',
```

**L50**
```typescript
  bodyHtml: '<p>Hello</p>',
```

**L51**
```typescript
  urmHeaders: {
```

**L52**
```typescript
    communicationId: 'comm-123',
```

**L53**
```typescript
    autoSend: false,
```

**L54**
```typescript
    engagementId: 'eng-456',
```

**L55**
```typescript
    brandVoiceId: 'bv-789',
```

**L56**
```typescript
  },
```

**L57**
```typescript
};
```

**L58**
```typescript

```

**L59**
```typescript
describe('TabsMailerClient.sendOne', () => {
```

**L60**
```typescript
  let transporter: ReturnType<typeof makeFakeTransporter>;
```

**L61**
```typescript
  let client: TabsMailerClient;
```

**L62**
```typescript

```

**L63**
```typescript
  beforeEach(() => {
```

**L64**
```typescript
    transporter = makeFakeTransporter();
```

**L65**
```typescript
    client = new TabsMailerClient({ transporter: transporter as never });
```

**L66**
```typescript
  });
```

**L67**
```typescript

```

**L68**
```typescript
  it('attaches X-URM-* headers correctly', async () => {
```

**L69**
```typescript
    const out = await client.sendOne(baseSendInput);
```

**L70**
```typescript

```

**L71**
```typescript
    expect(out.messageId).toBe('<smtp-msg-id@local>');
```

**L72**
```typescript
    expect(out.acceptedRecipients).toEqual(['to@x.com']);
```

**L73**
```typescript

```

**L74**
```typescript
    const callArgs = transporter.sendMail.mock.calls[0]?.[0] as Record<string, unknown>;
```

**L75**
```typescript
    const headers = callArgs.headers as Record<string, string>;
```

**L76**
```typescript
    expect(headers[URM_HEADER_NAMES.communicationId]).toBe('comm-123');
```

**L77**
```typescript
    expect(headers[URM_HEADER_NAMES.engagementId]).toBe('eng-456');
```

**L78**
```typescript
    expect(headers[URM_HEADER_NAMES.brandVoiceId]).toBe('bv-789');
```

**L79**
```typescript
    expect(headers[URM_HEADER_NAMES.autoSend]).toBe('false');
```

**L80**
```typescript
  });
```

**L81**
```typescript

```

**L82**
```typescript
  it('appends invisible footer to HTML body', async () => {
```

**L83**
```typescript
    await client.sendOne(baseSendInput);
```

**L84**
```typescript
    const callArgs = transporter.sendMail.mock.calls[0]?.[0] as Record<string, unknown>;
```

**L85**
```typescript
    const html = callArgs.html as string;
```

**L86**
```typescript
    expect(html).toContain('<!-- urm:c=comm-123;auto=0;e=eng-456 -->');
```

**L87**
```typescript
  });
```

**L88**
```typescript

```

**L89**
```typescript
  it('autoSend=true encodes as auto=1 in footer', async () => {
```

**L90**
```typescript
    await client.sendOne({
```

**L91**
```typescript
      ...baseSendInput,
```

**L92**
```typescript
      urmHeaders: { ...baseSendInput.urmHeaders, autoSend: true },
```

**L93**
```typescript
    });
```

**L94**
```typescript
    const callArgs = transporter.sendMail.mock.calls[0]?.[0] as Record<string, unknown>;
```

**L95**
```typescript
    const headers = callArgs.headers as Record<string, string>;
```

**L96**
```typescript
    expect(headers[URM_HEADER_NAMES.autoSend]).toBe('true');
```

**L97**
```typescript
    expect((callArgs.html as string)).toContain('auto=1');
```

**L98**
```typescript
  });
```

**L99**
```typescript

```

**L100**
```typescript
  it('blocks when within quiet hours', async () => {
```

**L101**
```typescript
    await expect(
```

**L102**
```typescript
      client.sendOne({
```

**L103**
```typescript
        ...baseSendInput,
```

**L104**
```typescript
        quietHours: {
```

**L105**
```typescript
          timezone: 'UTC',
```

**L106**
```typescript
          start: '00:00',
```

**L107**
```typescript
          end: '23:59',
```

**L108**
```typescript
          weekends_blocked: false,
```

**L109**
```typescript
        },
```

**L110**
```typescript
      }),
```

**L111**
```typescript
    ).rejects.toBeInstanceOf(TabsMailerQuietHoursError);
```

**L112**
```typescript
  });
```

**L113**
```typescript

```

**L114**
```typescript
  it('bypassQuietHours overrides the check', async () => {
```

**L115**
```typescript
    await expect(
```

**L116**
```typescript
      client.sendOne({
```

**L117**
```typescript
        ...baseSendInput,
```

**L118**
```typescript
        bypassQuietHours: true,
```

**L119**
```typescript
        quietHours: {
```

**L120**
```typescript
          timezone: 'UTC',
```

**L121**
```typescript
          start: '00:00',
```

**L122**
```typescript
          end: '23:59',
```

**L123**
```typescript
          weekends_blocked: false,
```

**L124**
```typescript
        },
```

**L125**
```typescript
      }),
```

**L126**
```typescript
    ).resolves.toMatchObject({ messageId: expect.any(String) });
```

**L127**
```typescript
  });
```

**L128**
```typescript

```

**L129**
```typescript
  it('wraps SMTP errors in TabsMailerError', async () => {
```

**L130**
```typescript
    const failing = makeFakeTransporter(() =>
```

**L131**
```typescript
      Promise.reject(new Error('554 message rejected')),
```

**L132**
```typescript
    );
```

**L133**
```typescript
    const c = new TabsMailerClient({ transporter: failing as never });
```

**L134**
```typescript
    await expect(c.sendOne(baseSendInput)).rejects.toThrow(/sendOne failed/);
```

**L135**
```typescript
  });
```

**L136**
```typescript
});
```

**L137**
```typescript

```

**L138**
```typescript
describe('TabsMailerClient.createCampaign / getCampaignStats', () => {
```

**L139**
```typescript
  it('throws NotImplementedError until 탭스랩 spec is received', async () => {
```

**L140**
```typescript
    const client = new TabsMailerClient({
```

**L141**
```typescript
      transporter: makeFakeTransporter() as never,
```

**L142**
```typescript
    });
```

**L143**
```typescript
    await expect(
```

**L144**
```typescript
      client.createCampaign({
```

**L145**
```typescript
        name: 'Test',
```

**L146**
```typescript
        templateId: 't-1',
```

**L147**
```typescript
        recipientCount: 100,
```

**L148**
```typescript
        fromAddress: 'a@b.com',
```

**L149**
```typescript
      }),
```

**L150**
```typescript
    ).rejects.toBeInstanceOf(TabsMailerNotImplementedError);
```

**L151**
```typescript

```

**L152**
```typescript
    await expect(client.getCampaignStats('campaign-1')).rejects.toBeInstanceOf(
```

**L153**
```typescript
      TabsMailerNotImplementedError,
```

**L154**
```typescript
    );
```

**L155**
```typescript
  });
```

**L156**
```typescript
});
```

**L157**
```typescript

```

**L158**
```typescript
describe('TabsMailerMockClient', () => {
```

**L159**
```typescript
  it('records sent emails and returns mock messageId', async () => {
```

**L160**
```typescript
    const mock = new TabsMailerMockClient();
```

**L161**
```typescript
    const out = await mock.sendOne(baseSendInput);
```

**L162**
```typescript
    expect(out.messageId).toMatch(/^<mock-[a-f0-9-]+@local>$/);
```

**L163**
```typescript

```

**L164**
```typescript
    const log = mock.getSentLog();
```

**L165**
```typescript
    expect(log).toHaveLength(1);
```

**L166**
```typescript
    expect(log[0]?.to).toBe('to@x.com');
```

**L167**
```typescript
    expect(log[0]?.urmCommunicationId).toBe('comm-123');
```

**L168**
```typescript
  });
```

**L169**
```typescript

```

**L170**
```typescript
  it('createCampaign returns a deterministic shape', async () => {
```

**L171**
```typescript
    const mock = new TabsMailerMockClient();
```

**L172**
```typescript
    const r = await mock.createCampaign({
```

**L173**
```typescript
      name: 'Q1',
```

**L174**
```typescript
      templateId: 't-1',
```

**L175**
```typescript
      recipientCount: 50,
```

**L176**
```typescript
      fromAddress: 'a@b.com',
```

**L177**
```typescript
    });
```

**L178**
```typescript
    expect(r.tabsCampaignId).toMatch(/^mock-campaign-/);
```

**L179**
```typescript
    expect(r.status).toBe('queued');
```

**L180**
```typescript
  });
```

**L181**
```typescript

```

**L182**
```typescript
  it('setMockStats + syncCampaignToMergeJob updates mail_merge_jobs.progress', async () => {
```

**L183**
```typescript
    const mock = new TabsMailerMockClient();
```

**L184**
```typescript
    const created = await mock.createCampaign({
```

**L185**
```typescript
      name: 'Q1',
```

**L186**
```typescript
      templateId: 't-1',
```

**L187**
```typescript
      recipientCount: 50,
```

**L188**
```typescript
      fromAddress: 'a@b.com',
```

**L189**
```typescript
    });
```

**L190**
```typescript
    mock.setMockStats(created.tabsCampaignId, {
```

**L191**
```typescript
      totalSent: 30,
```

**L192**
```typescript
      totalOpened: 20,
```

**L193**
```typescript
      totalClicked: 5,
```

**L194**
```typescript
    });
```

**L195**
```typescript

```

**L196**
```typescript
    const sb = buildSupabaseMock({
```

**L197**
```typescript
      'app.mail_merge_jobs': {
```

**L198**
```typescript
        selectMaybeSingle: {
```

**L199**
```typescript
          data: { id: 'job-1', tabs_campaign_id: created.tabsCampaignId },
```

**L200**
```typescript
        },
```

**L201**
```typescript
        updateResult: { error: null },
```

**L202**
```typescript
      },
```

**L203**
```typescript
    });
```

**L204**
```typescript

```

**L205**
```typescript
    await mock.syncCampaignToMergeJob(sb as never, 'org-1', 'job-1');
```

**L206**
```typescript

```

**L207**
```typescript
    // UPDATE 호출이 progress를 갱신했는지
```

**L208**
```typescript
    const updates = sb.__calls.update.filter(
```

**L209**
```typescript
      (c) => c.schema === 'app' && c.table === 'mail_merge_jobs',
```

**L210**
```typescript
    );
```

**L211**
```typescript
    expect(updates).toHaveLength(1);
```

**L212**
```typescript
    const payload = updates[0]?.payload as Record<string, unknown>;
```

**L213**
```typescript
    const progress = payload.progress as Record<string, number>;
```

**L214**
```typescript
    expect(progress.sent).toBe(30);
```

**L215**
```typescript
    expect(progress.opened).toBe(20);
```

**L216**
```typescript
    expect(progress.clicked).toBe(5);
```

**L217**
```typescript
  });
```

**L218**
```typescript

```

**L219**
```typescript
  it('blocks send when within quiet hours (parity with real client)', async () => {
```

**L220**
```typescript
    const mock = new TabsMailerMockClient();
```

**L221**
```typescript
    await expect(
```

**L222**
```typescript
      mock.sendOne({
```

**L223**
```typescript
        ...baseSendInput,
```

**L224**
```typescript
        quietHours: {
```

**L225**
```typescript
          timezone: 'UTC',
```

**L226**
```typescript
          start: '00:00',
```

**L227**
```typescript
          end: '23:59',
```

**L228**
```typescript
          weekends_blocked: false,
```

**L229**
```typescript
        },
```

**L230**
```typescript
      }),
```

**L231**
```typescript
    ).rejects.toBeInstanceOf(TabsMailerQuietHoursError);
```

**L232**
```typescript
  });
```

**L233**
```typescript
});
```

### `src\__tests__\setup\env-setup.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/setup/env-setup.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * vitest setupFiles에 등록되는 진입점.
```

**L5**
```typescript
 * env.ts가 모듈 로드 시점에 zod 검증을 실행하므로,
```

**L6**
```typescript
 * 모든 env 변수를 본 파일에서 미리 주입한다.
```

**L7**
```typescript
 */
```

**L8**
```typescript

```

**L9**
```typescript
// Anthropic
```

**L10**
```typescript
process.env.ANTHROPIC_API_KEY ??= 'sk-ant-test-1234567890abcdefghij';
```

**L11**
```typescript
process.env.ANTHROPIC_MODEL_OPUS ??= 'claude-opus-4-7';
```

**L12**
```typescript
process.env.ANTHROPIC_MODEL_HAIKU ??= 'claude-haiku-4-5-20251001';
```

**L13**
```typescript
process.env.ANTHROPIC_MODEL_SONNET ??= 'claude-sonnet-4-6';
```

**L14**
```typescript

```

**L15**
```typescript
// OpenAI
```

**L16**
```typescript
process.env.OPENAI_API_KEY ??= 'sk-test-1234567890abcdefghij';
```

**L17**
```typescript
process.env.OPENAI_EMBEDDING_MODEL ??= 'text-embedding-3-large';
```

**L18**
```typescript

```

**L19**
```typescript
// Supabase
```

**L20**
```typescript
process.env.NEXT_PUBLIC_SUPABASE_URL ??= 'https://test.supabase.co';
```

**L21**
```typescript
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??= 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature';
```

**L22**
```typescript
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.role.signature';
```

**L23**
```typescript
process.env.SUPABASE_DB_URL ??= 'postgres://test:test@localhost:5432/test';
```

**L24**
```typescript
process.env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS ??= 'communications-attachments';
```

**L25**
```typescript

```

**L26**
```typescript
// TABS Mailer
```

**L27**
```typescript
process.env.TABS_MAILER_HOST ??= 'mock';
```

**L28**
```typescript
process.env.TABS_MAILER_PORT ??= '587';
```

**L29**
```typescript
process.env.TABS_MAILER_AUTH_METHOD ??= 'login';
```

**L30**
```typescript
process.env.TABS_MAILER_USERNAME ??= 'test-user';
```

**L31**
```typescript
process.env.TABS_MAILER_PASSWORD ??= 'test-pass';
```

**L32**
```typescript
process.env.TABS_MAILER_FROM_DOMAIN ??= 'test.example.com';
```

**L33**
```typescript
process.env.TABS_MAILER_USE_TLS ??= 'true';
```

**L34**
```typescript
process.env.TABS_MAILER_USE_MOCK ??= 'true';
```

**L35**
```typescript

```

**L36**
```typescript
// MailCarrier
```

**L37**
```typescript
process.env.MAILCARRIER_HOST ??= 'imap.test.example.com';
```

**L38**
```typescript
process.env.MAILCARRIER_PORT ??= '993';
```

**L39**
```typescript
process.env.MAILCARRIER_USERNAME ??= 'inbox@test.example.com';
```

**L40**
```typescript
process.env.MAILCARRIER_PASSWORD ??= 'imap-test-pass';
```

**L41**
```typescript
process.env.MAILCARRIER_USE_IDLE ??= 'false';
```

**L42**
```typescript
process.env.MAILCARRIER_INBOX_FOLDER ??= 'INBOX';
```

**L43**
```typescript
process.env.MAILCARRIER_POLL_INTERVAL_SECONDS ??= '30';
```

**L44**
```typescript

```

**L45**
```typescript
// Business
```

**L46**
```typescript
process.env.AI_AUTO_SEND_ENABLED ??= 'false';
```

**L47**
```typescript
process.env.SCRAPING_ENABLED ??= 'true';
```

**L48**
```typescript
process.env.MAX_DAILY_AI_COST_USD ??= '10';
```

**L49**
```typescript
process.env.MAX_MONTHLY_AI_COST_USD ??= '100';
```

**L50**
```typescript
process.env.DRAFT_EXPIRY_DAYS ??= '7';
```

**L51**
```typescript
process.env.LOG_LEVEL ??= 'error';
```

**L52**
```typescript
process.env.WORKER_RUNTIME ??= 'node';
```

**L53**
```typescript
// NODE_ENV는 @types/node에서 readonly literal union으로 선언됨 — 우회를 위해 캐스트
```

**L54**
```typescript
(process.env as Record<string, string | undefined>).NODE_ENV ??= 'test';
```

**L55**
```typescript

```

**L56**
```typescript
// STEP 4 프론트엔드
```

**L57**
```typescript
process.env.NEXT_PUBLIC_APP_URL ??= 'http://localhost:3000';
```

**L58**
```typescript
process.env.NEXT_PUBLIC_DEFAULT_LOCALE ??= 'ko';
```

### `src\__tests__\setup\supabase-mock.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/setup/supabase-mock.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * Supabase 클라이언트 mock 빌더.
```

**L5**
```typescript
 *
```

**L6**
```typescript
 * 핵심 설계:
```

**L7**
```typescript
 *   - select / insert / update / delete 어느 것이든 builder 객체 반환
```

**L8**
```typescript
 *   - eq / order / limit 등 모든 chain 메서드도 builder 반환
```

**L9**
```typescript
 *   - 종단 평가는 다음 중 하나:
```

**L10**
```typescript
 *       * .single() / .maybeSingle() 호출 → 등록된 응답 반환
```

**L11**
```typescript
 *       * await builder (thenable) → 등록된 응답 반환 (Supabase의 PostgREST 동작)
```

**L12**
```typescript
 */
```

**L13**
```typescript

```

**L14**
```typescript
import { vi } from 'vitest';
```

**L15**
```typescript

```

**L16**
```typescript
export interface TableMockResponses {
```

**L17**
```typescript
  selectMaybeSingle?: { data: unknown; error?: unknown };
```

**L18**
```typescript
  selectCount?: { count: number; error?: unknown };
```

**L19**
```typescript
  selectList?: { data: unknown[]; error?: unknown };
```

**L20**
```typescript
  insertSingle?: { data: unknown; error?: unknown };
```

**L21**
```typescript
  updateResult?: { data?: unknown; error?: unknown };
```

**L22**
```typescript
  rpcResult?: { data: unknown; error?: unknown };
```

**L23**
```typescript
}
```

**L24**
```typescript

```

**L25**
```typescript
export interface SupabaseMockSpec {
```

**L26**
```typescript
  [schemaTable: string]: TableMockResponses;
```

**L27**
```typescript
}
```

**L28**
```typescript

```

**L29**
```typescript
export interface MockSupabaseCalls {
```

**L30**
```typescript
  insert: Array<{ schema: string; table: string; payload: unknown }>;
```

**L31**
```typescript
  update: Array<{ schema: string; table: string; payload: unknown }>;
```

**L32**
```typescript
  select: Array<{ schema: string; table: string; columns: string }>;
```

**L33**
```typescript
  rpc: Array<{ name: string; args: unknown }>;
```

**L34**
```typescript
}
```

**L35**
```typescript

```

**L36**
```typescript
export interface MockSupabase {
```

**L37**
```typescript
  schema: ReturnType<typeof vi.fn>;
```

**L38**
```typescript
  from: ReturnType<typeof vi.fn>;
```

**L39**
```typescript
  rpc: ReturnType<typeof vi.fn>;
```

**L40**
```typescript
  storage: {
```

**L41**
```typescript
    from: ReturnType<typeof vi.fn>;
```

**L42**
```typescript
  };
```

**L43**
```typescript
  __calls: MockSupabaseCalls;
```

**L44**
```typescript
}
```

**L45**
```typescript

```

**L46**
```typescript
export function buildSupabaseMock(spec: SupabaseMockSpec = {}): MockSupabase {
```

**L47**
```typescript
  const calls: MockSupabaseCalls = {
```

**L48**
```typescript
    insert: [],
```

**L49**
```typescript
    update: [],
```

**L50**
```typescript
    select: [],
```

**L51**
```typescript
    rpc: [],
```

**L52**
```typescript
  };
```

**L53**
```typescript

```

**L54**
```typescript
  const root: MockSupabase = {
```

**L55**
```typescript
    schema: vi.fn((schemaName: string) => ({
```

**L56**
```typescript
      from: (table: string) => makeQueryBuilder(schemaName, table),
```

**L57**
```typescript
    })),
```

**L58**
```typescript
    from: vi.fn((table: string) => makeQueryBuilder('public', table)),
```

**L59**
```typescript
    rpc: vi.fn((name: string, args: unknown) => {
```

**L60**
```typescript
      calls.rpc.push({ name, args });
```

**L61**
```typescript
      const r = spec[`rpc.${name}`];
```

**L62**
```typescript
      return Promise.resolve(r?.rpcResult ?? { data: null, error: null });
```

**L63**
```typescript
    }),
```

**L64**
```typescript
    storage: {
```

**L65**
```typescript
      from: vi.fn(() => ({
```

**L66**
```typescript
        upload: vi.fn(() => Promise.resolve({ data: null, error: null })),
```

**L67**
```typescript
        remove: vi.fn(() => Promise.resolve({ data: null, error: null })),
```

**L68**
```typescript
        download: vi.fn(() => Promise.resolve({ data: null, error: null })),
```

**L69**
```typescript
      })),
```

**L70**
```typescript
    },
```

**L71**
```typescript
    __calls: calls,
```

**L72**
```typescript
  };
```

**L73**
```typescript

```

**L74**
```typescript
  function makeQueryBuilder(schema: string, table: string) {
```

**L75**
```typescript
    const key = `${schema}.${table}`;
```

**L76**
```typescript
    const responses = spec[key] ?? {};
```

**L77**
```typescript

```

**L78**
```typescript
    let mode: 'select' | 'insert' | 'update' | 'delete' = 'select';
```

**L79**
```typescript
    let isCountHead = false;
```

**L80**
```typescript

```

**L81**
```typescript
    // 종단 응답 결정
```

**L82**
```typescript
    function resolveTerminal(forSingle: boolean): { data: unknown; error: unknown; count?: number } {
```

**L83**
```typescript
      if (mode === 'insert') {
```

**L84**
```typescript
        const r = responses.insertSingle ?? { data: null, error: null };
```

**L85**
```typescript
        return { data: r.data, error: r.error ?? null };
```

**L86**
```typescript
      }
```

**L87**
```typescript
      if (mode === 'update') {
```

**L88**
```typescript
        const r = responses.updateResult ?? { data: null, error: null };
```

**L89**
```typescript
        return { data: r.data ?? null, error: r.error ?? null };
```

**L90**
```typescript
      }
```

**L91**
```typescript
      if (mode === 'delete') {
```

**L92**
```typescript
        return { data: null, error: null };
```

**L93**
```typescript
      }
```

**L94**
```typescript
      // select
```

**L95**
```typescript
      if (isCountHead) {
```

**L96**
```typescript
        const r = responses.selectCount ?? { count: 0, error: null };
```

**L97**
```typescript
        return { data: null, error: r.error ?? null, count: r.count };
```

**L98**
```typescript
      }
```

**L99**
```typescript
      if (forSingle) {
```

**L100**
```typescript
        const r = responses.selectMaybeSingle ?? { data: null, error: null };
```

**L101**
```typescript
        return { data: r.data, error: r.error ?? null };
```

**L102**
```typescript
      }
```

**L103**
```typescript
      const r = responses.selectList ?? { data: [], error: null };
```

**L104**
```typescript
      return { data: r.data, error: r.error ?? null };
```

**L105**
```typescript
    }
```

**L106**
```typescript

```

**L107**
```typescript
    const builder: Record<string, unknown> = {};
```

**L108**
```typescript

```

**L109**
```typescript
    builder.select = vi.fn(
```

**L110**
```typescript
      (cols?: unknown, options?: { count?: string; head?: boolean }) => {
```

**L111**
```typescript
        // insert/update 후의 .select()는 PostgREST RETURNING — mode 유지
```

**L112**
```typescript
        if (mode !== 'insert' && mode !== 'update') {
```

**L113**
```typescript
          mode = 'select';
```

**L114**
```typescript
        }
```

**L115**
```typescript
        const colStr = typeof cols === 'string' ? cols : '*';
```

**L116**
```typescript
        if (options?.count === 'exact' && options?.head === true) {
```

**L117**
```typescript
          isCountHead = true;
```

**L118**
```typescript
        }
```

**L119**
```typescript
        calls.select.push({ schema, table, columns: colStr });
```

**L120**
```typescript
        return builder;
```

**L121**
```typescript
      },
```

**L122**
```typescript
    );
```

**L123**
```typescript
    builder.insert = vi.fn((payload: unknown) => {
```

**L124**
```typescript
      mode = 'insert';
```

**L125**
```typescript
      calls.insert.push({ schema, table, payload });
```

**L126**
```typescript
      return builder;
```

**L127**
```typescript
    });
```

**L128**
```typescript
    builder.update = vi.fn((payload: unknown) => {
```

**L129**
```typescript
      mode = 'update';
```

**L130**
```typescript
      calls.update.push({ schema, table, payload });
```

**L131**
```typescript
      return builder;
```

**L132**
```typescript
    });
```

**L133**
```typescript
    builder.delete = vi.fn(() => {
```

**L134**
```typescript
      mode = 'delete';
```

**L135**
```typescript
      return builder;
```

**L136**
```typescript
    });
```

**L137**
```typescript
    builder.upsert = vi.fn((payload: unknown) => {
```

**L138**
```typescript
      mode = 'insert';
```

**L139**
```typescript
      calls.insert.push({ schema, table, payload });
```

**L140**
```typescript
      return builder;
```

**L141**
```typescript
    });
```

**L142**
```typescript

```

**L143**
```typescript
    for (const m of [
```

**L144**
```typescript
      'eq', 'neq', 'gt', 'gte', 'lt', 'lte',
```

**L145**
```typescript
      'like', 'ilike', 'is', 'in', 'contains', 'containedBy',
```

**L146**
```typescript
      'rangeGt', 'rangeGte', 'rangeLt', 'rangeLte', 'rangeAdjacent',
```

**L147**
```typescript
      'overlaps', 'textSearch', 'match', 'not', 'or', 'filter',
```

**L148**
```typescript
      'order', 'limit', 'range', 'abortSignal', 'returns',
```

**L149**
```typescript
    ]) {
```

**L150**
```typescript
      builder[m] = vi.fn(() => builder);
```

**L151**
```typescript
    }
```

**L152**
```typescript

```

**L153**
```typescript
    builder.single = vi.fn(() => Promise.resolve(resolveTerminal(true)));
```

**L154**
```typescript
    builder.maybeSingle = vi.fn(() => Promise.resolve(resolveTerminal(true)));
```

**L155**
```typescript

```

**L156**
```typescript
    builder.then = (
```

**L157**
```typescript
      onFulfilled?: (v: unknown) => unknown,
```

**L158**
```typescript
      onRejected?: (v: unknown) => unknown,
```

**L159**
```typescript
    ): Promise<unknown> =>
```

**L160**
```typescript
      Promise.resolve(resolveTerminal(false)).then(onFulfilled, onRejected);
```

**L161**
```typescript

```

**L162**
```typescript
    builder.catch = (onRejected: (v: unknown) => unknown): Promise<unknown> =>
```

**L163**
```typescript
      Promise.resolve(resolveTerminal(false)).catch(onRejected);
```

**L164**
```typescript

```

**L165**
```typescript
    return builder;
```

**L166**
```typescript
  }
```

**L167**
```typescript

```

**L168**
```typescript
  return root;
```

**L169**
```typescript
}
```

### `src\__tests__\step4\action-schemas.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * tests/action-schemas.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * Server Actions의 zod 검증 로직 테스트.
```

**L5**
```typescript
 * Server Action 자체는 supabase mock 없이 테스트하기 복잡하므로,
```

**L6**
```typescript
 * 여기선 schema가 input을 정확히 검증·정규화하는지에 집중.
```

**L7**
```typescript
 *
```

**L8**
```typescript
 * Server Action 모듈을 직접 import할 수 없는 이유: 'use server' + supabase server client
```

**L9**
```typescript
 * → schema를 재정의해서 동일 규칙 검증.
```

**L10**
```typescript
 */
```

**L11**
```typescript

```

**L12**
```typescript
import { describe, it, expect } from 'vitest';
```

**L13**
```typescript
import { z } from 'zod';
```

**L14**
```typescript

```

**L15**
```typescript
describe('Party action schemas', () => {
```

**L16**
```typescript
  // src/lib/actions/parties.ts와 동일한 규칙 재정의
```

**L17**
```typescript
  const partySchema = z.object({
```

**L18**
```typescript
    name: z.string().min(1).max(200),
```

**L19**
```typescript
    module: z.enum([
```

**L20**
```typescript
      'investor',
```

**L21**
```typescript
      'paper_mill',
```

**L22**
```typescript
      'partner',
```

**L23**
```typescript
      'customer',
```

**L24**
```typescript
      'filler_supplier',
```

**L25**
```typescript
    ]),
```

**L26**
```typescript
    partyType: z.enum(['company', 'individual', 'organization']).default('company'),
```

**L27**
```typescript
    tier: z.enum(['tier_1', 'tier_2', 'tier_3', 'cold']).optional().nullable(),
```

**L28**
```typescript
    countryCode: z
```

**L29**
```typescript
      .string()
```

**L30**
```typescript
      .length(2)
```

**L31**
```typescript
      .optional()
```

**L32**
```typescript
      .nullable()
```

**L33**
```typescript
      .or(z.literal('').transform(() => null)),
```

**L34**
```typescript
    website: z
```

**L35**
```typescript
      .string()
```

**L36**
```typescript
      .url()
```

**L37**
```typescript
      .max(500)
```

**L38**
```typescript
      .optional()
```

**L39**
```typescript
      .nullable()
```

**L40**
```typescript
      .or(z.literal('').transform(() => null)),
```

**L41**
```typescript
  });
```

**L42**
```typescript

```

**L43**
```typescript
  it('accepts valid input', () => {
```

**L44**
```typescript
    const result = partySchema.safeParse({
```

**L45**
```typescript
      name: 'Acme Inc.',
```

**L46**
```typescript
      module: 'paper_mill',
```

**L47**
```typescript
    });
```

**L48**
```typescript
    expect(result.success).toBe(true);
```

**L49**
```typescript
  });
```

**L50**
```typescript

```

**L51**
```typescript
  it('rejects empty name', () => {
```

**L52**
```typescript
    const result = partySchema.safeParse({ name: '', module: 'paper_mill' });
```

**L53**
```typescript
    expect(result.success).toBe(false);
```

**L54**
```typescript
  });
```

**L55**
```typescript

```

**L56**
```typescript
  it('rejects name > 200 chars', () => {
```

**L57**
```typescript
    const result = partySchema.safeParse({
```

**L58**
```typescript
      name: 'A'.repeat(201),
```

**L59**
```typescript
      module: 'paper_mill',
```

**L60**
```typescript
    });
```

**L61**
```typescript
    expect(result.success).toBe(false);
```

**L62**
```typescript
  });
```

**L63**
```typescript

```

**L64**
```typescript
  it('rejects unknown module', () => {
```

**L65**
```typescript
    const result = partySchema.safeParse({
```

**L66**
```typescript
      name: 'A',
```

**L67**
```typescript
      module: 'unknown_module',
```

**L68**
```typescript
    });
```

**L69**
```typescript
    expect(result.success).toBe(false);
```

**L70**
```typescript
  });
```

**L71**
```typescript

```

**L72**
```typescript
  it('accepts 7 valid modules', () => {
```

**L73**
```typescript
    const modules = [
```

**L74**
```typescript
      'investor',
```

**L75**
```typescript
      'paper_mill',
```

**L76**
```typescript
      'partner',
```

**L77**
```typescript
      'customer',
```

**L78**
```typescript
      'filler_supplier',
```

**L79**
```typescript
    ];
```

**L80**
```typescript
    for (const m of modules) {
```

**L81**
```typescript
      expect(partySchema.safeParse({ name: 'X', module: m }).success).toBe(true);
```

**L82**
```typescript
    }
```

**L83**
```typescript
  });
```

**L84**
```typescript

```

**L85**
```typescript
  it('accepts 2-letter country code', () => {
```

**L86**
```typescript
    expect(
```

**L87**
```typescript
      partySchema.safeParse({ name: 'X', module: 'paper_mill', countryCode: 'KR' }).success,
```

**L88**
```typescript
    ).toBe(true);
```

**L89**
```typescript
  });
```

**L90**
```typescript

```

**L91**
```typescript
  it('rejects 3-letter country code', () => {
```

**L92**
```typescript
    expect(
```

**L93**
```typescript
      partySchema.safeParse({ name: 'X', module: 'paper_mill', countryCode: 'KOR' }).success,
```

**L94**
```typescript
    ).toBe(false);
```

**L95**
```typescript
  });
```

**L96**
```typescript

```

**L97**
```typescript
  it('accepts empty string country (transforms to null)', () => {
```

**L98**
```typescript
    const r = partySchema.safeParse({ name: 'X', module: 'paper_mill', countryCode: '' });
```

**L99**
```typescript
    expect(r.success).toBe(true);
```

**L100**
```typescript
    if (r.success) expect(r.data.countryCode).toBeNull();
```

**L101**
```typescript
  });
```

**L102**
```typescript

```

**L103**
```typescript
  it('accepts https website', () => {
```

**L104**
```typescript
    expect(
```

**L105**
```typescript
      partySchema.safeParse({
```

**L106**
```typescript
        name: 'X',
```

**L107**
```typescript
        module: 'paper_mill',
```

**L108**
```typescript
        website: 'https://example.com',
```

**L109**
```typescript
      }).success,
```

**L110**
```typescript
    ).toBe(true);
```

**L111**
```typescript
  });
```

**L112**
```typescript

```

**L113**
```typescript
  it('rejects bare-domain website (no protocol)', () => {
```

**L114**
```typescript
    expect(
```

**L115**
```typescript
      partySchema.safeParse({ name: 'X', module: 'paper_mill', website: 'example.com' })
```

**L116**
```typescript
        .success,
```

**L117**
```typescript
    ).toBe(false);
```

**L118**
```typescript
  });
```

**L119**
```typescript
});
```

**L120**
```typescript

```

**L121**
```typescript
describe('Compose action schemas', () => {
```

**L122**
```typescript
  const composeSchema = z.object({
```

**L123**
```typescript
    to: z.string().email().max(255),
```

**L124**
```typescript
    subject: z.string().min(1).max(500),
```

**L125**
```typescript
    bodyPlain: z.string().min(1).max(50_000),
```

**L126**
```typescript
  });
```

**L127**
```typescript

```

**L128**
```typescript
  it('accepts valid email', () => {
```

**L129**
```typescript
    expect(
```

**L130**
```typescript
      composeSchema.safeParse({
```

**L131**
```typescript
        to: 'a@b.com',
```

**L132**
```typescript
        subject: 's',
```

**L133**
```typescript
        bodyPlain: 'b',
```

**L134**
```typescript
      }).success,
```

**L135**
```typescript
    ).toBe(true);
```

**L136**
```typescript
  });
```

**L137**
```typescript

```

**L138**
```typescript
  it('rejects invalid email', () => {
```

**L139**
```typescript
    expect(
```

**L140**
```typescript
      composeSchema.safeParse({
```

**L141**
```typescript
        to: 'not-an-email',
```

**L142**
```typescript
        subject: 's',
```

**L143**
```typescript
        bodyPlain: 'b',
```

**L144**
```typescript
      }).success,
```

**L145**
```typescript
    ).toBe(false);
```

**L146**
```typescript
  });
```

**L147**
```typescript

```

**L148**
```typescript
  it('rejects empty body', () => {
```

**L149**
```typescript
    expect(
```

**L150**
```typescript
      composeSchema.safeParse({
```

**L151**
```typescript
        to: 'a@b.com',
```

**L152**
```typescript
        subject: 's',
```

**L153**
```typescript
        bodyPlain: '',
```

**L154**
```typescript
      }).success,
```

**L155**
```typescript
    ).toBe(false);
```

**L156**
```typescript
  });
```

**L157**
```typescript

```

**L158**
```typescript
  it('rejects body > 50k', () => {
```

**L159**
```typescript
    expect(
```

**L160**
```typescript
      composeSchema.safeParse({
```

**L161**
```typescript
        to: 'a@b.com',
```

**L162**
```typescript
        subject: 's',
```

**L163**
```typescript
        bodyPlain: 'x'.repeat(50_001),
```

**L164**
```typescript
      }).success,
```

**L165**
```typescript
    ).toBe(false);
```

**L166**
```typescript
  });
```

**L167**
```typescript
});
```

**L168**
```typescript

```

**L169**
```typescript
describe('Engagement action schemas', () => {
```

**L170**
```typescript
  const engagementSchema = z.object({
```

**L171**
```typescript
    name: z.string().min(1).max(200),
```

**L172**
```typescript
    valueAmount: z.number().min(0).max(1e15).optional().nullable(),
```

**L173**
```typescript
    valueCurrency: z.string().length(3).default('USD'),
```

**L174**
```typescript
    probabilityPct: z.number().int().min(0).max(100).default(0),
```

**L175**
```typescript
  });
```

**L176**
```typescript

```

**L177**
```typescript
  it('accepts valid', () => {
```

**L178**
```typescript
    expect(
```

**L179**
```typescript
      engagementSchema.safeParse({
```

**L180**
```typescript
        name: 'Q3 Deal',
```

**L181**
```typescript
        valueAmount: 50000,
```

**L182**
```typescript
        probabilityPct: 75,
```

**L183**
```typescript
      }).success,
```

**L184**
```typescript
    ).toBe(true);
```

**L185**
```typescript
  });
```

**L186**
```typescript

```

**L187**
```typescript
  it('rejects negative value', () => {
```

**L188**
```typescript
    expect(
```

**L189**
```typescript
      engagementSchema.safeParse({ name: 'X', valueAmount: -100 }).success,
```

**L190**
```typescript
    ).toBe(false);
```

**L191**
```typescript
  });
```

**L192**
```typescript

```

**L193**
```typescript
  it('rejects probability > 100', () => {
```

**L194**
```typescript
    expect(
```

**L195**
```typescript
      engagementSchema.safeParse({ name: 'X', probabilityPct: 150 }).success,
```

**L196**
```typescript
    ).toBe(false);
```

**L197**
```typescript
  });
```

**L198**
```typescript

```

**L199**
```typescript
  it('rejects non-integer probability', () => {
```

**L200**
```typescript
    expect(
```

**L201**
```typescript
      engagementSchema.safeParse({ name: 'X', probabilityPct: 50.5 }).success,
```

**L202**
```typescript
    ).toBe(false);
```

**L203**
```typescript
  });
```

**L204**
```typescript

```

**L205**
```typescript
  it('rejects 2-letter currency', () => {
```

**L206**
```typescript
    expect(
```

**L207**
```typescript
      engagementSchema.safeParse({ name: 'X', valueCurrency: 'KR' }).success,
```

**L208**
```typescript
    ).toBe(false);
```

**L209**
```typescript
  });
```

**L210**
```typescript
});
```

**L211**
```typescript

```

**L212**
```typescript
describe('Task action schemas', () => {
```

**L213**
```typescript
  const taskSchema = z.object({
```

**L214**
```typescript
    title: z.string().min(1).max(500),
```

**L215**
```typescript
    priority: z.enum(['low', 'medium', 'high', 'urgent']).default('medium'),
```

**L216**
```typescript
  });
```

**L217**
```typescript

```

**L218**
```typescript
  it('accepts each valid priority', () => {
```

**L219**
```typescript
    for (const p of ['low', 'medium', 'high', 'urgent']) {
```

**L220**
```typescript
      expect(taskSchema.safeParse({ title: 'T', priority: p }).success).toBe(true);
```

**L221**
```typescript
    }
```

**L222**
```typescript
  });
```

**L223**
```typescript

```

**L224**
```typescript
  it('rejects unknown priority', () => {
```

**L225**
```typescript
    expect(taskSchema.safeParse({ title: 'T', priority: 'critical' }).success).toBe(
```

**L226**
```typescript
      false,
```

**L227**
```typescript
    );
```

**L228**
```typescript
  });
```

**L229**
```typescript

```

**L230**
```typescript
  it('rejects title > 500 chars', () => {
```

**L231**
```typescript
    expect(taskSchema.safeParse({ title: 'x'.repeat(501) }).success).toBe(false);
```

**L232**
```typescript
  });
```

**L233**
```typescript
});
```

**L234**
```typescript

```

**L235**
```typescript
describe('Contact action schemas', () => {
```

**L236**
```typescript
  const contactSchema = z.object({
```

**L237**
```typescript
    fullName: z.string().min(1).max(160),
```

**L238**
```typescript
    email: z
```

**L239**
```typescript
      .string()
```

**L240**
```typescript
      .email()
```

**L241**
```typescript
      .max(255)
```

**L242**
```typescript
      .optional()
```

**L243**
```typescript
      .or(z.literal('').transform(() => undefined)),
```

**L244**
```typescript
    decisionRole: z
```

**L245**
```typescript
      .enum(['decision_maker', 'influencer', 'gatekeeper', 'user', 'champion', 'unknown'])
```

**L246**
```typescript
      .default('unknown'),
```

**L247**
```typescript
    preferredLanguage: z
```

**L248**
```typescript
      .enum(['ko', 'en', 'ja', 'zh-CN'])
```

**L249**
```typescript
      .optional()
```

**L250**
```typescript
      .or(z.literal('').transform(() => undefined)),
```

**L251**
```typescript
  });
```

**L252**
```typescript

```

**L253**
```typescript
  it('accepts valid', () => {
```

**L254**
```typescript
    expect(contactSchema.safeParse({ fullName: 'John Doe' }).success).toBe(true);
```

**L255**
```typescript
  });
```

**L256**
```typescript

```

**L257**
```typescript
  it('decisionRole defaults to unknown', () => {
```

**L258**
```typescript
    const r = contactSchema.safeParse({ fullName: 'X' });
```

**L259**
```typescript
    if (r.success) expect(r.data.decisionRole).toBe('unknown');
```

**L260**
```typescript
  });
```

**L261**
```typescript

```

**L262**
```typescript
  it('accepts ko/en/ja/zh-CN languages', () => {
```

**L263**
```typescript
    for (const lang of ['ko', 'en', 'ja', 'zh-CN']) {
```

**L264**
```typescript
      expect(
```

**L265**
```typescript
        contactSchema.safeParse({ fullName: 'X', preferredLanguage: lang }).success,
```

**L266**
```typescript
      ).toBe(true);
```

**L267**
```typescript
    }
```

**L268**
```typescript
  });
```

**L269**
```typescript

```

**L270**
```typescript
  it('rejects unknown language', () => {
```

**L271**
```typescript
    expect(
```

**L272**
```typescript
      contactSchema.safeParse({ fullName: 'X', preferredLanguage: 'es' }).success,
```

**L273**
```typescript
    ).toBe(false);
```

**L274**
```typescript
  });
```

**L275**
```typescript
});
```

### `src\__tests__\step4\i18n-completeness.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * tests/i18n-completeness.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * 3개 언어 (ko/en/ja) 파일이 동일한 key 집합을 가지는지 검증.
```

**L5**
```typescript
 * Phase 1은 100% 동기화가 목표 (Q10 결정).
```

**L6**
```typescript
 */
```

**L7**
```typescript

```

**L8**
```typescript
import { describe, it, expect } from 'vitest';
```

**L9**
```typescript
import koMessages from '@/i18n/messages/ko.json';
```

**L10**
```typescript
import enMessages from '@/i18n/messages/en.json';
```

**L11**
```typescript
import jaMessages from '@/i18n/messages/ja.json';
```

**L12**
```typescript

```

**L13**
```typescript
type MessageObject = { [key: string]: string | MessageObject };
```

**L14**
```typescript

```

**L15**
```typescript
function flattenKeys(obj: MessageObject, prefix = ''): Set<string> {
```

**L16**
```typescript
  const keys = new Set<string>();
```

**L17**
```typescript
  for (const [k, v] of Object.entries(obj)) {
```

**L18**
```typescript
    const path = prefix ? `${prefix}.${k}` : k;
```

**L19**
```typescript
    if (typeof v === 'string') {
```

**L20**
```typescript
      keys.add(path);
```

**L21**
```typescript
    } else if (v && typeof v === 'object') {
```

**L22**
```typescript
      for (const sub of flattenKeys(v, path)) {
```

**L23**
```typescript
        keys.add(sub);
```

**L24**
```typescript
      }
```

**L25**
```typescript
    }
```

**L26**
```typescript
  }
```

**L27**
```typescript
  return keys;
```

**L28**
```typescript
}
```

**L29**
```typescript

```

**L30**
```typescript
describe('i18n completeness', () => {
```

**L31**
```typescript
  const koKeys = flattenKeys(koMessages as unknown as MessageObject);
```

**L32**
```typescript
  const enKeys = flattenKeys(enMessages as unknown as MessageObject);
```

**L33**
```typescript
  const jaKeys = flattenKeys(jaMessages as unknown as MessageObject);
```

**L34**
```typescript

```

**L35**
```typescript
  it('all three locales have the same number of keys', () => {
```

**L36**
```typescript
    expect(enKeys.size).toBe(koKeys.size);
```

**L37**
```typescript
    expect(jaKeys.size).toBe(koKeys.size);
```

**L38**
```typescript
  });
```

**L39**
```typescript

```

**L40**
```typescript
  it('ko has no key missing in en', () => {
```

**L41**
```typescript
    const missing = [...koKeys].filter((k) => !enKeys.has(k));
```

**L42**
```typescript
    expect(missing).toEqual([]);
```

**L43**
```typescript
  });
```

**L44**
```typescript

```

**L45**
```typescript
  it('ko has no key missing in ja', () => {
```

**L46**
```typescript
    const missing = [...koKeys].filter((k) => !jaKeys.has(k));
```

**L47**
```typescript
    expect(missing).toEqual([]);
```

**L48**
```typescript
  });
```

**L49**
```typescript

```

**L50**
```typescript
  it('en has no key missing in ko', () => {
```

**L51**
```typescript
    const missing = [...enKeys].filter((k) => !koKeys.has(k));
```

**L52**
```typescript
    expect(missing).toEqual([]);
```

**L53**
```typescript
  });
```

**L54**
```typescript

```

**L55**
```typescript
  it('ja has no key missing in ko', () => {
```

**L56**
```typescript
    const missing = [...jaKeys].filter((k) => !koKeys.has(k));
```

**L57**
```typescript
    expect(missing).toEqual([]);
```

**L58**
```typescript
  });
```

**L59**
```typescript

```

**L60**
```typescript
  it('all values are non-empty strings', () => {
```

**L61**
```typescript
    function checkValues(obj: MessageObject, lang: string, path = ''): string[] {
```

**L62**
```typescript
      const empties: string[] = [];
```

**L63**
```typescript
      for (const [k, v] of Object.entries(obj)) {
```

**L64**
```typescript
        const p = path ? `${path}.${k}` : k;
```

**L65**
```typescript
        if (typeof v === 'string') {
```

**L66**
```typescript
          if (v.trim().length === 0) empties.push(`${lang}: ${p}`);
```

**L67**
```typescript
        } else if (v && typeof v === 'object') {
```

**L68**
```typescript
          empties.push(...checkValues(v, lang, p));
```

**L69**
```typescript
        }
```

**L70**
```typescript
      }
```

**L71**
```typescript
      return empties;
```

**L72**
```typescript
    }
```

**L73**
```typescript
    expect([
```

**L74**
```typescript
      ...checkValues(koMessages as unknown as MessageObject, 'ko'),
```

**L75**
```typescript
      ...checkValues(enMessages as unknown as MessageObject, 'en'),
```

**L76**
```typescript
      ...checkValues(jaMessages as unknown as MessageObject, 'ja'),
```

**L77**
```typescript
    ]).toEqual([]);
```

**L78**
```typescript
  });
```

**L79**
```typescript

```

**L80**
```typescript
  it('all three locales have core namespaces present', () => {
```

**L81**
```typescript
    const requiredNamespaces = [
```

**L82**
```typescript
      'common',
```

**L83**
```typescript
      'nav',
```

**L84**
```typescript
      'modules',
```

**L85**
```typescript
      'drafts',
```

**L86**
```typescript
      'inbox',
```

**L87**
```typescript
      'partyDetail',
```

**L88**
```typescript
      'engagements',
```

**L89**
```typescript
      'tasks',
```

**L90**
```typescript
      'settings',
```

**L91**
```typescript
      'realtime',
```

**L92**
```typescript
      'partyForm',
```

**L93**
```typescript
      'engagementForm',
```

**L94**
```typescript
      'contactForm',
```

**L95**
```typescript
      'taskForm',
```

**L96**
```typescript
      'compose',
```

**L97**
```typescript
    ];
```

**L98**
```typescript
    for (const ns of requiredNamespaces) {
```

**L99**
```typescript
      expect(
```

**L100**
```typescript
        [...koKeys].some((k) => k.startsWith(`${ns}.`)),
```

**L101**
```typescript
        `ko missing namespace: ${ns}`,
```

**L102**
```typescript
      ).toBe(true);
```

**L103**
```typescript
      expect(
```

**L104**
```typescript
        [...enKeys].some((k) => k.startsWith(`${ns}.`)),
```

**L105**
```typescript
        `en missing namespace: ${ns}`,
```

**L106**
```typescript
      ).toBe(true);
```

**L107**
```typescript
      expect(
```

**L108**
```typescript
        [...jaKeys].some((k) => k.startsWith(`${ns}.`)),
```

**L109**
```typescript
        `ja missing namespace: ${ns}`,
```

**L110**
```typescript
      ).toBe(true);
```

**L111**
```typescript
    }
```

**L112**
```typescript
  });
```

**L113**
```typescript
});
```

### `src\__tests__\step4\url-parsers.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * tests/url-parsers.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * URL searchParams → filter 객체로 변환하는 파서들의 단위 테스트.
```

**L5**
```typescript
 * 이들은 server-only 모듈에서 import — 'server-only' 폴리필 필요.
```

**L6**
```typescript
 */
```

**L7**
```typescript

```

**L8**
```typescript
import { describe, it, expect, vi } from 'vitest';
```

**L9**
```typescript

```

**L10**
```typescript
// server-only 폴리필 — Vitest 환경에서 import 가능하게
```

**L11**
```typescript
vi.mock('server-only', () => ({}));
```

**L12**
```typescript

```

**L13**
```typescript
// supabase server client mock — 파서는 client 사용 안 함
```

**L14**
```typescript
vi.mock('@/lib/supabase/server', () => ({
```

**L15**
```typescript
  createSupabaseServerClient: vi.fn(),
```

**L16**
```typescript
}));
```

**L17**
```typescript

```

**L18**
```typescript
import {
```

**L19**
```typescript
  parseInboxFilters,
```

**L20**
```typescript
  parseInboxPagination,
```

**L21**
```typescript
} from '@/lib/queries/inbox';
```

**L22**
```typescript
import {
```

**L23**
```typescript
  parseTaskFilters,
```

**L24**
```typescript
  parseTaskSort,
```

**L25**
```typescript
  parseTaskPagination,
```

**L26**
```typescript
} from '@/lib/queries/tasks';
```

**L27**
```typescript

```

**L28**
```typescript
describe('parseInboxFilters', () => {
```

**L29**
```typescript
  it('defaults all filters to "all" / empty / false', () => {
```

**L30**
```typescript
    const filters = parseInboxFilters({});
```

**L31**
```typescript
    expect(filters).toEqual({
```

**L32**
```typescript
      channel: 'all',
```

**L33**
```typescript
      direction: 'all',
```

**L34**
```typescript
      query: '',
```

**L35**
```typescript
      hasDraft: false,
```

**L36**
```typescript
      partyId: null,
```

**L37**
```typescript
    });
```

**L38**
```typescript
  });
```

**L39**
```typescript

```

**L40**
```typescript
  it('parses valid channel + direction', () => {
```

**L41**
```typescript
    const filters = parseInboxFilters({
```

**L42**
```typescript
      channel: 'email',
```

**L43**
```typescript
      direction: 'inbound',
```

**L44**
```typescript
    });
```

**L45**
```typescript
    expect(filters.channel).toBe('email');
```

**L46**
```typescript
    expect(filters.direction).toBe('inbound');
```

**L47**
```typescript
  });
```

**L48**
```typescript

```

**L49**
```typescript
  it('rejects unknown channel — falls back to "all"', () => {
```

**L50**
```typescript
    const filters = parseInboxFilters({ channel: 'pigeon' });
```

**L51**
```typescript
    expect(filters.channel).toBe('all');
```

**L52**
```typescript
  });
```

**L53**
```typescript

```

**L54**
```typescript
  it('parses hasDraft=1 as true', () => {
```

**L55**
```typescript
    expect(parseInboxFilters({ hasDraft: '1' }).hasDraft).toBe(true);
```

**L56**
```typescript
    expect(parseInboxFilters({ hasDraft: '0' }).hasDraft).toBe(false);
```

**L57**
```typescript
    expect(parseInboxFilters({}).hasDraft).toBe(false);
```

**L58**
```typescript
  });
```

**L59**
```typescript

```

**L60**
```typescript
  it('parses valid UUID party — rejects non-UUID', () => {
```

**L61**
```typescript
    const validUuid = '12345678-1234-1234-1234-123456789012';
```

**L62**
```typescript
    expect(parseInboxFilters({ party: validUuid }).partyId).toBe(validUuid);
```

**L63**
```typescript
    expect(parseInboxFilters({ party: 'not-a-uuid' }).partyId).toBeNull();
```

**L64**
```typescript
  });
```

**L65**
```typescript

```

**L66**
```typescript
  it('trims query string', () => {
```

**L67**
```typescript
    expect(parseInboxFilters({ q: '  hello  ' }).query).toBe('hello');
```

**L68**
```typescript
  });
```

**L69**
```typescript

```

**L70**
```typescript
  it('handles array searchParam (takes first)', () => {
```

**L71**
```typescript
    expect(parseInboxFilters({ channel: ['email', 'slack'] }).channel).toBe('email');
```

**L72**
```typescript
  });
```

**L73**
```typescript
});
```

**L74**
```typescript

```

**L75**
```typescript
describe('parseInboxPagination', () => {
```

**L76**
```typescript
  it('defaults to page=1, size=25', () => {
```

**L77**
```typescript
    expect(parseInboxPagination({})).toEqual({ page: 1, pageSize: 25 });
```

**L78**
```typescript
  });
```

**L79**
```typescript

```

**L80**
```typescript
  it('parses valid page', () => {
```

**L81**
```typescript
    expect(parseInboxPagination({ page: '3' }).page).toBe(3);
```

**L82**
```typescript
  });
```

**L83**
```typescript

```

**L84**
```typescript
  it('rejects negative/zero page', () => {
```

**L85**
```typescript
    expect(parseInboxPagination({ page: '0' }).page).toBe(1);
```

**L86**
```typescript
    expect(parseInboxPagination({ page: '-5' }).page).toBe(1);
```

**L87**
```typescript
  });
```

**L88**
```typescript

```

**L89**
```typescript
  it('rejects non-numeric page', () => {
```

**L90**
```typescript
    expect(parseInboxPagination({ page: 'abc' }).page).toBe(1);
```

**L91**
```typescript
  });
```

**L92**
```typescript

```

**L93**
```typescript
  it('accepts valid pageSize from allowed options', () => {
```

**L94**
```typescript
    expect(parseInboxPagination({ size: '50' }).pageSize).toBe(50);
```

**L95**
```typescript
    expect(parseInboxPagination({ size: '100' }).pageSize).toBe(100);
```

**L96**
```typescript
  });
```

**L97**
```typescript

```

**L98**
```typescript
  it('rejects invalid pageSize — falls to default 25', () => {
```

**L99**
```typescript
    expect(parseInboxPagination({ size: '37' }).pageSize).toBe(25);
```

**L100**
```typescript
    expect(parseInboxPagination({ size: '999' }).pageSize).toBe(25);
```

**L101**
```typescript
  });
```

**L102**
```typescript
});
```

**L103**
```typescript

```

**L104**
```typescript
describe('parseTaskFilters', () => {
```

**L105**
```typescript
  it('defaults status to "open"', () => {
```

**L106**
```typescript
    expect(parseTaskFilters({}).status).toBe('open');
```

**L107**
```typescript
  });
```

**L108**
```typescript

```

**L109**
```typescript
  it('accepts each valid TaskStatus', () => {
```

**L110**
```typescript
    for (const s of ['todo', 'in_progress', 'blocked', 'done', 'cancelled']) {
```

**L111**
```typescript
      expect(parseTaskFilters({ status: s }).status).toBe(s);
```

**L112**
```typescript
    }
```

**L113**
```typescript
    expect(parseTaskFilters({ status: 'all' }).status).toBe('all');
```

**L114**
```typescript
    expect(parseTaskFilters({ status: 'open' }).status).toBe('open');
```

**L115**
```typescript
  });
```

**L116**
```typescript

```

**L117**
```typescript
  it('overdueOnly=1 → true', () => {
```

**L118**
```typescript
    expect(parseTaskFilters({ overdue: '1' }).overdueOnly).toBe(true);
```

**L119**
```typescript
    expect(parseTaskFilters({ overdue: 'true' }).overdueOnly).toBe(false); // 정확히 '1'만
```

**L120**
```typescript
  });
```

**L121**
```typescript

```

**L122**
```typescript
  it('defaults sort to "due_soonest"', () => {
```

**L123**
```typescript
    expect(parseTaskSort({})).toBe('due_soonest');
```

**L124**
```typescript
  });
```

**L125**
```typescript

```

**L126**
```typescript
  it('accepts valid sort values', () => {
```

**L127**
```typescript
    expect(parseTaskSort({ sort: 'priority' })).toBe('priority');
```

**L128**
```typescript
    expect(parseTaskSort({ sort: 'newest' })).toBe('newest');
```

**L129**
```typescript
  });
```

**L130**
```typescript

```

**L131**
```typescript
  it('rejects unknown sort — falls to default', () => {
```

**L132**
```typescript
    expect(parseTaskSort({ sort: 'random' })).toBe('due_soonest');
```

**L133**
```typescript
  });
```

**L134**
```typescript

```

**L135**
```typescript
  it('parseTaskPagination behaves like inbox', () => {
```

**L136**
```typescript
    expect(parseTaskPagination({}).pageSize).toBe(25);
```

**L137**
```typescript
    expect(parseTaskPagination({ size: '50' }).pageSize).toBe(50);
```

**L138**
```typescript
  });
```

**L139**
```typescript
});
```

### `src\__tests__\workers\consultation-worker.test.ts`

**L1**
```typescript
/**
```

**L2**
```typescript
 * __tests__/workers/consultation-worker.test.ts
```

**L3**
```typescript
 *
```

**L4**
```typescript
 * processConsultation의 핵심 로직 검증:
```

**L5**
```typescript
 *   1. 정상 흐름 — strategy + 3개 액션 (immediate/short/long), immediate은 task 생성
```

**L6**
```typescript
 *   2. ai_processing_status='completed'인 consultation은 skip (멱등)
```

**L7**
```typescript
 *   3. consultation 미존재 → status='failed'
```

**L8**
```typescript
 *   4. ClaudeBudgetExceededError → ai_processing_retryable=false
```

**L9**
```typescript
 *   5. ClaudeApiError 5xx → ai_processing_retryable=true
```

**L10**
```typescript
 *   6. strategy_advisor가 invalid JSON 반환 → 실패 처리
```

**L11**
```typescript
 */
```

**L12**
```typescript

```

**L13**
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

**L14**
```typescript
import {
```

**L15**
```typescript
  processConsultation,
```

**L16**
```typescript
  type ConsultationNotification,
```

**L17**
```typescript
} from '../../workers/consultation-worker';
```

**L18**
```typescript
import {
```

**L19**
```typescript
  ClaudeApiError,
```

**L20**
```typescript
  ClaudeBudgetExceededError,
```

**L21**
```typescript
} from '../../lib/ai/claude-client';
```

**L22**
```typescript
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
```

**L23**
```typescript
import type {
```

**L24**
```typescript
  ClaudeCompleteInput,
```

**L25**
```typescript
  ClaudeCompleteOutput,
```

**L26**
```typescript
} from '../../types/ai';
```

**L27**
```typescript

```

**L28**
```typescript
const orgId = 'org-1';
```

**L29**
```typescript
const consultationId = 'consult-1';
```

**L30**
```typescript

```

**L31**
```typescript
interface MockClaudeOpts {
```

**L32**
```typescript
  parsedJson?: object;
```

**L33**
```typescript
  throwError?: Error;
```

**L34**
```typescript
}
```

**L35**
```typescript

```

**L36**
```typescript
function buildMockClaude(opts: MockClaudeOpts): {
```

**L37**
```typescript
  complete: ReturnType<typeof vi.fn>;
```

**L38**
```typescript
} {
```

**L39**
```typescript
  const complete = vi.fn(async (_input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> => {
```

**L40**
```typescript
    if (opts.throwError) throw opts.throwError;
```

**L41**
```typescript
    return {
```

**L42**
```typescript
      content: opts.parsedJson ? JSON.stringify(opts.parsedJson) : '',
```

**L43**
```typescript
      parsedJson: opts.parsedJson,
```

**L44**
```typescript
      runId: 'run-strat-1',
```

**L45**
```typescript
      agentId: 'agent-strategy-advisor-1',
```

**L46**
```typescript
      model: 'claude-opus-4-7',
```

**L47**
```typescript
      latencyMs: 4000,
```

**L48**
```typescript
      tokensIn: 1000,
```

**L49**
```typescript
      tokensOut: 800,
```

**L50**
```typescript
      costUsd: 0.075,
```

**L51**
```typescript
    };
```

**L52**
```typescript
  });
```

**L53**
```typescript
  return { complete };
```

**L54**
```typescript
}
```

**L55**
```typescript

```

**L56**
```typescript
const validStrategy = {
```

**L57**
```typescript
  situation_analysis: 'Investor showing strong interest after demo',
```

**L58**
```typescript
  key_signals: ['quick reply', 'follow-up questions'],
```

**L59**
```typescript
  recommended_approach: 'Send updated deck and propose call',
```

**L60**
```typescript
  key_messages: ['traction', 'team', 'roadmap'],
```

**L61**
```typescript
  risks_to_avoid: ['premature valuation discussion'],
```

**L62**
```typescript
  questions_to_ask_internally: ['confirm investor mandate'],
```

**L63**
```typescript
  confidence_score: 0.85,
```

**L64**
```typescript
  requires_human_review: true,
```

**L65**
```typescript
  requires_legal_review: false,
```

**L66**
```typescript
  requires_finance_review: false,
```

**L67**
```typescript
  actions: [
```

**L68**
```typescript
    {
```

**L69**
```typescript
      title: 'Reply with updated deck',
```

**L70**
```typescript
      description: 'Send v3 deck and propose 30-min call',
```

**L71**
```typescript
      action_type: 'immediate',
```

**L72**
```typescript
      priority: 'high',
```

**L73**
```typescript
      suggested_due_in_hours: 24,
```

**L74**
```typescript
      sort_order: 1,
```

**L75**
```typescript
    },
```

**L76**
```typescript
    {
```

**L77**
```typescript
      title: 'Prepare data room',
```

**L78**
```typescript
      description: 'Organize financials and metrics',
```

**L79**
```typescript
      action_type: 'short_term',
```

**L80**
```typescript
      priority: 'medium',
```

**L81**
```typescript
      suggested_due_in_days: 7,
```

**L82**
```typescript
      sort_order: 2,
```

**L83**
```typescript
    },
```

**L84**
```typescript
    {
```

**L85**
```typescript
      title: 'Schedule board update',
```

**L86**
```typescript
      description: 'Brief board on funding pipeline',
```

**L87**
```typescript
      action_type: 'long_term',
```

**L88**
```typescript
      priority: 'low',
```

**L89**
```typescript
      suggested_due_in_days: 30,
```

**L90**
```typescript
      sort_order: 3,
```

**L91**
```typescript
    },
```

**L92**
```typescript
  ],
```

**L93**
```typescript
};
```

**L94**
```typescript

```

**L95**
```typescript
const consultationRow = {
```

**L96**
```typescript
  id: consultationId,
```

**L97**
```typescript
  organization_id: orgId,
```

**L98**
```typescript
  party_id: 'party-1',
```

**L99**
```typescript
  engagement_id: 'eng-1',
```

**L100**
```typescript
  module: 'investor',
```

**L101**
```typescript
  content_raw: '안녕하세요, 데모 잘 봤습니다…',
```

**L102**
```typescript
  content_processed: '안녕하세요, 데모 잘 봤습니다… [요약]',
```

**L103**
```typescript
  language: 'ko',
```

**L104**
```typescript
  priority: 'high',
```

**L105**
```typescript
  urgency: 'high',
```

**L106**
```typescript
  ai_processing_status: 'pending',
```

**L107**
```typescript
};
```

**L108**
```typescript

```

**L109**
```typescript
function makeBaseNotification(): ConsultationNotification {
```

**L110**
```typescript
  return {
```

**L111**
```typescript
    consultation_id: consultationId,
```

**L112**
```typescript
    organization_id: orgId,
```

**L113**
```typescript
    module: 'investor',
```

**L114**
```typescript
    priority: 'high',
```

**L115**
```typescript
    urgency: 'high',
```

**L116**
```typescript
  };
```

**L117**
```typescript
}
```

**L118**
```typescript

```

**L119**
```typescript
function buildSupabase(consultationData: object | null = consultationRow): MockSupabase {
```

**L120**
```typescript
  return buildSupabaseMock({
```

**L121**
```typescript
    'app.consultations': {
```

**L122**
```typescript
      selectMaybeSingle: { data: consultationData },
```

**L123**
```typescript
      updateResult: { error: null },
```

**L124**
```typescript
    },
```

**L125**
```typescript
    'app.response_strategies': {
```

**L126**
```typescript
      insertSingle: { data: { id: 'strategy-1' } },
```

**L127**
```typescript
    },
```

**L128**
```typescript
    'app.strategy_actions': {
```

**L129**
```typescript
      insertSingle: { data: { id: 'action-1' } },
```

**L130**
```typescript
      updateResult: { error: null },
```

**L131**
```typescript
    },
```

**L132**
```typescript
    'app.tasks': {
```

**L133**
```typescript
      insertSingle: { data: { id: 'task-1' } },
```

**L134**
```typescript
    },
```

**L135**
```typescript
  });
```

**L136**
```typescript
}
```

**L137**
```typescript

```

**L138**
```typescript
describe('processConsultation — happy path', () => {
```

**L139**
```typescript
  let supabase: MockSupabase;
```

**L140**
```typescript

```

**L141**
```typescript
  beforeEach(() => {
```

**L142**
```typescript
    supabase = buildSupabase();
```

**L143**
```typescript
  });
```

**L144**
```typescript

```

**L145**
```typescript
  it('runs strategy_advisor and inserts response_strategies + actions + tasks', async () => {
```

**L146**
```typescript
    const claude = buildMockClaude({ parsedJson: validStrategy });
```

**L147**
```typescript
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
```

**L148**
```typescript
      claudeClient: claude as never,
```

**L149**
```typescript
      nowProvider: () => new Date('2026-04-01T10:00:00Z'),
```

**L150**
```typescript
    });
```

**L151**
```typescript

```

**L152**
```typescript
    expect(result.status).toBe('completed');
```

**L153**
```typescript
    expect(result.strategyId).toBe('strategy-1');
```

**L154**
```typescript
    expect(result.actionsCreated).toBe(3); // 3 actions
```

**L155**
```typescript
    expect(result.tasksCreated).toBe(1); // 1 immediate
```

**L156**
```typescript

```

**L157**
```typescript
    // claude는 strategy_advisor 1회 호출
```

**L158**
```typescript
    expect(claude.complete).toHaveBeenCalledTimes(1);
```

**L159**
```typescript
    expect(claude.complete.mock.calls[0]?.[0]?.agentRole).toBe('strategy_advisor');
```

**L160**
```typescript
    expect(claude.complete.mock.calls[0]?.[0]?.outputFormat).toBe('json');
```

**L161**
```typescript

```

**L162**
```typescript
    // response_strategies INSERT 검증
```

**L163**
```typescript
    const strategyInserts = supabase.__calls.insert.filter(
```

**L164**
```typescript
      (c) => c.schema === 'app' && c.table === 'response_strategies',
```

**L165**
```typescript
    );
```

**L166**
```typescript
    expect(strategyInserts).toHaveLength(1);
```

**L167**
```typescript
    const strategyPayload = strategyInserts[0]?.payload as Record<string, unknown>;
```

**L168**
```typescript
    expect(strategyPayload.consultation_id).toBe(consultationId);
```

**L169**
```typescript
    expect(strategyPayload.run_id).toBe('run-strat-1');
```

**L170**
```typescript
    expect(strategyPayload.confidence_score).toBe(0.85);
```

**L171**
```typescript
    expect(strategyPayload.ai_generated).toBe(true);
```

**L172**
```typescript
    expect(strategyPayload.status).toBe('draft');
```

**L173**
```typescript

```

**L174**
```typescript
    // strategy_actions 3건 INSERT
```

**L175**
```typescript
    const actionInserts = supabase.__calls.insert.filter(
```

**L176**
```typescript
      (c) => c.schema === 'app' && c.table === 'strategy_actions',
```

**L177**
```typescript
    );
```

**L178**
```typescript
    expect(actionInserts).toHaveLength(3);
```

**L179**
```typescript

```

**L180**
```typescript
    // tasks 1건 INSERT (immediate만)
```

**L181**
```typescript
    const taskInserts = supabase.__calls.insert.filter(
```

**L182**
```typescript
      (c) => c.schema === 'app' && c.table === 'tasks',
```

**L183**
```typescript
    );
```

**L184**
```typescript
    expect(taskInserts).toHaveLength(1);
```

**L185**
```typescript
    const taskPayload = taskInserts[0]?.payload as Record<string, unknown>;
```

**L186**
```typescript
    expect(taskPayload.title).toBe('Reply with updated deck');
```

**L187**
```typescript
    expect(taskPayload.status).toBe('todo');
```

**L188**
```typescript
    expect(taskPayload.party_id).toBe('party-1');
```

**L189**
```typescript
    expect(taskPayload.engagement_id).toBe('eng-1');
```

**L190**
```typescript
    expect(taskPayload.linked_strategy_action_id).toBe('action-1');
```

**L191**
```typescript

```

**L192**
```typescript
    // due_at 24시간 후
```

**L193**
```typescript
    expect(taskPayload.due_at).toBe('2026-04-02T10:00:00.000Z');
```

**L194**
```typescript

```

**L195**
```typescript
    // strategy_actions UPDATE (linked_task_id back-link) 1건 이상
```

**L196**
```typescript
    const actionUpdates = supabase.__calls.update.filter(
```

**L197**
```typescript
      (c) => c.schema === 'app' && c.table === 'strategy_actions',
```

**L198**
```typescript
    );
```

**L199**
```typescript
    expect(actionUpdates.length).toBeGreaterThanOrEqual(1);
```

**L200**
```typescript
  });
```

**L201**
```typescript

```

**L202**
```typescript
  it('does not create task when due_in_hours is missing', async () => {
```

**L203**
```typescript
    const supa = buildSupabase();
```

**L204**
```typescript
    const strategyNoHours = {
```

**L205**
```typescript
      ...validStrategy,
```

**L206**
```typescript
      actions: [
```

**L207**
```typescript
        {
```

**L208**
```typescript
          title: 'Immediate without due',
```

**L209**
```typescript
          description: 'x',
```

**L210**
```typescript
          action_type: 'immediate',
```

**L211**
```typescript
          // suggested_due_in_hours 없음
```

**L212**
```typescript
        },
```

**L213**
```typescript
      ],
```

**L214**
```typescript
    };
```

**L215**
```typescript
    const claude = buildMockClaude({ parsedJson: strategyNoHours });
```

**L216**
```typescript
    const result = await processConsultation(supa as never, makeBaseNotification(), {
```

**L217**
```typescript
      claudeClient: claude as never,
```

**L218**
```typescript
    });
```

**L219**
```typescript
    expect(result.tasksCreated).toBe(1);
```

**L220**
```typescript
    const tasks = supa.__calls.insert.filter((c) => c.table === 'tasks');
```

**L221**
```typescript
    expect((tasks[0]?.payload as Record<string, unknown>).due_at).toBeNull();
```

**L222**
```typescript
  });
```

**L223**
```typescript
});
```

**L224**
```typescript

```

**L225**
```typescript
describe('processConsultation — idempotency', () => {
```

**L226**
```typescript
  it('skips when ai_processing_status is already completed', async () => {
```

**L227**
```typescript
    const supabase = buildSupabase({
```

**L228**
```typescript
      ...consultationRow,
```

**L229**
```typescript
      ai_processing_status: 'completed',
```

**L230**
```typescript
    });
```

**L231**
```typescript
    const claude = buildMockClaude({ parsedJson: validStrategy });
```

**L232**
```typescript

```

**L233**
```typescript
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
```

**L234**
```typescript
      claudeClient: claude as never,
```

**L235**
```typescript
    });
```

**L236**
```typescript

```

**L237**
```typescript
    expect(result.status).toBe('completed');
```

**L238**
```typescript
    expect(result.errorMessage).toBe('already_completed');
```

**L239**
```typescript
    // claude는 호출되지 않아야 함
```

**L240**
```typescript
    expect(claude.complete).not.toHaveBeenCalled();
```

**L241**
```typescript
    // response_strategies는 INSERT 안 됨
```

**L242**
```typescript
    const strategyInserts = supabase.__calls.insert.filter(
```

**L243**
```typescript
      (c) => c.table === 'response_strategies',
```

**L244**
```typescript
    );
```

**L245**
```typescript
    expect(strategyInserts).toHaveLength(0);
```

**L246**
```typescript
  });
```

**L247**
```typescript
});
```

**L248**
```typescript

```

**L249**
```typescript
describe('processConsultation — failure paths', () => {
```

**L250**
```typescript
  it('returns failed when consultation does not exist', async () => {
```

**L251**
```typescript
    const supabase = buildSupabase(null);
```

**L252**
```typescript
    const claude = buildMockClaude({ parsedJson: validStrategy });
```

**L253**
```typescript
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
```

**L254**
```typescript
      claudeClient: claude as never,
```

**L255**
```typescript
    });
```

**L256**
```typescript
    expect(result.status).toBe('failed');
```

**L257**
```typescript
    expect(claude.complete).not.toHaveBeenCalled();
```

**L258**
```typescript
  });
```

**L259**
```typescript

```

**L260**
```typescript
  it('marks ai_processing_retryable=false on ClaudeBudgetExceededError', async () => {
```

**L261**
```typescript
    const supabase = buildSupabase();
```

**L262**
```typescript
    const claude = buildMockClaude({
```

**L263**
```typescript
      throwError: new ClaudeBudgetExceededError(60, 50, 'daily'),
```

**L264**
```typescript
    });
```

**L265**
```typescript

```

**L266**
```typescript
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
```

**L267**
```typescript
      claudeClient: claude as never,
```

**L268**
```typescript
    });
```

**L269**
```typescript
    expect(result.status).toBe('failed');
```

**L270**
```typescript

```

**L271**
```typescript
    const updates = supabase.__calls.update.filter(
```

**L272**
```typescript
      (c) => c.schema === 'app' && c.table === 'consultations',
```

**L273**
```typescript
    );
```

**L274**
```typescript
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
```

**L275**
```typescript
    expect(lastUpdate.ai_processing_status).toBe('failed');
```

**L276**
```typescript
    expect(lastUpdate.ai_processing_retryable).toBe(false);
```

**L277**
```typescript
  });
```

**L278**
```typescript

```

**L279**
```typescript
  it('marks ai_processing_retryable=true on transient ClaudeApiError 503', async () => {
```

**L280**
```typescript
    const supabase = buildSupabase();
```

**L281**
```typescript
    const claude = buildMockClaude({
```

**L282**
```typescript
      throwError: new ClaudeApiError('upstream timeout', 503),
```

**L283**
```typescript
    });
```

**L284**
```typescript

```

**L285**
```typescript
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
```

**L286**
```typescript
      claudeClient: claude as never,
```

**L287**
```typescript
    });
```

**L288**
```typescript
    expect(result.status).toBe('failed');
```

**L289**
```typescript

```

**L290**
```typescript
    const updates = supabase.__calls.update.filter(
```

**L291**
```typescript
      (c) => c.schema === 'app' && c.table === 'consultations',
```

**L292**
```typescript
    );
```

**L293**
```typescript
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
```

**L294**
```typescript
    expect(lastUpdate.ai_processing_retryable).toBe(true);
```

**L295**
```typescript
  });
```

**L296**
```typescript

```

**L297**
```typescript
  it('handles invalid strategy JSON', async () => {
```

**L298**
```typescript
    const supabase = buildSupabase();
```

**L299**
```typescript
    const claude = buildMockClaude({ parsedJson: { situation_analysis: 'x' } }); // recommended_approach 누락
```

**L300**
```typescript

```

**L301**
```typescript
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
```

**L302**
```typescript
      claudeClient: claude as never,
```

**L303**
```typescript
    });
```

**L304**
```typescript
    expect(result.status).toBe('failed');
```

**L305**
```typescript
    expect(result.errorMessage).toContain('invalid JSON structure');
```

**L306**
```typescript
  });
```

**L307**
```typescript

```

**L308**
```typescript
  it('continues with remaining actions when one fails', async () => {
```

**L309**
```typescript
    let actionInsertCount = 0;
```

**L310**
```typescript
    const supa = buildSupabaseMock({
```

**L311**
```typescript
      'app.consultations': {
```

**L312**
```typescript
        selectMaybeSingle: { data: consultationRow },
```

**L313**
```typescript
        updateResult: { error: null },
```

**L314**
```typescript
      },
```

**L315**
```typescript
      'app.response_strategies': {
```

**L316**
```typescript
        insertSingle: { data: { id: 'strategy-1' } },
```

**L317**
```typescript
      },
```

**L318**
```typescript
      'app.tasks': {
```

**L319**
```typescript
        insertSingle: { data: { id: 'task-1' } },
```

**L320**
```typescript
      },
```

**L321**
```typescript
    });
```

**L322**
```typescript
    // strategy_actions 첫 INSERT는 실패, 나머지는 성공
```

**L323**
```typescript
    const orig = supa.schema;
```

**L324**
```typescript
    supa.schema = vi.fn((schemaName: string) => ({
```

**L325**
```typescript
      from: (table: string) => {
```

**L326**
```typescript
        const built = orig(schemaName).from(table) as Record<string, unknown>;
```

**L327**
```typescript
        if (table === 'strategy_actions') {
```

**L328**
```typescript
          built.single = vi.fn(() => {
```

**L329**
```typescript
            actionInsertCount += 1;
```

**L330**
```typescript
            if (actionInsertCount === 1) {
```

**L331**
```typescript
              return Promise.resolve({
```

**L332**
```typescript
                data: null,
```

**L333**
```typescript
                error: { message: 'insert failed' },
```

**L334**
```typescript
              });
```

**L335**
```typescript
            }
```

**L336**
```typescript
            return Promise.resolve({ data: { id: `action-${actionInsertCount}` }, error: null });
```

**L337**
```typescript
          });
```

**L338**
```typescript
        }
```

**L339**
```typescript
        return built;
```

**L340**
```typescript
      },
```

**L341**
```typescript
    })) as unknown as typeof supa.schema;
```

**L342**
```typescript

```

**L343**
```typescript
    const claude = buildMockClaude({ parsedJson: validStrategy });
```

**L344**
```typescript
    const result = await processConsultation(supa as never, makeBaseNotification(), {
```

**L345**
```typescript
      claudeClient: claude as never,
```

**L346**
```typescript
    });
```

**L347**
```typescript

```

**L348**
```typescript
    // 3개 중 첫 번째 실패 → 2개만 success
```

**L349**
```typescript
    expect(result.actionsCreated).toBe(2);
```

**L350**
```typescript
    expect(result.status).toBe('completed');
```

**L351**
```typescript
  });
```

**L352**
```typescript
});
```

**L353**
```typescript

```

**L354**
```typescript
describe('processConsultation — fields propagation', () => {
```

**L355**
```typescript
  it('passes language and partyId to Claude correctly', async () => {
```

**L356**
```typescript
    const supabase = buildSupabase({
```

**L357**
```typescript
      ...consultationRow,
```

**L358**
```typescript
      language: 'en',
```

**L359**
```typescript
      party_id: 'party-en-1',
```

**L360**
```typescript
      engagement_id: 'eng-en-1',
```

**L361**
```typescript
    });
```

**L362**
```typescript
    const claude = buildMockClaude({ parsedJson: validStrategy });
```

**L363**
```typescript
    await processConsultation(supabase as never, makeBaseNotification(), {
```

**L364**
```typescript
      claudeClient: claude as never,
```

**L365**
```typescript
    });
```

**L366**
```typescript
    const callInput = claude.complete.mock.calls[0]?.[0] as ClaudeCompleteInput;
```

**L367**
```typescript
    expect(callInput.language).toBe('en');
```

**L368**
```typescript
    expect(callInput.partyId).toBe('party-en-1');
```

**L369**
```typescript
    expect(callInput.engagementId).toBe('eng-en-1');
```

**L370**
```typescript
    expect(callInput.traceLabel).toContain(consultationId);
```

**L371**
```typescript
  });
```

**L372**
```typescript
});
```

