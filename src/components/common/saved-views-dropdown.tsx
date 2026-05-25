/**
 * components/common/saved-views-dropdown.tsx
 *
 * Dropdown showing user-saved filter views for an entity/module.
 */
'use client';
import { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { SavedView } from '@/lib/queries/saved-views';
import type { PartyTypeCode } from '@/types/ai';

interface SavedViewsDropdownProps {
  views: SavedView[];
  entityType: string;
  module: PartyTypeCode;
  className?: string;
}

export function SavedViewsDropdown({
  views,
  className,
}: SavedViewsDropdownProps) {
  const [open, setOpen] = useState(false);

  if (!views || views.length === 0) return null;

  return (
    <div className={cn('relative', className)}>
      <button
        type="button"
        onClick={() => setOpen(o => !o)}
        className="inline-flex items-center gap-1 rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
      >
        Saved Views
        <ChevronDown className="h-4 w-4" />
      </button>
      {open && (
        <div className="absolute right-0 mt-1 w-56 rounded-md border border-gray-200 bg-white shadow-lg z-10">
          <ul className="py-1">
            {views.map(v => (
              <li key={v.id}>
                <button
                  type="button"
                  className="block w-full px-3 py-2 text-left text-sm text-gray-700 hover:bg-gray-50"
                  onClick={() => setOpen(false)}
                >
                  {v.name}
                  {v.is_default && (
                    <span className="ml-2 text-xs text-gray-400">(default)</span>
                  )}
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}