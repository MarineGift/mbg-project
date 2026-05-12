'use client';

import { AlertCircle, RefreshCw } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface ErrorStateProps {
  title?: string;
  description?: string;
  /** Server Component 에러 boundary에서 reset 함수 전달 */
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
