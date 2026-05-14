'use client';

/**
 * components/inbox/channel-direction-icon.tsx
 *
 * 통신 채널 + 방향을 한 줄 아이콘으로 표시.
 * 인박스 목록 / 활동 타임라인에서 공통 사용.
 *
 * 변경 이력:
 *   - 2026-05-12 (1차): 9개 채널 매핑 + defensive fallback.
 *   - 2026-05-12 (2차): 11개로 확장 (slack, other 추가).
 *   - 2026-05-12 (3차): 12개로 확장 (webform = Globe).
 *                       DB enum app.channel_type과 1:1 매칭.
 */

import {
  Mail,
  MessageSquare,
  MessageCircle,
  Phone,
  Smartphone,
  Linkedin,
  Users,
  Video,
  Globe,
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
  phone: Phone,
  sms: Smartphone,
  linkedin: Linkedin,
  kakaotalk: MessageSquare,
  wechat: MessageSquare,
  whatsapp: MessageCircle,
  in_person: Users,
  video_call: Video,
  webform: Globe,
  slack: MessageSquare,
  other: HelpCircle,
};

const CHANNEL_COLOR: Record<CommunicationChannel, string> = {
  email: 'text-blue-600 dark:text-blue-400',
  phone: 'text-orange-600 dark:text-orange-400',
  sms: 'text-emerald-600 dark:text-emerald-400',
  linkedin: 'text-sky-700 dark:text-sky-400',
  kakaotalk: 'text-yellow-600 dark:text-yellow-400',
  wechat: 'text-green-600 dark:text-green-400',
  whatsapp: 'text-green-500 dark:text-green-400',
  in_person: 'text-indigo-600 dark:text-indigo-400',
  video_call: 'text-violet-600 dark:text-violet-400',
  webform: 'text-slate-600 dark:text-slate-400',
  slack: 'text-purple-600 dark:text-purple-400',
  other: 'text-muted-foreground',
};

export function ChannelDirectionIcon({
  channel,
  direction,
  className,
}: Props) {
  // Defensive fallback — DB enum이 향후 확장되어도 React render 에러 방지.
  const Icon = CHANNEL_ICON[channel] ?? HelpCircle;
  const colorCls = CHANNEL_COLOR[channel] ?? 'text-muted-foreground';
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
