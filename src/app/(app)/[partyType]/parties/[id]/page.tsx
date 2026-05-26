/**
 * app/(app)/[module]/parties/[id]/page.tsx
 *
 * Recent changes:
 *   - 2026-05-17: Phase 21b — PartySequencePanel integrated
 *   - 2026-05-17: Phase 22a — PartyCommunicationsTimeline integrated
 *   - 2026-05-17: Phase 22a fix — parens around ?? / || mix
 */

import { notFound, redirect } from 'next/navigation';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { fetchPartyMeetings } from '@/lib/queries/meetings';
import {
  getPartyCommunicationsTimeline,
  getPartyCommunicationStats,
  listTemplatesForCompose,
} from '@/lib/queries/communications';
import { PartyHeader } from '@/components/parties/party-header';
import { PartyStatsGrid } from '@/components/parties/party-stats-grid';
import { PartyContactsList } from '@/components/parties/party-contacts-list';
import { PartyEngagementsList } from '@/components/parties/party-engagements-list';
import { PartyTasksList } from '@/components/parties/party-tasks-list';
import { PartyNotesCard } from '@/components/parties/party-notes-card';
import { PartyMeetingsList } from '@/components/parties/party-meetings-list';
import { ActivityTimeline } from '@/components/parties/activity-timeline';
import { IndustryPaperSection } from '@/components/parties/industry-paper-section';
import { IndustryFillerSection } from '@/components/parties/industry-filler-section';
import { LinkedMillSection } from '@/components/industry/LinkedMillSection';
import { PartySequencePanel } from '@/components/parties/party-sequence-panel';
import { CountryPeersPanel } from '@/components/parties/country-peers-panel';
import { PartyCommunicationsTimeline } from '@/components/parties/party-communications-timeline';
import type { PartyTypeCode } from '@/types/ai';
import { PartySupplyLinksPanel } from '@/components/parties/party-supply-links-panel';

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

  // organization_id: env 변수 (단일 조직 앱)
  const orgId = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID ?? '';
  const partyCountry = full.party.countryCode ?? null;  // DB: country_code

  // ──────────────────────────────────────────────────────────
  // Phase 22a — Communications timeline + stats + templates
  // ──────────────────────────────────────────────────────────
  const [commTimeline, commStats, templates] = await Promise.all([
    getPartyCommunicationsTimeline(full.party.id, 100),
    getPartyCommunicationStats(full.party.id),
    listTemplatesForCompose(orgId, full.party.partyType),
  ]);

  // Default contact for "new email" button: first contact with an email
  const contactsArr = full.contacts as any[];
  const defaultContact =
    contactsArr.find((c) => c.email) ?? contactsArr[0] ?? null;

  const defaultContactName: string | null = getContactDisplayName(defaultContact);

  // contacts → sequence panel용 shape 변환
  const sequenceContacts = full.contacts.map((c: any) => ({
    id:        c.id,
    full_name: c.fullName ?? c.full_name ?? '',
    email:     c.email ?? null,
  }));

  return (
    <div className="flex flex-col h-full">
      <PartyHeader party={full.party} />

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-7xl mx-auto space-y-6">
          <PartyStatsGrid party={full.party} />

          {full.party.industryPaperCompanyId != null && (
            <IndustryPaperSection
              paperCompanyId={full.party.industryPaperCompanyId}
            />
          )}
          {full.party.industryFillerSupplierId != null && (
            <IndustryFillerSection
              fillerSupplierId={full.party.industryFillerSupplierId}
            />
          )}
          {(full.party as any).industryPaperMillId != null && (
            <LinkedMillSection
              industryPaperMillId={(full.party as any).industryPaperMillId}
            />
          )}

          <div className="grid gap-4 lg:grid-cols-[1.4fr_1fr]">
            <div className="space-y-4">
              <ActivityTimeline items={full.timeline} />

              {/* Phase 22a — Communications Timeline (sent + received, threaded) */}
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

              <PartyNotesCard notes={full.party.notes} />
              <PartyMeetingsList partyId={full.party.id} meetings={meetings as never} />

              {/* Phase 21b — Email Sequences */}
              {orgId && (
                <PartySequencePanel
                  partyId={full.party.id}
                  orgId={orgId}
                  contacts={sequenceContacts}
                />
              )}
            </div>

            <div className="space-y-4">
              <PartySupplyLinksPanel
                partyId={full.party.id}
                partyModule={full.party.partyType as 'filler_supplier' | 'paper_mill'}
                orgId={orgId}
              />
              <PartyContactsList
                contacts={full.contacts}
                partyId={full.party.id}
              />
              <PartyEngagementsList
                engagements={full.engagements}
                partyId={full.party.id}
                partyType={full.party.partyType}
              />
              <PartyTasksList
                tasks={full.tasks}
                partyId={full.party.id}
                partyType={full.party.partyType}
              />
              {partyCountry && (urlModule === 'paper_mill' || urlModule === 'filler_supplier') && (
                <CountryPeersPanel
                  partyId={full.party.id}
                  country={partyCountry}
                  currentModule={urlModule as 'paper_mill' | 'filler_supplier'}
                />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
