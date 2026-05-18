// src/app/(app)/settings/email-signatures/page.tsx
// Phase 22b: 이메일 서명 설정 페이지
import { EmailSignaturesClient } from "@/components/settings/email-signatures-client";

export default function EmailSignaturesPage() {
  return (
    <div className="p-6 max-w-3xl">
      <div className="mb-6">
        <h1 className="text-2xl font-semibold">이메일 서명</h1>
        <p className="text-sm text-muted-foreground mt-1">
          이메일 발송 시 자동으로 첨부되는 HTML 서명을 관리합니다.
        </p>
      </div>
      <EmailSignaturesClient />
    </div>
  );
}
