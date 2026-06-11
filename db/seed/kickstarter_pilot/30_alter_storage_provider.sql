ALTER TABLE app.attachments
  DROP CONSTRAINT chk_attachments_storage_provider,
  ADD CONSTRAINT chk_attachments_storage_provider
    CHECK (storage_provider = ANY (ARRAY[
      'supabase'::text,
      's3'::text,
      'external_url'::text,
      'google_drive'::text
    ]));
