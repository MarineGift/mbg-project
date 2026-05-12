'use client';

import { useTranslations } from 'next-intl';
import { StickyNote } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

interface Props {
  notes: string | null;
}

export function PartyNotesCard({ notes }: Props) {
  const t = useTranslations('partyDetail.notes');
  if (!notes || notes.trim().length === 0) {
    return null;
  }
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <StickyNote className="h-4 w-4 text-muted-foreground" />
          {t('title')}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-sm whitespace-pre-wrap leading-relaxed">{notes}</p>
      </CardContent>
    </Card>
  );
}
