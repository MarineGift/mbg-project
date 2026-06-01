'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Bell, BellOff, AlertCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';
import { useUiStore } from '@/lib/stores/ui-store';

/**
 * Browser Notification permission + opt-in toggle.
 * Q9 — default off.
 * Actual notification dispatch is handled in the Realtime message handler.
 */
export function NotificationsForm() {
  const t = useTranslations('settings.notifications');
  const notificationsEnabled = useUiStore((s) => s.notificationsEnabled);
  const setNotificationsEnabled = useUiStore((s) => s.setNotificationsEnabled);

  const [permission, setPermission] = useState<NotificationPermission | 'unsupported'>(
    'default',
  );

  useEffect(() => {
    if (typeof window === 'undefined' || !('Notification' in window)) {
      setPermission('unsupported');
      return;
    }
    setPermission(Notification.permission);
  }, []);

  const handleEnable = async () => {
    if (permission === 'unsupported') {
      toast.error(t('notSupported'));
      return;
    }
    if (permission === 'denied') {
      toast.error(t('permissionDenied'));
      return;
    }
    if (permission === 'default') {
      const result = await Notification.requestPermission();
      setPermission(result);
      if (result === 'granted') {
        setNotificationsEnabled(true);
        toast.success(t('enabled'));
      } else {
        toast.warning(t('permissionDenied'));
      }
      return;
    }
    // already granted — just toggle store
    setNotificationsEnabled(!notificationsEnabled);
    toast.success(notificationsEnabled ? t('disabled') : t('enabled'));
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {notificationsEnabled && permission === 'granted' ? (
            <Bell className="h-5 w-5" />
          ) : (
            <BellOff className="h-5 w-5 text-muted-foreground" />
          )}
          {t('title')}
        </CardTitle>
        <CardDescription>{t('description')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {permission === 'unsupported' && (
          <p className="text-sm text-muted-foreground flex items-start gap-2">
            <AlertCircle className="h-4 w-4 mt-0.5 shrink-0" />
            {t('notSupported')}
          </p>
        )}

        {permission === 'denied' && (
          <p className="text-sm text-destructive flex items-start gap-2">
            <AlertCircle className="h-4 w-4 mt-0.5 shrink-0" />
            {t('permissionDenied')}
          </p>
        )}

        {permission !== 'unsupported' && permission !== 'denied' && (
          <div className="flex items-center gap-2">
            <Checkbox
              id="notifications-toggle"
              checked={notificationsEnabled && permission === 'granted'}
              onCheckedChange={handleEnable}
            />
            <Label htmlFor="notifications-toggle" className="cursor-pointer">
              {t('toggle')}
            </Label>
          </div>
        )}

        {permission === 'granted' && (
          <p className="text-xs text-muted-foreground">{t('grantedHint')}</p>
        )}

        {permission === 'default' && (
          <Button onClick={handleEnable} variant="outline" size="sm">
            <Bell className="h-4 w-4" />
            {t('requestPermission')}
          </Button>
        )}
      </CardContent>
    </Card>
  );
}
