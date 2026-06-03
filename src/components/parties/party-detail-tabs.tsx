'use client';

import type { ReactNode } from 'react';
import { useCallback } from 'react';
import { useSearchParams } from 'next/navigation';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';

const TAB_VALUES = [
  'overview',
  'activity',
  'communications',
  'contacts',
  'tasks',
  'notes',
] as const;
type TabValue = (typeof TAB_VALUES)[number];
const DEFAULT_TAB: TabValue = 'overview';
const TRIGGER = 'text-sm h-7';

interface PartyDetailTabsProps {
  overview: ReactNode;
  activity: ReactNode;
  communications: ReactNode;
  contacts: ReactNode;
  tasks: ReactNode;
  notes: ReactNode;
}

export function PartyDetailTabs({
  overview,
  activity,
  communications,
  contacts,
  tasks,
  notes,
}: PartyDetailTabsProps) {
  const searchParams = useSearchParams();
  const fromUrl = searchParams.get('tab');
  const initial: TabValue = (TAB_VALUES as readonly string[]).includes(fromUrl ?? '')
    ? (fromUrl as TabValue)
    : DEFAULT_TAB;

  const handleChange = useCallback((value: string) => {
    const params = new URLSearchParams(window.location.search);
    if (value === DEFAULT_TAB) {
      params.delete('tab');
    } else {
      params.set('tab', value);
    }
    const qs = params.toString();
    const url = qs
      ? `${window.location.pathname}?${qs}`
      : window.location.pathname;
    window.history.replaceState(null, '', url);
  }, []);

  return (
    <Tabs defaultValue={initial} onValueChange={handleChange} className="w-full">
      <TabsList className="h-auto flex-wrap justify-start gap-1">
        <TabsTrigger value="overview" className={TRIGGER}>Overview</TabsTrigger>
        <TabsTrigger value="activity" className={TRIGGER}>Activity</TabsTrigger>
        <TabsTrigger value="communications" className={TRIGGER}>Communications</TabsTrigger>
        <TabsTrigger value="contacts" className={TRIGGER}>Contacts</TabsTrigger>
        <TabsTrigger value="tasks" className={TRIGGER}>Tasks</TabsTrigger>
        <TabsTrigger value="notes" className={TRIGGER}>Notes</TabsTrigger>
      </TabsList>

      <TabsContent value="overview" className="space-y-4">{overview}</TabsContent>
      <TabsContent value="activity" className="space-y-4">{activity}</TabsContent>
      <TabsContent value="communications" className="space-y-4">{communications}</TabsContent>
      <TabsContent value="contacts" className="space-y-4">{contacts}</TabsContent>
      <TabsContent value="tasks" className="space-y-4">{tasks}</TabsContent>
      <TabsContent value="notes" className="space-y-4">{notes}</TabsContent>
    </Tabs>
  );
}
