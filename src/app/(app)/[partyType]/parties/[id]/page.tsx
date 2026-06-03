/**
 * app/(app)/[module]/parties/[id]/page.tsx
 *
 * Recent changes:
 *   - 2026-05-17: Phase 21b — PartySequencePanel integrated
 *   - 2026-05-17: Phase 22a — PartyCommunicationsTimeline integrated
 *   - 2026-05-17: Phase 22a fix — parens around ?? / || mix
 *   - 2026-05-26: D6-5c-2b — Industry sections removed (industry schema deleted)
 *   - 2026-06-03: Contacts tab -> 2-panel (PartyContactsPanel) with per-contact
 *                 engagement activity (fetchContactActivities)
 */

import { notFound, redirect } from 'next/navigation';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { fetchPartyMeetings } from '@/lib/queries/meetings';
import {
  getPartyCommunicationsTimeline,
  getPartyCommunicationStats,
  listTemplatesForCompose,
} from '@/lib/queries/communications';
import { fetchContactActivities } from '@/lib/queries/contact-activities';
import { PartyHeader } from '@/components/parties/party-header';
import { PartyStatsGrid } from '@/components/parties/party-stats-grid';
import { PartyContactsPanel } from '@/components/parties/party-contacts-panel';
import { PartyTasksList } from '@/components/parties/party-tasks-list';
import { PartyNotesCard } from '@/components/parties/party-notes-card';
import { PartyMeetingsList } from '@/components/parties/party-meetings-list';
import { ActivityTimeline } from '@/components/parties/activity-timeline';
import { PartySequencePanel } from '@/components/parties/party-sequence-panel';
import { CountryPeersPanel } from '@/components/parties/country-peers-panel';
import { PartyCommunicationsTimeline } from '@/components/parties/party-communications-timeline';
import type { PartyTypeCode } from '@/types/ai';
import { PartySupplyLinksPanel } from '@/components/parties/party-supply-links-panel';
import { PartyDetailTabs } from '@/components/parties/party-detail-tabs';
import { PartyInfoCard } from '@/components/parties/party-info-card';

const PHASE_1_MODULES: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier'
] as const;

interface PageProps {
  params: Promise<{ partyType: string; id: string }>;
}

/**
 * Compute display name from a contact object that may have various field shapes:
 * - { fullName: "..." }
 * - { full_name: "..." }
 * - { given_name: "...", family_name: "..." }
 */
function getContactDisplayName(contact: any): string | null {
  if (!contact) return null;
  if (typeof contact.fullName === 'string' && contact.fullName.trim()) {
    return contact.fullName.trim();
  }
  if (typeof contact.full_name === 'string' && contact.full_name.trim()) {
    return contact.full_name.trim();
  }
  const given = typeof contact.given_name === 'string' ? contact.given_name : '';
  const family = typeof contact.family_name === 'string' ? contact.family_name : '';
  const joined = `${given} ${family}`.trim();
  return joined.length > 0 ? joined : null;
}

export default async function PartyDetailPage({ params }: PageProps) {
  const { partyType: urlModule, id } = await params;

  if (!(PHASE_1_MODULES as readonly string[]).includes(urlModule)) {
    notFound();
  }

  const [full, meetings] = await Promise.all([
    fetchPartyDetail(id),
    fetchPartyMeetings(id),
  ]);

  if (!full) {
    notFound();
  }

  if (full.party.partyType !== urlModule) {
    redirect(`/${full.party.partyType}/parties/${id}`);
  }

  // organization_id: env variable (single-org app)
  const orgId = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID ?? '';
  const partyCountry = full.party.countryCode ?? null;  // DB: country_code

  // ──────────────────────────────────────────────────────────
  // Phase 22a — Communications timeline + stats + templates
  // 2026-06-03 — per-contact engagement activity (for Contacts 2-panel)
  // ──────────────────────────────────────────────────────────
  const [commTimeline, commStats, templates, contactActivities] = await Promise.all([
    getPartyCommunicationsTimeline(full.party.id, 100),
    getPartyCommunicationStats(full.party.id),
    listTemplatesForCompose(orgId, full.party.partyType),
    fetchContactActivities(full.party.id),
  ]);

  // Default contact for "new email" button: first contact with an email
  const contactsArr = full.contacts as any[];
  const defaultContact =
    contactsArr.find((c) => c.email) ?? contactsArr[0] ?? null;

  const defaultContactName: string | null = getContactDisplayName(defaultContact);

  // contacts -> transform into the shape needed by the sequence panel
  const sequenceContacts = full.contacts.map((c: any) => ({
    id:        c.id,
    full_name: c.fullName ?? c.full_name ?? '',
    email:     c.email ?? null,
  }));

  return (
    <div className="flex flex-col h-full">
      <PartyHeader party={full.party} />

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-7xl mx-auto">
          <PartyDetailTabs
            overview={
              <>
                <PartyStatsGrid party={full.party} />
                <PartyInfoCard party={full.party} />
                <PartySupplyLinksPanel
                  partyId={full.party.id}
                  partyType={full.party.partyType as 'filler_supplier' | 'paper_mill'}
                  orgId={orgId}
                />
                {partyCountry && (urlModule === 'paper_mill' || urlModule === 'filler_supplier') && (
                  <CountryPeersPanel
                    partyId={full.party.id}
                    country={partyCountry}
                    currentModule={urlModule as 'paper_mill' | 'filler_supplier'}
                  />
                )}
              </>
            }
            activity={
              <>
                <ActivityTimeline items={full.timeline} />
                <PartyMeetingsList partyId={full.party.id} meetings={meetings as never} />
              </>
            }
            communications={
              <>
                {orgId && (
                  <PartyCommunicationsTimeline
                    partyId={full.party.id}
                    partyName={full.party.name}
                    defaultContactEmail={defaultContact?.email ?? null}
                    defaultContactId={defaultContact?.id ?? null}
                    defaultContactName={defaultContactName}
                    items={commTimeline}
                    stats={commStats}
                    templates={templates}
                    orgId={orgId}
                  />
                )}
                {orgId && (
                  <PartySequencePanel
                    partyId={full.party.id}
                    orgId={orgId}
                    contacts={sequenceContacts}
                  />
                )}
              </>
            }
            contacts={
              <PartyContactsPanel
                contacts={full.contacts}
                partyId={full.party.id}
                activitiesByContact={contactActivities}
              />
            }
            tasks={
              <PartyTasksList
                tasks={full.tasks}
                partyId={full.party.id}
                partyType={full.party.partyType}
              />
            }
            notes={
              <PartyNotesCard notes={full.party.notes} partyId={full.party.id} partyType={full.party.partyType} />
            }
          />
        </div>
      </div>
    </div>
  );
}
