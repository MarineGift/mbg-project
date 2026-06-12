import {
  listWhitelist,
  getUnregisteredDomains,
  getAddressAssignments,
} from "@/lib/actions/email-whitelist";
import { EmailWhitelistClient } from "@/components/settings/email-whitelist-client";

export default async function EmailWhitelistPage() {
  const [entries, unregistered] = await Promise.all([
    listWhitelist(),
    getUnregisteredDomains(),
  ]);
  const addressEmails = entries
    .filter(e => e.kind === "address")
    .map(e => e.pattern);
  const assignments = await getAddressAssignments(addressEmails);
  return (
    <div className="p-6 max-w-4xl mx-auto">
      <EmailWhitelistClient
        initialEntries={entries}
        unregisteredDomains={unregistered}
        initialAssignments={assignments}
      />
    </div>
  );
}
