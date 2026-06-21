/**
 * app/(app)/settings/email-templates/page.tsx
 *
 * Server component for managing email templates.
 * Track B / Stage 29-c.
 */

import { listEmailTemplates } from '@/lib/queries/email-templates';
import { TemplateListClient } from '@/components/settings/email-templates/template-list';

export const dynamic = 'force-dynamic';

export default async function EmailTemplatesPage() {
  const templates = await listEmailTemplates();

  return (
    <div className="mx-auto max-w-app p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-semibold text-gray-900">Email Templates</h1>
        <p className="mt-1 text-sm text-gray-500">
          Reusable email templates for sequences and one-off sends. Use{' '}
          <code className="rounded bg-gray-100 px-1 py-0.5 text-xs">
            {'{{variable}}'}
          </code>{' '}
          placeholders for personalization.
        </p>
      </div>
      <TemplateListClient initialTemplates={templates} />
    </div>
  );
}
