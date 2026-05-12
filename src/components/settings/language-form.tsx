'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Loader2, Save } from 'lucide-react';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';
import { updateUserPreferredLanguage } from '@/lib/actions/profile';
import { locales, localeCookieName, localeDisplayNames, type Locale } from '@/i18n/routing';

interface Props {
  currentLanguage: Locale;
}

export function LanguageForm({ currentLanguage }: Props) {
  const t = useTranslations('settings.language');
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selected, setSelected] = useState<Locale>(currentLanguage);

  const handleSave = () => {
    if (selected === currentLanguage) return;
    startTransition(async () => {
      const result = await updateUserPreferredLanguage({ language: selected });
      if (result.ok) {
        // cookie도 즉시 갱신 (다음 요청부터 반영)
        document.cookie = `${localeCookieName}=${selected}; path=/; max-age=${60 * 60 * 24 * 365}; samesite=lax`;
        toast.success(t('saved'));
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? 'Save failed');
      }
    });
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t('title')}</CardTitle>
        <CardDescription>{t('description')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <RadioGroup
          value={selected}
          onValueChange={(v) => setSelected(v as Locale)}
          disabled={isPending}
          className="space-y-2"
        >
          {locales.map((loc) => (
            <div key={loc} className="flex items-center gap-2">
              <RadioGroupItem value={loc} id={`lang-${loc}`} />
              <Label htmlFor={`lang-${loc}`} className="cursor-pointer font-normal">
                {localeDisplayNames[loc]}
              </Label>
            </div>
          ))}
        </RadioGroup>

        <Button onClick={handleSave} disabled={isPending || selected === currentLanguage}>
          {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          {t('save')}
        </Button>
      </CardContent>
    </Card>
  );
}
