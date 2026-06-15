'use client';

// Deal detail right-hand info panel ("About this deal" / Company / Notes).
// Desktop (lg+): a persistent side column, as before.
// Mobile (<lg): hidden by default so it no longer squeezes/overlays the Activity
//               timeline. A floating info button opens it as a slide-over panel.
//
// The children are the same server-rendered cards passed from the deal page, so
// no data logic lives here -- this is purely the responsive container/toggle.

import { useState, type ReactNode } from 'react';
import { Info, X } from 'lucide-react';

export function DealInfoAside({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      {/* Desktop: persistent side column (unchanged layout) */}
      <aside className="hidden w-80 shrink-0 space-y-3 overflow-y-auto border-l bg-muted/20 p-4 lg:block">
        {children}
      </aside>

      {/* Mobile: floating toggle button */}
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Deal info"
        className="fixed bottom-4 right-4 z-30 inline-flex h-12 w-12 items-center justify-center rounded-full border bg-background text-foreground shadow-lg lg:hidden"
      >
        <Info className="h-5 w-5" />
      </button>

      {/* Mobile: slide-over panel */}
      {open && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div
            className="absolute inset-0 bg-black/40"
            onClick={() => setOpen(false)}
            aria-hidden="true"
          />
          <div className="absolute right-0 top-0 flex h-full w-[85%] max-w-sm flex-col overflow-y-auto bg-background p-4 shadow-xl">
            <div className="mb-3 flex items-center justify-between">
              <span className="text-sm font-semibold">Deal info</span>
              <button
                type="button"
                onClick={() => setOpen(false)}
                aria-label="Close"
                className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-3">{children}</div>
          </div>
        </div>
      )}
    </>
  );
}
