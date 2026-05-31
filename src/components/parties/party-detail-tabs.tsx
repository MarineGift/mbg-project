'use client';

import type { ReactNode } from 'react';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';

interface PartyDetailTabsProps {
  overview: ReactNode;
  activity: ReactNode;
  communications: ReactNode;
  contacts: ReactNode;
  engagements: ReactNode;
  tasks: ReactNode;
  notes: ReactNode;
}

const TRIGGER = 'text-sm h-7';

export function PartyDetailTabs({
  overview,
  activity,
  communications,
  contacts,
  engagements,
  tasks,
  notes,
}: PartyDetailTabsProps) {
  return (
    <Tabs defaultValue="overview" className="w-full">
      <TabsList className="h-auto flex-wrap justify-start gap-1">
        <TabsTrigger value="overview" className={TRIGGER}>Overview</TabsTrigger>
        <TabsTrigger value="activity" className={TRIGGER}>Activity</TabsTrigger>
        <TabsTrigger value="communications" className={TRIGGER}>Communications</TabsTrigger>
        <TabsTrigger value="contacts" className={TRIGGER}>Contacts</TabsTrigger>
        <TabsTrigger value="engagements" className={TRIGGER}>Engagements</TabsTrigger>
        <TabsTrigger value="tasks" className={TRIGGER}>Tasks</TabsTrigger>
        <TabsTrigger value="notes" className={TRIGGER}>Notes</TabsTrigger>
      </TabsList>

      <TabsContent value="overview" className="space-y-4">{overview}</TabsContent>
      <TabsContent value="activity" className="space-y-4">{activity}</TabsContent>
      <TabsContent value="communications" className="space-y-4">{communications}</TabsContent>
      <TabsContent value="contacts" className="space-y-4">{contacts}</TabsContent>
      <TabsContent value="engagements" className="space-y-4">{engagements}</TabsContent>
      <TabsContent value="tasks" className="space-y-4">{tasks}</TabsContent>
      <TabsContent value="notes" className="space-y-4">{notes}</TabsContent>
    </Tabs>
  );
}