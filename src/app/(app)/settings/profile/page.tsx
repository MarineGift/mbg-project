import { notFound } from 'next/navigation';
import { fetchCurrentUserProfile } from '@/lib/queries/user-profile';
import { ProfileForm } from '@/components/settings/profile-form';

export default async function ProfileSettingsPage() {
  const profile = await fetchCurrentUserProfile();
  if (!profile) notFound();
  return (
    <div className="max-w-2xl">
      <ProfileForm profile={profile} />
    </div>
  );
}
