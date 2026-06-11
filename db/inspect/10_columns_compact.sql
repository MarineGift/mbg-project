SELECT c.table_name,
       string_agg(
         c.column_name || ' ' || c.udt_name
         || CASE WHEN c.is_nullable = 'NO' THEN ' NN' ELSE '' END
         || COALESCE(' DEF ' || c.column_default, ''),
         ' | ' ORDER BY c.ordinal_position
       ) AS cols
FROM information_schema.columns c
WHERE c.table_schema = 'app'
  AND c.table_name IN (
    'deals', 'deal_parties', 'deal_checklists', 'deal_participation',
    'deal_stage_history', 'reward_tiers', 'tasks',
    'todo_boards', 'todo_groups', 'todo_items', 'todo_status_options',
    'todo_updates', 'todo_dependencies',
    'parties', 'party_types', 'contact_types',
    'stages', 'pipelines', 'stage_checklist_templates', 'stage_task_templates',
    'entity_types', 'engagement_documents'
  )
GROUP BY c.table_name
ORDER BY c.table_name;
