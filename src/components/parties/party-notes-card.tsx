'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { StickyNote, Plus } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

interface Props {
  notes: string | null;
  partyId: string;
  partyType: string;
}

export function PartyNotesCard({ notes, partyId, partyType }: Props) {
  const t = useTranslations('partyDetail.notes');
  const hasNotes = !!notes && notes.trim().length > 0;
  return (
    <Card>
      <CardHeader className="pb-3 flex flex-row items-center justify-between space-y-0">
        <CardTitle className="text-sm flex items-center gap-2">
          <StickyNote className="h-4 w-4 text-muted-foreground" />
          {t('title')}
        </CardTitle>
        <Button
          asChild
          size="sm"
          className="gap-1 bg-blue-600 hover:bg-blue-700 text-white"
          aria-label="Add note"
        >
          <Link href={`/${partyType}/parties/${partyId}/edit`}>
            <Plus className="h-4 w-4" />
            <span className="text-xs">Add</span>
          </Link>
        </Button>
      </CardHeader>
      <CardContent>
        {hasNotes ? (
          <p className="text-sm whitespace-pre-wrap leading-relaxed">{notes}</p>
        ) : (
          <p className="text-xs text-muted-foreground italic">No notes yet.</p>
        )}
      </CardContent>
    </Card>
  );
}
