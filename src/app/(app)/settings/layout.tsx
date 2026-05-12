import { SettingsNav } from '@/components/settings/settings-nav';

export default function SettingsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex h-full">
      <SettingsNav />
      <div className="flex-1 overflow-y-auto p-6">{children}</div>
    </div>
  );
}
