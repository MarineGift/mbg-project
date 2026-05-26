'use client';
import { Calendar } from 'lucide-react';
import type { PartyMeeting } from '@/lib/queries/meetings';

interface PartyMeetingsListProps {
  partyId: string;
  meetings: PartyMeeting[];
}

export function PartyMeetingsList({ meetings }: PartyMeetingsListProps) {
  if (!meetings || meetings.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-gray-400">
        <Calendar className="h-8 w-8 mb-2" />
        <p className="text-sm">No meetings yet.</p>
      </div>
    );
  }

  return (
    <ul className="divide-y divide-gray-100">
      {meetings.map((m) => (
        <li key={m.id} className="py-3">
          <div className="flex items-start gap-3">
            <Calendar className="h-4 w-4 mt-0.5 text-gray-400" />
            <div className="flex-1 min-w-0">
              <div className="font-medium text-sm text-gray-900 truncate">{m.title}</div>
              <div className="text-xs text-gray-500 mt-0.5">
                {new Date(m.scheduledAt ?? m.occurredAt).toLocaleString()}
                {m.location && (
                  <span> { ', ' }{m.location}</span>
                )}
              </div>
              {m.notes && (
                <p className="text-xs text-gray-600 mt-1 line-clamp-2">{m.notes}</p>
              )}
            </div>
          </div>
        </li>
      ))}
    </ul>
  );
}
