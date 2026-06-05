'use client';

import type { TimelineItem } from './timeline-types';

const DAY_MS = 86_400_000;
const DAY_PX = 28; // column width per day

function daysBetween(a: Date, b: Date) {
  return Math.round((b.getTime() - a.getTime()) / DAY_MS);
}

export function GanttChart({
  items,
  className,
}: {
  items: TimelineItem[];
  className?: string;
}) {
  const valid = items.filter((i) => i.start && i.end);
  if (valid.length === 0) {
    return <div className="p-6 text-sm text-muted-foreground">표시할 일정이 없습니다.</div>;
  }

  const startTimes = valid.map((i) => new Date(i.start).getTime());
  const endTimes = valid.map((i) => new Date(i.end).getTime());
  const min = new Date(Math.min(...startTimes));
  const max = new Date(Math.max(...endTimes));
  min.setDate(min.getDate() - 2);
  max.setDate(max.getDate() + 2);

  const totalDays = Math.max(1, daysBetween(min, max));
  const width = totalDays * DAY_PX;

  // month ticks
  const ticks: { left: number; label: string }[] = [];
  const cur = new Date(min);
  while (cur <= max) {
    if (cur.getDate() === 1 || ticks.length === 0) {
      ticks.push({
        left: daysBetween(min, cur) * DAY_PX,
        label: `${cur.getFullYear()}.${cur.getMonth() + 1}`,
      });
    }
    cur.setDate(cur.getDate() + 1);
  }

  // "today" marker
  const today = new Date();
  const showToday = today >= min && today <= max;
  const todayLeft = daysBetween(min, today) * DAY_PX;

  return (
    <div className={`overflow-x-auto ${className ?? ''}`}>
      <div style={{ width }} className="relative min-w-full">
        <div className="relative h-6 border-b text-xs text-muted-foreground">
          {ticks.map((t, i) => (
            <span key={i} className="absolute top-0" style={{ left: t.left }}>
              {t.label}
            </span>
          ))}
        </div>

        <div className="relative divide-y">
          {showToday && (
            <div
              className="pointer-events-none absolute bottom-0 top-0 z-10 w-px bg-red-500/70"
              style={{ left: todayLeft }}
              title="오늘"
            />
          )}

          {valid.map((item) => {
            const s = new Date(item.start);
            const e = new Date(item.end);
            const left = daysBetween(min, s) * DAY_PX;
            const w = Math.max(DAY_PX, (daysBetween(s, e) + 1) * DAY_PX);
            const pct = Math.max(0, Math.min(100, item.progress ?? 0));
            const color = item.color ?? '#2563eb';

            // track = same color at ~20% alpha (assumes 6-digit hex), fill = full color
            const bar = (
              <div
                className="absolute top-1.5 h-5 overflow-hidden rounded text-xs leading-5"
                style={{ left, width: w, backgroundColor: `${color}33` }}
                title={`${item.label} · ${pct}%`}
              >
                <div
                  className="absolute inset-y-0 left-0"
                  style={{ width: `${pct}%`, backgroundColor: color }}
                />
                <span className="relative z-10 block truncate px-2 text-foreground">
                  {item.label}
                </span>
              </div>
            );

            return (
              <div key={item.id} className="relative h-8">
                {item.href ? <a href={item.href}>{bar}</a> : bar}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
