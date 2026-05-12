import { notFound } from 'next/navigation';
import { fetchCurrentUserProfile } from '@/lib/queries/user-profile';
import { LanguageForm } from '@/components/settings/language-form';

export default async function LanguageSettingsPage() {
  const profile = await fetchCurrentUserProfile();
  if (!profile) notFound();
  return (
    <div className="max-w-2xl">
      <LanguageForm currentLanguage={profile.preferredLanguage} />
    </div>
  );
}
