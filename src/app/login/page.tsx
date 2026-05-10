import { signInWithPassword, signInWithMagicLink } from '@/app/auth/actions';

export const dynamic = 'force-dynamic';

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; info?: string; next?: string }>;
}) {
  const sp = await searchParams;
  const errorMsg = sp.error;
  const infoMsg = sp.info;
  const next = sp.next ?? '/drafts';

  return (
    <main className="min-h-screen grid place-items-center bg-surface-muted px-6">
      <div className="w-full max-w-sm bg-surface border border-border rounded-lg p-8 shadow-card">
        <h1 className="text-xl font-bold text-center mb-1">URM Platform</h1>
        <p className="text-base text-muted-foreground text-center mb-6">
          이메일과 비밀번호로 로그인
        </p>

        {errorMsg ? (
          <div className="alert-error mb-4" role="alert">
            {errorMsg}
          </div>
        ) : null}
        {infoMsg ? (
          <div className="alert-info mb-4" role="status">
            {infoMsg}
          </div>
        ) : null}

        <form action={signInWithPassword} className="grid gap-3">
          <input type="hidden" name="next" value={next} />
          <label className="label">
            이메일
            <input
              type="email"
              name="email"
              required
              autoComplete="email"
              className="input"
              placeholder="you@example.com"
            />
          </label>
          <label className="label">
            비밀번호
            <input
              type="password"
              name="password"
              required
              autoComplete="current-password"
              className="input"
            />
          </label>
          <button type="submit" className="btn-primary mt-1">
            로그인
          </button>
        </form>

        <div className="flex items-center gap-2 my-5">
          <hr className="flex-1 border-t border-border" />
          <span className="text-xs text-zinc-400">OR</span>
          <hr className="flex-1 border-t border-border" />
        </div>

        <form action={signInWithMagicLink} className="grid gap-3">
          <input type="hidden" name="next" value={next} />
          <input
            type="email"
            name="email"
            required
            autoComplete="email"
            className="input"
            placeholder="매직 링크 받을 이메일"
          />
          <button type="submit" className="btn-secondary">
            매직 링크로 로그인
          </button>
        </form>

        <p className="text-xs text-zinc-400 text-center mt-6">
          신규 가입은 조직 관리자에게 문의하세요.
        </p>
      </div>
    </main>
  );
}
