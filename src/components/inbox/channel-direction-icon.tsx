'use client';

import {
  Mail,
  MessageSquare,
  Phone,
  Smartphone,
  HelpCircle,
  ArrowDownLeft,
  ArrowUpRight,
} from 'lucide-react';
import type {
  CommunicationChannel,
  CommunicationDirection,
} from '@/types/inbox';
import { cn } from '@/lib/utils';

interface Props {
  channel: CommunicationChannel;
  direction: CommunicationDirection;
  className?: string;
}

const CHANNEL_ICON: Record<CommunicationChannel, typeof Mail> = {
  email: Mail,
  slack: MessageSquare,
  sms: Smartphone,
  phone: Phone,
  other: HelpCircle,
};

const CHANNEL_COLOR: Record<CommunicationChannel, string> = {
  email: 'text-blue-600 dark:text-blue-400',
  slack: 'text-purple-600 dark:text-purple-400',
  sms: 'text-emerald-600 dark:text-emerald-400',
  phone: 'text-orange-600 dark:text-orange-400',
  other: 'text-muted-foreground',
};

export function ChannelDirectionIcon({
  channel,
  direction,
  className,
}: Props) {
  const Icon = CHANNEL_ICON[channel];
  const colorCls = CHANNEL_COLOR[channel];
  const DirIcon = direction === 'inbound' ? ArrowDownLeft : ArrowUpRight;

  return (
    <span
      className={cn('inline-flex items-center gap-1 shrink-0', colorCls, className)}
      title={`${channel} ${direction}`}
    >
      <Icon className="h-4 w-4" />
      <DirIcon className="h-3 w-3 opacity-60" />
    </span>
  );
}
