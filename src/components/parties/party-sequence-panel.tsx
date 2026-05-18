// src/components/parties/party-sequence-panel.tsx
// Server component — party 상세 페이지 하단에 배치
// 사용: <PartySequencePanel partyId={id} orgId={orgId} contacts={contacts} />

import { fetchPartyEnrollments, fetchSequences } from '@/lib/queries/email-sequences';
import { EnrollSequenceDialog } from './enroll-sequence-dialog';
import { CancelEnrollmentButton } from './cancel-enrollment-button';
import type { EnrollmentStatus } from '@/types/phase21b';

interface Contact {
  id:        string;
  full_name: string;
  email:     string | null;
}

interface Props {
  partyId:  string;
  orgId:    string;
  contacts: Contact[];
}

const STATUS_CONFIG: Record<EnrollmentStatus, { label: string; color: string }> = {
  active:    { label: 'Active',    color: 'bg-emerald-100 text-emerald-700' },
  paused:    { label: 'Paused',    color: 'bg-amber-100 text-amber-700' },
  completed: { label: 'Completed', color: 'bg-blue-100 text-blue-700' },
  cancelled: { label: 'Cancelled', color: 'bg-gray-100 text-gray-500' },
};

function formatDate(iso: string | null) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric',
  });
}

function ProgressDots({ current, total }: { current: number; total: number }) {
  return (
    <div className="flex items-center gap-1">
      {Array.from({ length: total }).map((_, i) => (
        <div
          key={i}
          className={`w-2 h-2 rounded-full ${
            i < current  ? 'bg-blue-500'   :
            i === current ? 'bg-blue-300 ring-2 ring-blue-200' :
                           'bg-gray-200'
          }`}
        />
      ))}
      <span className="ml-1 text-xs text-gray-400">{current}/{total}</span>
    </div>
  );
}

export async function PartySequencePanel({ partyId, orgId, contacts }: Props) {
  const [enrollments, sequences] = await Promise.all([
    fetchPartyEnrollments(partyId),
    fetchSequences(orgId),
  ]);

  const active    = enrollments.filter(e => e.status === 'active');
  const completed = enrollments.filter(e => e.status === 'completed');
  const other     = enrollments.filter(e => e.status !== 'active' && e.status !== 'completed');

  return (
    <section className="mt-8">
      {/* Section header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <h3 className="text-sm font-semibold text-gray-900">Email Sequences</h3>
          {active.length > 0 && (
            <span className="text-xs bg-emerald-100 text-emerald-700 font-medium px-2 py-0.5 rounded-full">
              {active.length} active
            </span>
          )}
        </div>
        <EnrollSequenceDialog
          partyId={partyId}
          orgId={orgId}
          sequences={sequences}
          contacts={contacts}
        />
      </div>

      {enrollments.length === 0 ? (
        <div className="text-sm text-gray-400 py-4 text-center border border-dashed border-gray-200 rounded-lg">
          Not enrolled in any sequences.
        </div>
      ) : (
        <div className="space-y-2">
          {/* Active enrollments */}
          {active.map(e => {
            const cfg = STATUS_CONFIG[e.status];
            return (
              <div
                key={e.id}
                className="flex items-center justify-between px-4 py-3 border border-gray-200 rounded-lg bg-white hover:bg-gray-50"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm font-medium text-gray-900 truncate">
                      {e.sequence_name}
                    </span>
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full flex-shrink-0 ${cfg.color}`}>
                      {cfg.label}
                    </span>
                  </div>
                  <div className="flex items-center gap-4">
                    <ProgressDots
                      current={e.sends_count}
                      total={e.total_steps}
                    />
                    {e.next_send_at && (
                      <span className="text-xs text-gray-400">
                        Next: {formatDate(e.next_send_at)}
                      </span>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-3 ml-3 flex-shrink-0">
                  <span className="text-xs text-gray-400">
                    Step {e.next_step_order + 1} of {e.total_steps}
                  </span>
                  <CancelEnrollmentButton enrollmentId={e.id} partyId={partyId} />
                </div>
              </div>
            );
          })}

          {/* Completed enrollments (collapsed) */}
          {completed.map(e => {
            const cfg = STATUS_CONFIG[e.status];
            return (
              <div
                key={e.id}
                className="flex items-center justify-between px-4 py-2 border border-gray-100 rounded-lg bg-gray-50"
              >
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-500 truncate">{e.sequence_name}</span>
                  <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${cfg.color}`}>
                    {cfg.label}
                  </span>
                </div>
                <span className="text-xs text-gray-400">
                  {e.sends_count} sent · enrolled {formatDate(e.enrolled_at)}
                </span>
              </div>
            );
          })}

          {/* Cancelled */}
          {other.map(e => {
            const cfg = STATUS_CONFIG[e.status];
            return (
              <div
                key={e.id}
                className="flex items-center justify-between px-4 py-2 border border-gray-100 rounded-lg bg-gray-50 opacity-60"
              >
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-400 truncate">{e.sequence_name}</span>
                  <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${cfg.color}`}>
                    {cfg.label}
                  </span>
                </div>
                <span className="text-xs text-gray-400">{formatDate(e.enrolled_at)}</span>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}
