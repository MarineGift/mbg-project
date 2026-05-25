'use client';

import { useState, useTransition } from 'react';
import type { EmailTemplate } from '@/lib/queries/email-templates';
import { TemplateFormModal } from './template-form-modal';
import {
  deleteEmailTemplate,
  toggleEmailTemplateActive,
} from '@/lib/actions/email-templates';

interface Props {
  initialTemplates: EmailTemplate[];
}

export function TemplateListClient({ initialTemplates }: Props) {
  const [templates, setTemplates] = useState(initialTemplates);
  const [modalState, setModalState] = useState<{
    open: boolean;
    editing: EmailTemplate | null;
  }>({ open: false, editing: null });
  const [isPending, startTransition] = useTransition();

  function handleOpenCreate() {
    setModalState({ open: true, editing: null });
  }

  function handleOpenEdit(template: EmailTemplate) {
    setModalState({ open: true, editing: template });
  }

  function handleClose() {
    setModalState({ open: false, editing: null });
  }

  function handleSaved(saved: EmailTemplate) {
    setTemplates((prev) => {
      const idx = prev.findIndex((t) => t.id === saved.id);
      if (idx >= 0) {
        const next = [...prev];
        next[idx] = saved;
        return next;
      }
      return [saved, ...prev];
    });
    handleClose();
  }

  function handleToggle(template: EmailTemplate) {
    const next = !template.isActive;
    startTransition(async () => {
      const result = await toggleEmailTemplateActive(template.id, next);
      if (result.ok) {
        setTemplates((prev) =>
          prev.map((t) =>
            t.id === template.id ? { ...t, isActive: next } : t,
          ),
        );
      } else {
        alert('Failed to toggle: ' + result.errorMessage);
      }
    });
  }

  function handleDelete(template: EmailTemplate) {
    const msg = 'Delete template "' + template.name + '"? This cannot be undone.';
    if (!confirm(msg)) return;
    startTransition(async () => {
      const result = await deleteEmailTemplate(template.id);
      if (result.ok) {
        setTemplates((prev) => prev.filter((t) => t.id !== template.id));
      } else {
        alert('Failed to delete: ' + result.errorMessage);
      }
    });
  }

  if (templates.length === 0) {
    return (
      <>
        <div className="rounded-lg border border-dashed border-gray-300 p-12 text-center">
          <h3 className="text-base font-medium text-gray-900">No templates yet</h3>
          <p className="mt-1 text-sm text-gray-500">
            Create your first email template to streamline outreach.
          </p>
          <button
            type="button"
            onClick={handleOpenCreate}
            className="mt-4 inline-flex items-center rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            + Create template
          </button>
        </div>
        <TemplateFormModal
          open={modalState.open}
          editing={modalState.editing}
          onClose={handleClose}
          onSaved={handleSaved}
        />
      </>
    );
  }

  return (
    <>
      <div className="mb-4 flex justify-end">
        <button
          type="button"
          onClick={handleOpenCreate}
          className="inline-flex items-center rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          + Create template
        </button>
      </div>
      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Name
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Subject
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Module
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Category
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Active
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {templates.map((template) => (
              <tr key={template.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm font-medium text-gray-900">
                  {template.name}
                </td>
                <td className="px-4 py-3 text-sm text-gray-700">
                  <span className="line-clamp-1 block max-w-xs">
                    {template.subject}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-gray-700">
                  {template.module ?? '-'}
                </td>
                <td className="px-4 py-3 text-sm text-gray-700">
                  {template.category ?? '-'}
                </td>
                <td className="px-4 py-3 text-sm">
                  <button
                    type="button"
                    onClick={() => handleToggle(template)}
                    disabled={isPending}
                    aria-label={
                      template.isActive ? 'Deactivate template' : 'Activate template'
                    }
                    className={
                      'inline-flex h-5 w-9 items-center rounded-full transition ' +
                      (template.isActive ? 'bg-green-500' : 'bg-gray-300') +
                      (isPending ? ' opacity-50' : '')
                    }
                  >
                    <span
                      className={
                        'inline-block h-4 w-4 transform rounded-full bg-white shadow transition ' +
                        (template.isActive ? 'translate-x-4' : 'translate-x-0.5')
                      }
                    />
                  </button>
                </td>
                <td className="px-4 py-3 text-right text-sm">
                  <button
                    type="button"
                    onClick={() => handleOpenEdit(template)}
                    className="mr-3 text-blue-600 hover:text-blue-900"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDelete(template)}
                    disabled={isPending}
                    className="text-red-600 hover:text-red-900 disabled:opacity-50"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <TemplateFormModal
        open={modalState.open}
        editing={modalState.editing}
        onClose={handleClose}
        onSaved={handleSaved}
      />
    </>
  );
}
