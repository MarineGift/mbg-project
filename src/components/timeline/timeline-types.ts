// Shared shape consumed by both GanttChart and CalendarView.
// Feed it from deals OR todos -> the views are identical.
export type TimelineItem = {
  id: string;
  label: string;
  start: string; // 'YYYY-MM-DD'
  end: string;   // 'YYYY-MM-DD'
  color?: string;
  progress?: number; // 0-100 stage progress (e.g. effective win-probability). Drives the bar fill.
  group?: string;    // optional: stage / campaign / status for lanes or filtering
  href?: string;     // optional: link to the deal/task detail
};
