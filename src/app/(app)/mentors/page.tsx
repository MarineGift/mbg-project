/**
 * app/(app)/mentors/page.tsx
 * Mentors directory. Reads app.mentors (a standalone table, NOT a party_type),
 * resolving each mentor's affiliating partner name (e.g. Greentown Labs Houston)
 * via a separate app.parties lookup (no FK embed, matching the app's manual-join style).
 */

import Link from 'next/link';
import { ExternalLink, Mail, GraduationCap } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { requireAuthOrRedirect } from '@/lib/auth';
import { Card, CardContent } from '@/components/ui/card';

interface MentorRow {
  id: string;
  full_name: string;
  company: string | null;
  title: string | null;
  email: string | null;
  linkedin_url: string | null;
  expertise: string[] | null;
  notes: string | null;
  partner_id: string | null;
  is_active: boolean | null;
}

export default async function MentorsPage() {
  await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const { data: mentorRows } = await supabase
    .schema('app')
    .from('mentors' as never)
    .select('id, full_name, company, title, email, linkedin_url, expertise, notes, partner_id, is_active')
    .order('full_name' as never, { ascending: true });

  const mentors = (mentorRows ?? []) as unknown as MentorRow[];

  // Resolve affiliating partner names (e.g. "Greentown Labs Houston").
  const partnerIds = [...new Set(mentors.map((m) => m.partner_id).filter(Boolean))] as string[];
  const partnerName: Record<string, string> = {};
  if (partnerIds.length > 0) {
    const { data: pRows } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('id, party_name')
      .in('id' as never, partnerIds);
    for (const r of ((pRows ?? []) as any[])) partnerName[r.id] = r.party_name;
  }

  const total = mentors.length;

  return (
    <div className="px-4 sm:px-6 py-4 sm:py-6 space-y-4 sm:space-y-6 h-full flex flex-col">
      {/* Header */}
      <div className="flex flex-col gap-1.5">
        <h1 className="text-xl sm:text-2xl font-bold flex items-center gap-2">
          <GraduationCap className="h-6 w-6 text-emerald-600" />
          Mentors
        </h1>
        <p className="text-sm text-muted-foreground">{total} mentors</p>
      </div>

      {total === 0 ? (
        <Card className="flex-1">
          <CardContent className="py-16 text-center">
            <p className="text-muted-foreground">No mentors registered yet.</p>
          </CardContent>
        </Card>
      ) : (
        <Card className="flex-1 flex flex-col">
          <div className="overflow-x-auto flex-1">
            <table className="w-full min-w-[640px]">
              <thead className="border-b bg-indigo-50/80 dark:bg-indigo-950/30">
                <tr className="text-left text-xs uppercase tracking-wide font-semibold text-indigo-700/80 dark:text-indigo-300">
                  <th className="px-4 py-3 font-medium whitespace-nowrap">Name</th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden sm:table-cell">Company</th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell">Affiliation</th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Expertise</th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap w-16 text-center">Email</th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap w-16 text-center hidden sm:table-cell">LinkedIn</th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Status</th>
                </tr>
              </thead>
              <tbody>
                {mentors.map((m) => {
                  const expertise = Array.isArray(m.expertise)
                    ? m.expertise.filter((e): e is string => typeof e === 'string' && e.trim() !== '')
                    : [];
                  const affiliation = m.partner_id ? (partnerName[m.partner_id] ?? '-') : '-';
                  return (
                    <tr key={m.id} className="border-b hover:bg-muted/20 transition align-top">
                      <td className="px-4 py-3">
                        <span className="font-medium line-clamp-1">{m.full_name}</span>
                        {m.title && (
                          <div className="text-xs text-muted-foreground mt-0.5">{m.title}</div>
                        )}
                        {/* Mobile fold: company + affiliation */}
                        <div className="mt-1 flex flex-col gap-0.5 text-xs text-muted-foreground sm:hidden">
                          {m.company && <span>{m.company}</span>}
                          {affiliation !== '-' && <span>{affiliation}</span>}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm hidden sm:table-cell whitespace-nowrap text-muted-foreground">
                        {m.company ?? '-'}
                      </td>
                      <td className="px-4 py-3 text-sm hidden md:table-cell whitespace-nowrap">
                        {affiliation !== '-' ? (
                          <span className="inline-flex px-1.5 py-0.5 text-xs font-medium rounded-full whitespace-nowrap bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300">
                            {affiliation}
                          </span>
                        ) : (
                          <span className="text-muted-foreground">-</span>
                        )}
                      </td>
                      <td className="px-4 py-3 hidden lg:table-cell max-w-[360px]">
                        {expertise.length > 0 ? (
                          <div className="flex flex-wrap gap-1">
                            {expertise.map((e) => (
                              <span key={e} className="inline-flex px-1.5 py-0.5 text-xs bg-muted rounded whitespace-nowrap">
                                {e}
                              </span>
                            ))}
                          </div>
                        ) : (
                          <span className="text-sm text-muted-foreground">-</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-center">
                        {m.email ? (
                          <a href={`mailto:${m.email}`} title={m.email}
                            className="text-primary hover:text-primary/70 inline-flex items-center justify-center">
                            <Mail className="h-4 w-4" />
                          </a>
                        ) : (
                          <span className="text-muted-foreground text-sm">-</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-center hidden sm:table-cell">
                        {m.linkedin_url ? (
                          <a href={m.linkedin_url} target="_blank" rel="noopener noreferrer" title={m.linkedin_url}
                            className="text-primary hover:text-primary/70 inline-flex items-center justify-center">
                            <ExternalLink className="h-4 w-4" />
                          </a>
                        ) : (
                          <span className="text-muted-foreground text-sm">-</span>
                        )}
                      </td>
                      <td className="px-4 py-3 hidden lg:table-cell">
                        <span className="inline-flex px-1.5 py-0.5 text-xs font-medium rounded-full whitespace-nowrap bg-muted text-muted-foreground">
                          {m.is_active === false ? 'Inactive' : 'Active'}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
}
