'use client';

import { useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { AlertCircle } from 'lucide-react';

export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const t = useTranslations('common');

  useEffect(() => {
    // in production, send to Sentry or similar
    // eslint-disable-next-line no-console
    console.error('[app:error-boundary]', error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="text-center max-w-md">
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10">
          <AlertCircle className="h-6 w-6 text-destructive" />
        </div>
        <h2 className="text-xl font-semibold mb-2">{t('errorTitle')}</h2>
        <p className="text-sm text-muted-foreground mb-6">{error.message}</p>
        {error.digest && (
          <p className="text-xs text-muted-foreground mb-4 font-mono">
            digest: {error.digest}
          </p>
        )}
        <Button onClick={reset}>{t('errorRetry')}</Button>
      </div>
    </div>
  );
}
