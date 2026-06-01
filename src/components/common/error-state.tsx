'use client';

import { AlertCircle, RefreshCw } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface ErrorStateProps {
  title?: string;
  description?: string;
  /** the reset function passed from the Server Component error boundary */
  onRetry?: () => void;
  className?: string;
}

export function ErrorState({
  title,
  description,
  onRetry,
  className,
}: ErrorStateProps) {
  const t = useTranslations('common');
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center text-center p-12',
        className,
      )}
    >
      <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10 text-destructive">
        <AlertCircle className="h-6 w-6" />
      </div>
      <h3 className="text-base font-medium mb-1">
        {title ?? t('errorTitle')}
      </h3>
      {description && (
        <p className="text-sm text-muted-foreground max-w-md">{description}</p>
      )}
      {onRetry && (
        <Button onClick={onRetry} className="mt-6" variant="outline">
          <RefreshCw className="h-4 w-4" />
          {t('errorRetry')}
        </Button>
      )}
    </div>
  );
}
