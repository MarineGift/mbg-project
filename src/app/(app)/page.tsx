/**
 * app/(app)/page.tsx
 *
 * 통합 대시보드 (Q2 결정).
 * Phase 1에서는 환영 메시지 + 핵심 카운트 placeholder.
 * Part 3 이후 실제 큐 카운트·최근 활동을 위젯으로 채운다.
 */

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Sparkles, Inbox, CheckSquare } from 'lucide-react';
import { requireAuthOrRedirect } from '@/lib/auth';

export default async function DashboardPage() {
  const auth = await requireAuthOrRedirect();

  return (
    <div className="container mx-auto p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">URM Platform</h1>
        <p className="text-sm text-muted-foreground mt-1">
          {auth.email}
        </p>
      </header>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">AI Drafts</CardTitle>
            <Sparkles className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums">—</div>
            <CardDescription className="mt-1">
              Pending review
            </CardDescription>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Inbox</CardTitle>
            <Inbox className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums">—</div>
            <CardDescription className="mt-1">
              Recent inbound
            </CardDescription>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tasks</CardTitle>
            <CheckSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums">—</div>
            <CardDescription className="mt-1">
              Open
            </CardDescription>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Welcome</CardTitle>
          <CardDescription>
            대시보드 위젯은 다음 단계에서 활성화됩니다. AI 초안 큐로 바로 이동하세요.
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  );
}
