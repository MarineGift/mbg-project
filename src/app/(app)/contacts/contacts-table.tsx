// src/app/(app)/contacts/contacts-table.tsx
// Client table for the contacts index. Handles role-only contacts (no name,
// only title + firm) gracefully -- common for imported VC firm partner lists.

'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Star, Mail, Phone, User } from 'lucide-react';

type Contact = {
  id: string;
  full_name: string | null;
  given_name: string | null;
  family_name: string | null;
  email: string | null;
  phone_e164: string | null;
  phone_mobile: string | null;
  title_text: string | null;
  department: string | null;
  role_category: string | null;
  is_decision_maker: boolean;
  is_primary: boolean;
  is_active: boolean;
  last_contacted_at: string | null;
  firm: {
    id: string;
    party_name: string;
    country_code: string | null;
  } | null;
};

interface Props {
  contacts: Contact[];
}

// ---- helpers ----

// Returns the contact's display name, or null if no name is set.
// Null is meaningful -- it signals "role-only" contacts (e.g. unidentified
// Partner at a VC firm) that should render differently.
function displayName(c: Contact): string | null {
  if (c.full_name) return c.full_name;
  if (c.given_name && c.family_name) return c.given_name + ' ' + c.family_name;
  return c.given_name || c.family_name || null;
}

// Returns 2-letter initials, or null if no name (caller renders an icon instead).
function initials(c: Contact): string | null {
  if (c.given_name && c.family_name) {
    return (c.given_name[0]! + c.family_name[0]!).toUpperCase();
  }
  const n = displayName(c);
  if (!n) return null;
  const parts = n.trim().split(/\s+/);
  if (parts.length >= 2) return (parts[0]![0]! + parts[parts.length - 1]![0]!).toUpperCase();
  return n.slice(0, 2).toUpperCase();
}

function fmtRelative(iso: string | null): string {
  if (!iso) return '';
  const ms = Date.now() - new Date(iso).getTime();
  if (ms < 0) return '';
  const days = Math.floor(ms / 86_400_000);
  if (days < 1) return 'today';
  if (days < 30) return days + 'd ago';
  if (days < 365) return Math.floor(days / 30) + 'mo ago';
  return Math.floor(days / 365) + 'y ago';
}

// ---- component ----

export function ContactsTable({ contacts }: Props) {
  const [query, setQuery] = useState('');
  const router = useRouter();

  const filtered = useMemo(() => {
    if (!query.trim()) return contacts;
    const q = query.toLowerCase().trim();
    return contacts.filter((c) => {
      const name = (displayName(c) || '').toLowerCase();
      const email = (c.email || '').toLowerCase();
      const firm = (c.firm?.party_name || '').toLowerCase();
      const title = (c.title_text || '').toLowerCase();
      const dept = (c.department || '').toLowerCase();
      return (
        name.includes(q) ||
        email.includes(q) ||
        firm.includes(q) ||
        title.includes(q) ||
        dept.includes(q)
      );
    });
  }, [contacts, query]);

  return (
    <div className="flex h-full flex-col">
      <div className="border-b bg-background px-6 py-4">
        <div className="flex items-baseline justify-between gap-4">
          <h1 className="text-xl font-semibold text-foreground">Contacts</h1>
          <div className="whitespace-nowrap text-xs text-muted-foreground tabular-nums">
            {query.trim() ? (
              <>
                {filtered.length} of {contacts.length}
              </>
            ) : (
              <>{contacts.length} contacts</>
            )}
          </div>
        </div>
        <p className="mt-0.5 text-xs text-muted-foreground">
          People across all your deals and companies
        </p>

        <div className="relative mt-3 max-w-md">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by name, email, company, title..."
            className="w-full rounded-md border bg-background py-2 pl-9 pr-3 text-sm placeholder:text-muted-foreground focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
          />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        {filtered.length === 0 ? (
          <div className="rounded-lg border bg-card px-6 py-16 text-center text-sm text-muted-foreground">
            {query.trim()
              ? 'No contacts match "' + query + '"'
              : 'No contacts yet'}
          </div>
        ) : (
          <div className="overflow-hidden rounded-lg border bg-card">
            <table className="w-full text-sm">
              <thead className="border-b bg-muted/30 text-xs text-muted-foreground">
                <tr>
                  <th className="px-4 py-2.5 text-left font-medium">Person</th>
                  <th className="px-4 py-2.5 text-left font-medium">Company</th>
                  <th className="px-4 py-2.5 text-left font-medium">Contact</th>
                  <th className="px-4 py-2.5 text-left font-medium">Last activity</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {filtered.map((c) => (
                  <ContactRow
                    key={c.id}
                    contact={c}
                    onOpen={() => router.push('/contacts/' + c.id)}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function ContactRow({ contact: c, onOpen }: { contact: Contact; onOpen: () => void }) {
  const name = displayName(c);
  const init = initials(c);
  const inactive = c.is_active === false;
  const subtitle = [c.title_text, c.department].filter(Boolean).join(', ');

  return (
    <tr
      onClick={onOpen}
      className={
        'cursor-pointer transition hover:bg-muted/40 ' +
        (inactive ? 'opacity-60' : '')
      }
    >
      {/* Person */}
      <td className="px-4 py-3">
        <div className="flex items-center gap-3">
          {/* Avatar -- initials if name known, user icon if not */}
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-medium text-muted-foreground">
            {init ?? <User className="h-4 w-4 opacity-50" />}
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-1.5">
              {name ? (
                <span className="truncate font-medium text-foreground">{name}</span>
              ) : (
                <span className="text-sm italic text-muted-foreground/80">(no name)</span>
              )}
              {c.is_decision_maker && (
                <span
                  title="Decision maker"
                  className="inline-flex items-center rounded-full bg-amber-50 px-1.5 py-0 text-[10px] font-medium text-amber-700 ring-1 ring-inset ring-amber-200"
                >
                  <Star className="h-2.5 w-2.5" />
                </span>
              )}
              {c.is_primary && (
                <span
                  title="Primary contact"
                  className="rounded-full bg-blue-50 px-1.5 py-0 text-[10px] font-medium text-blue-700 ring-1 ring-inset ring-blue-200"
                >
                  Primary
                </span>
              )}
              {inactive && (
                <span className="rounded-full bg-zinc-100 px-1.5 py-0 text-[10px] font-medium text-zinc-600">
                  Inactive
                </span>
              )}
            </div>
            {subtitle && (
              <div
                className={
                  'truncate text-xs ' +
                  // role-only contact: bump title weight slightly to compensate
                  // for the de-emphasized name slot above
                  (name ? 'text-muted-foreground' : 'text-foreground/70')
                }
              >
                {subtitle}
              </div>
            )}
          </div>
        </div>
      </td>

      {/* Company */}
      <td className="px-4 py-3">
        {c.firm ? (
          <div className="min-w-0">
            <div className="truncate font-medium text-foreground">{c.firm.party_name}</div>
            {c.firm.country_code && (
              <div className="text-xs text-muted-foreground">{c.firm.country_code}</div>
            )}
          </div>
        ) : (
          <span className="text-xs text-muted-foreground">{'\u2014'}</span>
        )}
      </td>

      {/* Contact */}
      <td className="px-4 py-3">
        <div className="space-y-0.5 text-xs">
          {c.email && (
            <div className="inline-flex items-center gap-1 text-muted-foreground">
              <Mail className="h-3 w-3 shrink-0" />
              <span className="truncate">{c.email}</span>
            </div>
          )}
          {(c.phone_e164 || c.phone_mobile) && (
            <div className="inline-flex items-center gap-1 text-muted-foreground">
              <Phone className="h-3 w-3 shrink-0" />
              <span>{c.phone_e164 || c.phone_mobile}</span>
            </div>
          )}
          {!c.email && !c.phone_e164 && !c.phone_mobile && (
            <span className="text-muted-foreground">{'\u2014'}</span>
          )}
        </div>
      </td>

      {/* Last activity */}
      <td className="px-4 py-3 text-xs text-muted-foreground">
        {c.last_contacted_at ? fmtRelative(c.last_contacted_at) : '\u2014'}
      </td>
    </tr>
  );
}
