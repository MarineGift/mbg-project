'use client';

/**
 * MentorGenderToggle - Male / Female / Unconfirmed segmented control on the
 * mentor profile card. Default is Unconfirmed; set a gender only once it has
 * been confirmed.
 */

import { useState, useTransition } from 'react';
import { Loader2 } from 'lucide-react';
import { setMentorGender } from '@/lib/actions/mentors';

type G = 'male' | 'female' | 'unknown';
const OPTIONS: { value: G; label: string }[] = [
  { value: 'male', label: 'Male' },
  { value: 'female', label: 'Female' },
  { value: 'unknown', label: 'Unconfirmed' },
];

export function MentorGenderToggle({ partyId, initial }: { partyId: string; initial: G }) {
  const [value, setValue] = useState<G>(initial);
  const [err, setErr] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const pick = (g: G) => {
    if (g === value || pending) return;
    const prev = value;
    setValue(g);
    setErr(null);
    start(async () => {
      const r = await setMentorGender(partyId, g);
      if (!r.ok) { setValue(prev); setErr(r.errorMessage ?? 'Save failed'); }
    });
  };

  return (
    <div className="flex items-center gap-2 mt-1">
      <span className="text-xs text-muted-foreground">Gender</span>
      <div className="inline-flex rounded-md border overflow-hidden">
        {OPTIONS.map((o) => (
          <button
            key={o.value}
            type="button"
            onClick={() => pick(o.value)}
            className={`px-2 py-0.5 text-xs transition ${
              value === o.value
                ? o.value === 'unknown' ? 'bg-muted font-medium' : 'bg-foreground text-background font-medium'
                : 'bg-background hover:bg-muted text-muted-foreground'
            }`}
            aria-pressed={value === o.value}
          >
            {o.label}
          </button>
        ))}
      </div>
      {pending && <Loader2 className="h-3 w-3 animate-spin text-muted-foreground" />}
      {err && <span className="text-xs text-destructive">{err}</span>}
    </div>
  );
}
