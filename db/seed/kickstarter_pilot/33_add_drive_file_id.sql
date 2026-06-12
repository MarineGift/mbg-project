ALTER TABLE app.attachments
  ADD COLUMN IF NOT EXISTS drive_file_id text;
