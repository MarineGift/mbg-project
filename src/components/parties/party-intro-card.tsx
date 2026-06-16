/**
 * components/parties/party-intro-card.tsx
 *
 * Prominent "Introduction" card for the party Overview tab.
 * Renders the long free-text party introduction in Korean and English
 * (app.parties.intro_ko / intro_en). This is the headline party context,
 * so it sits at the top of the Overview and is ALWAYS shown (like Notes):
 * when both fields are empty it shows a "-" placeholder so the section is
 * always visible and obvious where to add the introduction.
 */

import { BookOpen } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

interface Props {
  introKo: string | null;
  introEn: string | null;
}

export function PartyIntroCard({ introKo, introEn }: Props) {
  const hasKo = !!introKo && introKo.trim().length > 0;
  const hasEn = !!introEn && introEn.trim().length > 0;
  const isEmpty = !hasKo && !hasEn;

  return (
    <Card className="border-blue-200 bg-blue-50/40">
      <CardHeader className="pb-3">
        <CardTitle className="text-base flex items-center gap-2">
          <BookOpen className="h-5 w-5 text-blue-600" />
          Introduction / 소개
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-5 pb-6">
        {isEmpty && (
          <p className="text-sm text-muted-foreground">
            - <span className="ml-1">아직 등록된 소개가 없습니다. (intro_ko / intro_en)</span>
          </p>
        )}
        {hasKo && (
          <div>
            <p className="text-xs font-medium text-muted-foreground mb-1">한국어</p>
            <p className="text-base whitespace-pre-wrap leading-relaxed">{introKo}</p>
          </div>
        )}
        {hasEn && (
          <div>
            <p className="text-xs font-medium text-muted-foreground mb-1">English</p>
            <p className="text-base whitespace-pre-wrap leading-relaxed text-foreground/80">
              {introEn}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
