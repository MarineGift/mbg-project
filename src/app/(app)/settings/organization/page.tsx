import { notFound } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { getTranslations } from 'next-intl/server';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { fetchCurrentUserProfile } from '@/lib/queries/user-profile';

export default async function OrganizationSettingsPage() {
  const profile = await fetchCurrentUserProfile();
  if (!profile) notFound();

  const t = await getTranslations('settings.organization');

  return (
    <div className="max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle>{t('title')}</CardTitle>
          <CardDescription>{t('description')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3 text-sm">
          <div className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2">
            <span className="text-muted-foreground">{t('name')}</span>
            <span className="font-medium">{profile.organizationName}</span>
            <span className="text-muted-foreground">{t('organizationId')}</span>
            <span className="font-mono text-xs">{profile.organizationId}</span>
            <span className="text-muted-foreground">{t('role')}</span>
            <span className="font-medium">
              {profile.isOwner ? t('owner') : t('member')}
            </span>
          </div>
          <p className="text-xs text-muted-foreground pt-2 border-t">{t('phase1Notice')}</p>
        </CardContent>
      </Card>
    </div>
  );
}
