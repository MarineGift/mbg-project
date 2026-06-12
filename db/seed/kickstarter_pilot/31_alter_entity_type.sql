ALTER TABLE app.attachments
  DROP CONSTRAINT chk_attachments_entity_type,
  ADD CONSTRAINT chk_attachments_entity_type
    CHECK (entity_type = ANY (ARRAY[
      'communication'::text,
      'meeting'::text,
      'task'::text,
      'party'::text,
      'engagement'::text,
      'consultation'::text,
      'deal'::text,
      'deal_checklist'::text
    ]));
