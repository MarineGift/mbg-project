'use client';

import { useTranslations } from 'next-intl';
import { Star, Mail, Phone, Briefcase } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import type { PartyContact } from '@/types/party-detail';

interface Props {
  contacts: readonly PartyContact[];
}

export function PartyContactsList({ contacts }: Props) {
  const t = useTranslations('partyDetail.contacts');

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm">{t('title')}</CardTitle>
      </CardHeader>
      <CardContent>
        {contacts.length === 0 ? (
          <p className="text-xs text-muted-foreground italic">{t('empty')}</p>
        ) : (
          <ul className="space-y-3">
            {contacts.map((c) => (
              <li key={c.id} className="flex items-start gap-2">
                {c.isPrimary && (
                  <Star className="h-3.5 w-3.5 text-amber-500 mt-1 shrink-0" aria-label="Primary" />
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm truncate">
                    {c.fullName ?? c.email ?? '(unnamed)'}
                  </p>
                  {c.jobTitle && (
                    <p className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5">
                      <Briefcase className="h-3 w-3" />
                      {c.jobTitle}
                    </p>
                  )}
                  {c.email && (
                    <a
                      href={`mailto:${c.email}`}
                      className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5 hover:text-foreground truncate"
                    >
                      <Mail className="h-3 w-3" />
                      {c.email}
                    </a>
                  )}
                  {c.phone && (
                    <p className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5">
                      <Phone className="h-3 w-3" />
                      {c.phone}
                    </p>
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
