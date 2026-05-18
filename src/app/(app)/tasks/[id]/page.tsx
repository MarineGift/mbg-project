import { createSupabaseServerClient } from '@/lib/supabase/server';
import { notFound } from 'next/navigation';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { ArrowLeft, Building2, Calendar, Flag, CheckCircle2, Circle } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { TaskStatusButton } from '@/components/tasks/task-status-button';

interface Props { params: { id: string } }

const PRIORITY_LABEL: Record<string, string> = {
  urgent: '긴급', high: '높음', medium: '보통', low: '낮음',
};
const PRIORITY_COLOR: Record<string, string> = {
  urgent: 'text-red-500', high: 'text-orange-500',
  medium: 'text-yellow-500', low: 'text-blue-400',
};
const STATUS_LABEL: Record<string, string> = {
  todo: 'To Do', in_progress: 'In Progress', done: '완료', cancelled: '취소',
};

export default async function TaskDetailPage({ params }: Props) {
  const supabase = await createSupabaseServerClient();

  const { data: task, error } = await supabase
    .schema('app')
    .from('tasks')
    .select('id, title, description, status, priority, due_date, created_at, party_id')
    .eq('id', params.id)
    .maybeSingle();

  if (error || !task) notFound();
  const t = task as any;

  let party: any = null;
  if (t.party_id) {
    const { data } = await supabase.schema('app').from('parties')
      .select('id, name, module').eq('id', t.party_id).maybeSingle();
    party = data;
  }

  const isPastDue = t.due_date && new Date(t.due_date) < new Date() && t.status !== 'done';
  const pColor = PRIORITY_COLOR[t.priority] ?? 'text-muted-foreground';

  return (
    <div className="max-w-2xl mx-auto p-6 space-y-4">
      <div className="flex items-center justify-between">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/tasks"><ArrowLeft className="h-4 w-4 mr-1" />Tasks</Link>
        </Button>
        <Badge variant={t.status === 'done' ? 'default' : 'secondary'}>
          {STATUS_LABEL[t.status] ?? t.status}
        </Badge>
      </div>
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 flex-shrink-0">
              {t.status === 'done'
                ? <CheckCircle2 className="h-5 w-5 text-primary" />
                : <Circle className="h-5 w-5 text-muted-foreground" />}
            </div>
            <div className="flex-1">
              <h1 className="text-xl font-semibold leading-tight">{t.title}</h1>
              {t.description && (
                <p className="mt-1.5 text-sm text-muted-foreground leading-relaxed">
                  {t.description}
                </p>
              )}
            </div>
          </div>
        </CardHeader>
        <CardContent className="pt-0 space-y-4">
          <div className="border-t pt-3 grid grid-cols-2 gap-3 text-sm">
            <div className="flex items-center gap-2">
              <Flag className={'h-3.5 w-3.5 ' + pColor} />
              <span className="text-muted-foreground">우선순위</span>
              <span className={'font-medium ' + pColor}>
                {PRIORITY_LABEL[t.priority] ?? t.priority ?? '-'}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <Calendar className={'h-3.5 w-3.5 ' + (isPastDue ? 'text-red-500' : 'text-muted-foreground')} />
              <span className="text-muted-foreground">마감일</span>
              <span className={'font-medium ' + (isPastDue ? 'text-red-500' : '')}>
                {t.due_date ? format(new Date(t.due_date), 'MM/dd (EEE)', { locale: ko }) : '-'}
              </span>
            </div>
            {party && (
              <div className="flex items-center gap-2 col-span-2">
                <Building2 className="h-3.5 w-3.5 text-muted-foreground" />
                <span className="text-muted-foreground">거래처</span>
                <Link
                  href={'/' + (party.module ?? 'paper-companies') + '/parties/' + t.party_id}
                  className="font-medium hover:underline"
                >
                  {party.name}
                </Link>
              </div>
            )}
            <div className="col-span-2 text-xs text-muted-foreground">
              생성: {format(new Date(t.created_at), 'PPP', { locale: ko })}
            </div>
          </div>
          <div className="border-t pt-3 flex items-center gap-2 flex-wrap">
            <span className="text-xs text-muted-foreground">상태 변경:</span>
            {['todo', 'in_progress', 'done'].map((s) => (
              <TaskStatusButton
                key={s} taskId={t.id} status={s}
                current={t.status} label={STATUS_LABEL[s]}
              />
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}