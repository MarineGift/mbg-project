import Link from 'next/link';
import { AlertCircle } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

interface AuthErrorPageProps {
  searchParams: Promise<{ reason?: string; message?: string }>;
}

const REASON_DESCRIPTIONS: Record<string, string> = {
  missing_code: 'Authentication code is missing.',
  exchange_failed: 'Could not exchange the authentication code.',
  config: 'Authentication service is not configured.',
};

export default async function AuthErrorPage({ searchParams }: AuthErrorPageProps) {
  const params = await searchParams;
  const reason = params.reason ?? 'unknown';
  const description =
    REASON_DESCRIPTIONS[reason] ??
    params.message ??
    'An authentication error occurred.';

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10">
            <AlertCircle className="h-6 w-6 text-destructive" />
          </div>
          <CardTitle className="text-center">Authentication Failed</CardTitle>
          <CardDescription className="text-center">{description}</CardDescription>
        </CardHeader>
        <CardContent>
          <Button asChild className="w-full" variant="outline">
            <Link href="/login">Back to login</Link>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
