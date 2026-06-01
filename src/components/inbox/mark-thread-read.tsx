'use client';

/**
 * src/components/inbox/mark-thread-read.tsx
 * Invisible helper: on mount, marks the given inbound messages read.
 * Runs as a client effect (not during server render) so the server action's
 * revalidatePath is invoked from an action context, not during render.
 */

import { useEffect, useRef } from 'react';
import { markCommunicationsRead } from '@/app/actions/mark-read';

export function MarkThreadRead({ ids }: { ids: string[] }) {
  const done = useRef(false);
  useEffect(() => {
    if (done.current) return;
    if (!ids || ids.length === 0) return;
    done.current = true;
    void markCommunicationsRead(ids);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return null;
}
