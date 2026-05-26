'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Star, Mail, Phone, Briefcase, Plus } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ContactFormDialog } from '@/components/parties/contact-form-dialog';
import type { PartyContact } from '@/types/party-detail';

interface Props {
  contacts: readonly PartyContact[];
  /** Add Contact 다이얼로그에서 자동 연결할 party */
  partyId: string;
}

export function PartyContactsList({ contacts, partyId }: Props) {
  const t = useTranslations('partyDetail.contacts');
  const [dialogOpen, setDialogOpen] = useState(false);

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
            <span className="text-xs">{t('addContact')}</span>
          </Button>
        </CardHeader>
        <CardContent>
          {contacts.length === 0 ? (
            <p className="text-xs text-muted-foreground italic">{t('empty')}</p>
          ) : (
            <ul className="space-y-3">
              {contacts.map((c) => (
                <li key={c.id} className="flex items-start gap-2">
                  {c.isPrimary && (
                    <Star
                      className="h-3.5 w-3.5 text-amber-500 mt-1 shrink-0"
                      aria-label="Primary"
                    />
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

      <ContactFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        partyId={partyId}
      />
    </>
  );
}
