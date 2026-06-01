/**
 * components/providers/toast-provider.tsx
 *
 * Toast container - uses the sonner library.
 *
 * Usage pattern:
 *   import { toast } from 'sonner';
 *   toast.success('Draft approved');
 *   toast.error('Approval failed', { description: error.message });
 */

'use client';

import { Toaster } from 'sonner';

export function ToastProvider() {
  return (
    <Toaster
      position="top-right"
      richColors
      closeButton
      duration={4500}
      toastOptions={{
        classNames: {
          toast:
            'group toast group-[.toaster]:bg-background group-[.toaster]:text-foreground group-[.toaster]:border-border group-[.toaster]:shadow-lg',
        },
      }}
    />
  );
}
