import { listBlocklist } from '@/lib/actions/email-blocklist';
import { EmailBlocklistClient } from '@/components/settings/email-blocklist-client';

export default async function EmailBlocklistPage() {
  const entries = await listBlocklist();
  return (
    <div className="p-6">
      <EmailBlocklistClient initialEntries={entries} />
    </div>
  );
}
