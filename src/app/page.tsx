import { redirect } from 'next/navigation';
import Link from 'next/link';
import { getServerSupabase } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function HomePage() {
  const supa = await getServerSupabase();
  const { data } = await supa.auth.getUser();
  if (data.user) {
    redirect('/drafts');
  }

  return (
    <main className="max-w-2xl mx-auto px-6 py-16 leading-relaxed">
      <h1 className="text-3xl font-bold mb-2">URM Platform</h1>
      <p className="text-muted-foreground">
        Universal Relationship Management Platform — backend skeleton deployed.
      </p>
      <Link href="/login" className="btn-primary mt-6 inline-flex">
        로그인 →
      </Link>
    </main>
  );
}
