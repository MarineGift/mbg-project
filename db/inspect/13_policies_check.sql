SELECT tablename, policyname, permissive, cmd
FROM pg_policies
WHERE schemaname = 'app'
  AND tablename IN (
    'attachments', 'deal_backers', 'reward_tiers',
    'deal_checklists', 'tasks', 'todo_items', 'deals'
  )
ORDER BY tablename, policyname;
