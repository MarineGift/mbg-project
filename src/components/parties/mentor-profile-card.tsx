/**
 * MentorProfileCard — rich mentor profile shown ONLY on mentor party detail pages.
 * Additive: rendered from the generic party detail page behind a
 * `partyType === 'mentor'` guard, so no other party type is affected.
 * Reads app.mentors (extended Greentown mentor-profile format) by party_id.
 */

import type { ReactNode } from 'react';
import { GraduationCap, ExternalLink, Mail } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { createSupabaseServerClient } from '@/lib/supabase/server';

interface Props {
  partyId: string;
}

interface MentorRow {
  full_name: string | null;
  email: string | null;
  title: string | null;
  company: string | null;
  linkedin_url: string | null;
  headshot_url: string | null;
  notes: string | null;
  why_mentor: string | null;
  expertise: string[] | null;
  sector_focus: string[] | null;
  product_types: string[] | null;
  technologies: string[] | null;
  startup_stage_focus: string[] | null;
  availability: string[] | null;
  preferred_engagement: string | null;
  location: string | null;
}

const DASH = <span className="text-muted-foreground">-</span>;

function ChipList({ items, color }: { items: string[] | null | undefined; color: string }) {
  const list = (items ?? []).filter((x) => typeof x === 'string' && x.trim() !== '');
  if (list.length === 0) return DASH;
  return (
    <div className="flex flex-wrap gap-1.5">
      {list.map((x) => (
        <span key={x} className={`inline-flex px-2 py-0.5 text-xs font-medium rounded-full ${color}`}>
          {x}
        </span>
      ))}
    </div>
  );
}

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-[190px_1fr] gap-1 sm:gap-3 py-2.5 border-b border-border/40 last:border-0">
      <div className="text-xs font-medium text-muted-foreground pt-0.5">{label}</div>
      <div className="text-sm break-words min-w-0 leading-relaxed">{children}</div>
    </div>
  );
}

export async function MentorProfileCard({ partyId }: Props) {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .schema('app')
    .from('mentors' as never)
    .select(
      'full_name, email, title, company, linkedin_url, headshot_url, notes, why_mentor, expertise, sector_focus, product_types, technologies, startup_stage_focus, availability, preferred_engagement, location',
    )
    .eq('party_id' as never, partyId)
    .maybeSingle();

  const m = data as unknown as MentorRow | null;
  if (!m) return null;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <GraduationCap className="h-4 w-4 text-emerald-600" />
          Mentor Profile
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0">
        {/* Header: Headshot + Title/Company + LinkedIn/Email */}
        <div className="flex gap-4 mb-4">
          {m.headshot_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={m.headshot_url}
              alt={m.full_name ?? 'Mentor'}
              className="h-24 w-24 rounded-lg object-cover border shrink-0"
            />
          ) : (
            <div className="h-24 w-24 rounded-lg border bg-muted flex items-center justify-center shrink-0">
              <GraduationCap className="h-8 w-8 text-muted-foreground" />
            </div>
          )}
          <div className="min-w-0 flex flex-col gap-1">
            {m.title && <div className="text-sm font-medium leading-snug">{m.title}</div>}
            {m.company && <div className="text-sm text-muted-foreground">{m.company}</div>}
            <div className="flex flex-wrap items-center gap-3 mt-1">
              {m.linkedin_url && (
                <a
                  href={m.linkedin_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 text-xs text-primary hover:underline"
                >
                  <ExternalLink className="h-3.5 w-3.5" /> LinkedIn
                </a>
              )}
              {m.email && (
                <a
                  href={`mailto:${m.email}`}
                  className="inline-flex items-center gap-1 text-xs text-primary hover:underline"
                >
                  <Mail className="h-3.5 w-3.5" /> {m.email}
                </a>
              )}
            </div>
          </div>
        </div>

        <dl>
          <Row label="Mentor Bio">{m.notes ? m.notes : DASH}</Row>
          <Row label="Why I Mentor">{m.why_mentor ? m.why_mentor : DASH}</Row>
          <Row label="Areas of expertise">
            <ChipList items={m.expertise} color="bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300" />
          </Row>
          <Row label="Climatetech Sector">
            <ChipList items={m.sector_focus} color="bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-300" />
          </Row>
          <Row label="Product types">
            <ChipList items={m.product_types} color="bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-300" />
          </Row>
          <Row label="Technologies">
            <ChipList items={m.technologies} color="bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300" />
          </Row>
          <Row label="Startup Stage Focus">
            <ChipList items={m.startup_stage_focus} color="bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-300" />
          </Row>
          <Row label="Availability">
            <ChipList items={m.availability} color="bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300" />
          </Row>
          <Row label="Preferred engagement">{m.preferred_engagement ? m.preferred_engagement : DASH}</Row>
          <Row label="Location">{m.location ? m.location : DASH}</Row>
        </dl>
      </CardContent>
    </Card>
  );
}
