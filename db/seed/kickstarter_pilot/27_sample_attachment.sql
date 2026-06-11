INSERT INTO app.attachments (
  id, organization_id, entity_type, entity_id, file_name, file_size_bytes,
  mime_type, storage_provider, storage_bucket, storage_path, description
)
VALUES (
  '1aa00b56-845e-4aa3-9f5b-5f055a288afd',
  'b25de8f2-1020-482f-9012-183f63883169',
  'task',
  'edceb03f-b5c0-4e60-880a-18e1b18e8aed',
  'Kickstarter Budget Sheet (SAMPLE - replace with real Drive link)',
  0,
  'application/vnd.google-apps.spreadsheet',
  'google_drive',
  NULL,
  'https://drive.google.com/drive/my-drive',
  'Sample google_drive attachment row on task: Confirm funding goal and budget. Replace via the new Attachments panel.'
)
ON CONFLICT (id) DO NOTHING;
