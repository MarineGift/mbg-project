// Dependency-free chip for deal cards. Drop a campaign's name + color in.
export function CampaignChip({
  name,
  color,
}: {
  name: string;
  color?: string | null;
}) {
  return (
    <span className="inline-flex max-w-full items-center gap-1 truncate rounded-full border px-2 py-0.5 text-xs font-medium text-muted-foreground">
      <span
        className="h-2 w-2 shrink-0 rounded-full"
        style={{ backgroundColor: color ?? '#94a3b8' }}
      />
      <span className="truncate">{name}</span>
    </span>
  );
}
