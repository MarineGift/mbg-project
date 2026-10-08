'use client';

/**
 * MentorHeadshot - mentor photo with a graceful fallback.
 * Shows the GraduationCap placeholder when there is no URL OR when the image
 * fails to load (expired Airtable links, deleted storage objects, etc.), so a
 * broken-image icon with alt text is never rendered.
 */

import { useState } from 'react';
import { GraduationCap } from 'lucide-react';

export function MentorHeadshot({ src, alt }: { src: string | null; alt: string }) {
  const [failed, setFailed] = useState(false);
  const usable = !!src && !failed && !/airtable\.com\//i.test(src);

  if (!usable) {
    return (
      <div className="h-24 w-24 rounded-lg border bg-muted flex items-center justify-center shrink-0" title="No photo">
        <GraduationCap className="h-8 w-8 text-muted-foreground" />
      </div>
    );
  }
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src!}
      alt={alt}
      onError={() => setFailed(true)}
      className="h-24 w-24 rounded-lg object-cover border shrink-0"
    />
  );
}
