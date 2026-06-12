// src/types/attachments.ts
// Types for app.attachments rows used by the Attachments panel.

export type AttachmentEntityType =
  | 'deal'
  | 'deal_checklist'
  | 'task'
  | 'engagement';

export interface Attachment {
  id: string;
  organization_id: string;
  entity_type: string;
  entity_id: string;
  file_name: string;
  file_size_bytes: number;
  mime_type: string;
  storage_provider: string; // 'google_drive' | 'external_url' | 'supabase' | 's3'
  storage_bucket: string | null;
  storage_path: string; // for google_drive/external_url providers this is the full URL
  drive_file_id?: string | null; // set for files uploaded via URM to Drive
  description: string | null;
  uploaded_by: string | null;
  uploaded_at: string;
  deleted_at: string | null;
}

export interface AddAttachmentInput {
  entityType: AttachmentEntityType;
  entityId: string;
  url: string;
  fileName: string;
  description?: string;
}
