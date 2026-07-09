// src/components/common/contact-method-badge.tsx
'use client';

// Small badge showing how a party prefers to be contacted
// (app.parties.preferred_contact_method, migration_027).
// For web_form / portal a form-link icon is shown when contact_form_url exists.

import { Mail, FileText, KeySquare, Phone, MessageCircle, ExternalLink } from 'lucide-react';
import { cn } from '@/lib/utils';

export type ContactMethod = 'email' | 'web_form' | 'portal' | 'phone' | 'other';

const METHOD_META: Record<
  ContactMethod,
  { label: string; className: string; Icon: typeof Mail }
> = {
  email: {
    label: 'Email',
    className:
      'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300',
    Icon: Mail,
  },
  web_form: {
    label: 'Web form',
    className:
      'bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300',
    Icon: FileText,
  },
  portal: {
    label: 'Portal',
    className:
      'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300',
    Icon: KeySquare,
  },
  phone: {
    label: 'Phone',
    className:
      'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
    Icon: Phone,
  },
  other: {
    label: 'Other',
    className: 'bg-muted text-muted-foreground',
    Icon: MessageCircle,
  },
};

interface Props {
  method: string | null | undefined;
  formUrl?: string | null;
  size?: 'sm' | 'md';
  /** icon-only compact mode for dense tables */
  compact?: boolean;
  className?: string;
}

export function ContactMethodBadge({
  method,
  formUrl,
  size = 'md',
  compact = false,
  className,
}: Props) {
  if (!method) return null;
  const meta = METHOD_META[method as ContactMethod];
  if (!meta) return null;

  const { label, className: colors, Icon } = meta;
  const isFormBased = method === 'web_form' || method === 'portal';
  const showLink = isFormBased && !!formUrl;

  const badge = (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full font-medium whitespace-nowrap',
        size === 'sm' ? 'px-1.5 py-0.5 text-[10px]' : 'px-2 py-0.5 text-xs',
        colors,
        className,
      )}
      title={showLink ? `${label} \u2192 ${formUrl}` : label}
    >
      <Icon className={size === 'sm' ? 'h-2.5 w-2.5' : 'h-3 w-3'} />
      {!compact && label}
      {showLink && (
        <ExternalLink className={size === 'sm' ? 'h-2.5 w-2.5' : 'h-3 w-3'} />
      )}
    </span>
  );

  if (showLink) {
    return (
      <a
        href={formUrl as string}
        target="_blank"
        rel="noopener noreferrer"
        className="hover:opacity-80"
        onClick={(e) => e.stopPropagation()}
      >
        {badge}
      </a>
    );
  }
  return badge;
}
