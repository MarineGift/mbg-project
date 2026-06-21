'use client';

// src/app/(app)/mailing/mailing-tabs-client.tsx
// Tabbed shell for the Mailing area:
//   Tab 1 "Mailing"          -> BulkMailClient (audience -> send / queue)
//   Tab 2 "Email Sequences"  -> EmailSequencesClient (list + full CRUD:
//                               create / edit / archive / bulk enroll)
// Both panels reuse the existing client components unchanged; this file
// only switches between them. Server data is fetched in page.tsx and
// passed down.

import { useState } from 'react';
import { BulkMailClient } from './bulk-mail-client';
import { EmailSequencesClient } from '@/components/settings/email-sequences-client';

type MailingProps = React.ComponentProps<typeof BulkMailClient>;
type SeqListProps = React.ComponentProps<typeof EmailSequencesClient>;

interface Props {
  mailing:   MailingProps;
  sequences: SeqListProps['sequences'];
  orgId:     string;
}

type TabKey = 'mailing' | 'sequences';

const TABS: { key: TabKey; label: string }[] = [
  { key: 'mailing',   label: 'Mailing' },
  { key: 'sequences', label: 'Email Sequences' },
];

export function MailingTabsClient({ mailing, sequences, orgId }: Props) {
  const [tab, setTab] = useState<TabKey>('mailing');

  return (
    <div>
      {/* Tab strip */}
      <div className="border-b border-gray-200 bg-white">
        <div className="mx-auto max-w-app px-4 sm:px-6">
          <nav className="flex gap-6">
            {TABS.map((t) => {
              const active = tab === t.key;
              return (
                <button
                  key={t.key}
                  type="button"
                  onClick={() => setTab(t.key)}
                  className={
                    'relative -mb-px py-3 text-sm font-medium transition-colors ' +
                    (active
                      ? 'text-blue-600 border-b-2 border-blue-600'
                      : 'text-gray-500 border-b-2 border-transparent hover:text-gray-800')
                  }
                  aria-current={active ? 'page' : undefined}
                >
                  {t.label}
                  {t.key === 'sequences' && sequences.length > 0 && (
                    <span className="ml-2 rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-500">
                      {sequences.length}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Active panel. Keep both mounted? No - render the active one only so
          BulkMailClient's polling/effects don't run on the sequences tab. */}
      {tab === 'mailing' ? (
        <BulkMailClient
          pipelines={mailing.pipelines}
          stages={mailing.stages}
          templates={mailing.templates}
          accounts={mailing.accounts}
        />
      ) : (
        <div className="mx-auto max-w-app p-4 sm:p-6">
          {orgId ? (
            <EmailSequencesClient sequences={sequences} orgId={orgId} />
          ) : (
            <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
              NEXT_PUBLIC_DEFAULT_ORG_ID is not set, so sequences cannot load.
            </div>
          )}
        </div>
      )}
    </div>
  );
}
