-- =============================================================
-- Phase 22b Patch 9: Supabase Storage - email-attachments bucket
-- Supabase Dashboard → Storage 에서 버킷 생성 후 아래 정책 적용
-- 또는 SQL Editor에서 직접 실행
-- =============================================================

-- 1) 버킷 생성 (Dashboard에서 수동으로 해도 됨)
-- 버킷명: email-attachments
-- Public: false (비공개)
-- File size limit: 10MB 권장
-- Allowed MIME types: 비워두기 (모두 허용)

-- 2) Storage RLS 정책 (SQL Editor에서 실행)

-- 업로드: org 멤버만 가능
CREATE POLICY "org members can upload email attachments"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'email-attachments'
  AND auth.uid() IN (
    SELECT user_id FROM app.org_members
  )
);

-- 조회: org 멤버만 가능
CREATE POLICY "org members can read email attachments"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'email-attachments'
  AND auth.uid() IN (
    SELECT user_id FROM app.org_members
  )
);

-- 삭제: org 멤버만 가능
CREATE POLICY "org members can delete email attachments"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'email-attachments'
  AND auth.uid() IN (
    SELECT user_id FROM app.org_members
  )
);

-- =============================================================
-- Storage path 규칙:
-- {party_id}/{timestamp}-{filename}
-- 예: "abc123/1716000000000-report.pdf"
-- =============================================================
