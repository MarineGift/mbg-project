'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useTranslations } from 'next-intl';
import { Loader2, Save } from 'lucide-react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { createTask, updateTaskDetails } from '@/lib/actions/tasks';
import type { ModuleType } from '@/types/ai';
import type { TaskPriority, TaskRow } from '@/types/task';

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** create 컨텍스트 — 빈 폼이지만 partyId/engagementId 자동 연결 */
  partyId?: string | null;
  engagementId?: string | null;
  module?: ModuleType | null;
  /** edit 모드면 기존 task */
  existing?: TaskRow | null;
}

const schema = z.object({
  title: z.string().min(1, 'Required').max(500),
  description: z.string().max(5000).optional().or(z.literal('')),
  priority: z.enum(['low', 'medium', 'high', 'urgent']),
  dueAt: z.string().optional().or(z.literal('')),
});

type FormValues = z.infer<typeof schema>;

const PRIORITIES: readonly TaskPriority[] = ['urgent', 'high', 'medium', 'low'] as const;

export function TaskFormDialog({
  open,
  onOpenChange,
  partyId,
  engagementId,
  module,
  existing,
}: Props) {
  const router = useRouter();
  const t = useTranslations('taskForm');
  const tPriority = useTranslations('tasks.priority');
  const [isPending, startTransition] = useTransition();

  const {
    register,
    handleSubmit,
    formState: { errors, isDirty },
    setValue,
    watch,
    reset,
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: existing
      ? {
          title: existing.title,
          description: existing.description ?? '',
          priority: existing.priority,
          dueAt: existing.dueAt ? existing.dueAt.slice(0, 16) : '', // datetime-local format
        }
      : {
          title: '',
          description: '',
          priority: 'medium',
          dueAt: '',
        },
  });

  const priority = watch('priority');

  const onSubmit = (values: FormValues) => {
    startTransition(async () => {
      const dueAtIso = values.dueAt ? new Date(values.dueAt).toISOString() : null;
      const payload = {
        title: values.title,
        description: values.description || null,
        priority: values.priority,
        dueAt: dueAtIso,
        partyId: existing?.partyId ?? partyId ?? null,
        engagementId: existing?.engagementId ?? engagementId ?? null,
        module: existing?.module ?? module ?? null,
      };

      const result = existing
        ? await updateTaskDetails({ taskId: existing.id, ...payload })
        : await createTask(payload);

      if (result.ok) {
        toast.success(existing ? t('updated') : t('created'));
        onOpenChange(false);
        reset();
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? t('saveFailed'));
      }
    });
  };

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!isPending) onOpenChange(v); }}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{existing ? t('editTitle') : t('createTitle')}</DialogTitle>
          <DialogDescription>
            {existing ? t('editDescription') : t('createDescription')}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-3" noValidate>
          <div className="space-y-2">
            <Label htmlFor="task-title">{t('title')} *</Label>
            <Input
              id="task-title"
              {...register('title')}
              disabled={isPending}
              autoFocus
              placeholder={t('titlePlaceholder')}
              aria-invalid={errors.title ? 'true' : undefined}
            />
            {errors.title && (
              <p className="text-xs text-destructive">{errors.title.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="task-description">{t('description')}</Label>
            <Textarea
              id="task-description"
              {...register('description')}
              disabled={isPending}
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="task-priority">{t('priority')}</Label>
              <Select
                value={priority}
                onValueChange={(v) =>
                  setValue('priority', v as TaskPriority, { shouldDirty: true })
                }
                disabled={isPending}
              >
                <SelectTrigger id="task-priority">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PRIORITIES.map((p) => (
                    <SelectItem key={p} value={p}>
                      {tPriority(p)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="task-due">{t('dueAt')}</Label>
              <Input
                id="task-due"
                type="datetime-local"
                {...register('dueAt')}
                disabled={isPending}
              />
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isPending}
            >
              {t('cancel')}
            </Button>
            <Button type="submit" disabled={isPending || (Boolean(existing) && !isDirty)}>
              {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
              {existing ? t('save') : t('create')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
