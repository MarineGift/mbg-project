'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import {
  Star,
  Mail,
  Phone,
  Briefcase,
  Plus,
  Calendar,
  ArrowRight,
  Check,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ContactFormDialog } from '@/components/parties/contact-form-dialog';
import type { PartyContact } from '@/types/party-detail';
import type { ContactActivity } from '@/lib/queries/contact-activities';

interface Props {
  contacts: readonly PartyContact[];
  /** the party to auto-link in the Add Contact dialog */
  partyId: string;
  /** activity per contact id, fetched server-side */
  activitiesByContact: Record<string, ContactActivity[]>;
}

function displayName(c: PartyContact): string {
  if (c.fullName && c.fullName.trim()) return c.fullName.trim();
  if (c.email) return c.email;
  return '(unnamed)';
}

function fmtDate(iso: string | null): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

export function PartyContactsPanel({ contacts, partyId, activitiesByContact }: Props) {
  const t = useTranslations('partyDetail.contacts');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(
    contacts[0]?.id ?? null,
  );

  const selected = contacts.find((c) => c.id === selectedId) ?? null;
  const activities = selected ? (activitiesByContact[selected.id] ?? []) : [];

  return (
    <>
      <Card>
        <CardHeader className="pb-3 flex flex-row items-center justify-between space-y-0">
          <CardTitle className="text-sm">{t('title')}</CardTitle>
          <Button
            size="sm"
            className="gap-1 bg-blue-600 hover:bg-blue-700 text-white"
            onClick={() => setDialogOpen(true)}
            aria-label={t('addContact')}
          >
            <Plus className="h-4 w-4" />
            <span className="text-xs">Add</span>
          </Button>
        </CardHeader>
        <CardContent>
          {contacts.length === 0 ? (
            <p className="text-xs text-muted-foreground italic">{t('empty')}</p>
          ) : (
            <div className="grid gap-4 md:grid-cols-[260px_1fr]">
              {/* LEFT: contact list */}
              <ul className="space-y-1 md:border-r md:pr-3">
                {contacts.map((c) => {
                  const active = c.id === selectedId;
                  return (
                    <li key={c.id}>
                      <button
                        type="button"
                        onClick={() => setSelectedId(c.id)}
                        aria-pressed={active}
                        className={[
                          'w-full text-left rounded-md px-2 py-1.5 transition-colors',
                          active ? 'bg-muted' : 'hover:bg-muted/60',
                        ].join(' ')}
                      >
                        <span className="flex items-center gap-1.5">
                          {c.isPrimary && (
                            <Star
                              className="h-3.5 w-3.5 text-amber-500 shrink-0"
                              aria-label="Primary"
                            />
                          )}
                          <span className="font-medium text-sm truncate">
                            {displayName(c)}
                          </span>
                        </span>
                        {c.jobTitle && (
                          <span className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5">
                            <Briefcase className="h-3 w-3 shrink-0" />
                            <span className="truncate">{c.jobTitle}</span>
                          </span>
                        )}
                      </button>
                    </li>
                  );
                })}
              </ul>

              {/* RIGHT: selected contact detail + engagement-activity timeline */}
              <div className="min-w-0">
                {!selected ? (
                  <p className="text-xs text-muted-foreground italic">Select a contact.</p>
                ) : (
                  <div className="space-y-4">
                    {/* detail */}
                    <div className="space-y-1">
                      <div className="flex items-center gap-1.5">
                        {selected.isPrimary && (
                          <Star className="h-4 w-4 text-amber-500 shrink-0" aria-label="Primary" />
                        )}
                        <h3 className="text-base font-semibold truncate">
                          {displayName(selected)}
                        </h3>
                      </div>
                      {selected.jobTitle && (
                        <p className="text-xs text-muted-foreground flex items-center gap-1">
                          <Briefcase className="h-3 w-3" />
                          {selected.jobTitle}
                        </p>
                      )}
                      {selected.email && (
                        <a
                          href={`mailto:${selected.email}`}
                          className="text-xs text-muted-foreground flex items-center gap-1 hover:text-foreground truncate"
                        >
                          <Mail className="h-3 w-3" />
                          {selected.email}
                        </a>
                      )}
                      {selected.phone && (
                        
                          href={`tel:${selected.phone}`}
                          className="text-xs text-muted-foreground flex items-center gap-1 hover:text-foreground"
                        >
                          <Phone className="h-3 w-3" />
                          {selected.phone}
                        </a>
                      )}
                      {selected.notes && (
                        <p className="text-xs text-foreground/80 whitespace-pre-line pt-1 leading-relaxed">
                          {selected.notes}
                        </p>
                      )}
                    </div>

                    {/* engagement activity timeline */}
                    <div>
                      <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2">
                        Engagement Activity
                      </h4>
                      {activities.length === 0 ? (
                        <p className="text-xs text-muted-foreground italic">
                          No activity recorded with this contact yet.
                        </p>
                      ) : (
                        <ul className="space-y-2">
                          {activities.map((a) => (
                            <li
                              key={a.engagementId}
                              className="rounded-md border px-3 py-2"
                            >
                              <div className="flex items-center justify-between gap-2">
                                <span className="text-sm font-medium truncate">
                                  {a.title ?? a.channel ?? 'Activity'}
                                </span>
                                {a.occurredAt && (
                                  <span className="text-xs text-muted-foreground flex items-center gap-1 shrink-0">
                                    <Calendar className="h-3 w-3" />
                                    {fmtDate(a.occurredAt)}
                                  </span>
                                )}
                              </div>
                              <div className="flex flex-wrap items-center gap-x-2 gap-y-0.5 mt-1 text-xs text-muted-foreground">
                                {a.direction && (
                                  <span className="inline-flex items-center gap-0.5">
                                    <ArrowRight className="h-3 w-3" />
                                    {a.direction}
                                  </span>
                                )}
                                {a.channel && <span>{a.channel}</span>}
                                {a.role && (
                                  <span className="rounded bg-muted px-1.5 py-0.5">{a.role}</span>
                                )}
                                {a.attended === true && (
                                  <span className="inline-flex items-center gap-0.5 text-emerald-600">
                                    <Check className="h-3 w-3" />
                                    attended
                                  </span>
                                )}
                              </div>
                              {a.summary && (
                                <p className="text-xs text-muted-foreground mt-1 line-clamp-2">
                                  {a.summary}
                                </p>
                              )}
                            </li>
                          ))}
                        </ul>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <ContactFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        partyId={partyId}
      />
    </>
  );
}
