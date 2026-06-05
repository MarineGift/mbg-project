'use client';

import { useState } from 'react';
import type { TimelineItem } from './timeline-types';

function startOfMonth(d: Date) {
  return new Date(d.getFullYear(), d.getMonth(), 1);
}
function addMonths(d: Date, n: number) {
  return new Date(d.getFullYear(), d.getMonth() + n, 1);
}
function ymd(d: Date) {
  // local date as YYYY-MM-DD (avoids UTC shift from toISOString)
  const m = `${d.getMonth() + 1}`.padStart(2, '0');
  const day = `${d.getDate()}`.padStart(2, '0');
  return `${d.getFullYear()}-${m}-${day}`;
}

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토'];

export function CalendarView({ items }: { items: TimelineItem[] }) {
  const [month, setMonth] = useState(() => startOfMonth(new Date()));

  const first = startOfMonth(month);
  const gridStart = new Date(first);
  gridStart.setDate(1 - first.getDay()); // back up to the Sunday

  const days: Date[] = [];
  for (let i = 0; i < 42; i++) {
    const d = new Date(gridStart);
    d.setDate(gridStart.getDate() + i);
    days.push(d);
  }

  const itemsOn = (d: Date) => {
    const key = ymd(d);
    return items.filter((it) => it.start && it.end && it.start <= key && key <= it.end);
  };

  return (
    <div className="select-none">
      <div className="mb-2 flex items-center justify-between">
        <button className="rounded border px-2 py-1 text-sm" onClick={() => setMonth(addMonths(month, -1))}>
          이전
        </button>
        <div className="text-sm font-medium">
          {month.getFullYear()}.{month.getMonth() + 1}
        </div>
        <button className="rounded border px-2 py-1 text-sm" onClick={() => setMonth(addMonths(month, 1))}>
          다음
        </button>
      </div>

      <div className="grid grid-cols-7 gap-px text-xs">
        {WEEKDAYS.map((d) => (
          <div key={d} className="py-1 text-center font-medium text-muted-foreground">
            {d}
          </div>
        ))}
        {days.map((d, i) => {
          const inMonth = d.getMonth() === month.getMonth();
          const dayItems = itemsOn(d);
          return (
            <div
              key={i}
              className={`min-h-[72px] border p-1 ${inMonth ? '' : 'bg-muted/40 text-muted-foreground'}`}
            >
              <div className="text-right">{d.getDate()}</div>
              <div className="mt-0.5 space-y-0.5">
                {dayItems.slice(0, 3).map((it) => {
                  const chip = (
                    <div
                      className="truncate rounded px-1 text-[10px] text-white"
                      style={{ backgroundColor: it.color ?? '#2563eb' }}
                      title={it.label}
                    >
                      {it.label}
                    </div>
                  );
                  return it.href ? (
                    <a key={it.id} href={it.href}>
                      {chip}
                    </a>
                  ) : (
                    <div key={it.id}>{chip}</div>
                  );
                })}
                {dayItems.length > 3 && (
                  <div className="text-[10px] text-muted-foreground">+{dayItems.length - 3}</div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
