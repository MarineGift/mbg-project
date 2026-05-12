import Link from 'next/link';
import { ArrowLeft, Inbox } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

export default function CommunicationNotFound() {
  return (
    <div className="flex items-center justify-center min-h-[60vh] p-6">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-muted">
            <Inbox className="h-6 w-6 text-muted-foreground" />
          </div>
          <CardTitle className="text-center">Message not found</CardTitle>
          <CardDescription className="text-center">
            This message may have been deleted or you don&apos;t have access to it.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button asChild className="w-full" variant="outline">
            <Link href="/inbox">
              <ArrowLeft className="h-4 w-4" />
              Back to inbox
            </Link>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
