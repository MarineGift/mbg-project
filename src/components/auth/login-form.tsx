/**
 * components/auth/login-form.tsx
 *
 * 이메일·비밀번호 로그인 폼. react-hook-form + zod로 클라이언트 검증.
 * Server Action(signInWithPassword)를 호출하여 실제 인증 수행.
 */

'use client';

import { useState, useTransition } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useTranslations } from 'next-intl';
import { useSearchParams } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { signInWithPassword, type SignInResult } from '@/lib/actions/auth';

const formSchema = z.object({
  email: z.string().email({ message: 'Invalid email format' }),
  password: z.string().min(1, { message: 'Password is required' }),
});

type FormValues = z.infer<typeof formSchema>;

export function LoginForm() {
  const t = useTranslations('auth');
  const tCommon = useTranslations('common');
  const searchParams = useSearchParams();
  const nextPath = searchParams.get('next') ?? '/';

  const [isPending, startTransition] = useTransition();
  const [serverError, setServerError] = useState<SignInResult | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: { email: '', password: '' },
  });

  const onSubmit = (values: FormValues) => {
    setServerError(null);
    startTransition(async () => {
      const result = await signInWithPassword({
        email: values.email,
        password: values.password,
        next: nextPath,
      });
      // 성공 시에는 redirect로 인해 이 코드까지 도달 안 함.
      // 실패 시에만 result 표시.
      if (result && !result.ok) {
        setServerError(result);
      }
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
      <div className="space-y-2">
        <Label htmlFor="email">{t('email')}</Label>
        <Input
          id="email"
          type="email"
          autoComplete="email"
          autoFocus
          disabled={isPending}
          aria-invalid={errors.email ? 'true' : undefined}
          {...register('email')}
        />
        {errors.email && (
          <p className="text-xs text-destructive">{errors.email.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="password">{t('password')}</Label>
        <Input
          id="password"
          type="password"
          autoComplete="current-password"
          disabled={isPending}
          aria-invalid={errors.password ? 'true' : undefined}
          {...register('password')}
        />
        {errors.password && (
          <p className="text-xs text-destructive">{errors.password.message}</p>
        )}
      </div>

      {serverError && !serverError.ok && (
        <div
          className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive"
          role="alert"
        >
          {serverError.errorCode === 'invalid_credentials'
            ? 'Invalid email or password.'
            : serverError.errorMessage ?? 'Sign-in failed. Please try again.'}
        </div>
      )}

      <Button type="submit" className="w-full" disabled={isPending}>
        {isPending ? (
          <>
            <Loader2 className="h-4 w-4 animate-spin" />
            {t('signingIn')}
          </>
        ) : (
          t('signInButton')
        )}
      </Button>

      <p className="text-xs text-muted-foreground text-center pt-2">
        {tCommon('appName')}
      </p>
    </form>
  );
}
