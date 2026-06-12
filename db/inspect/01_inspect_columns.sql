SELECT c.table_name,
       c.ordinal_position,
       c.column_name,
       c.data_type,
       c.udt_name,
       c.is_nullable,
       c.column_default
FROM information_schema.columns c
WHERE c.table_schema = 'app'
  AND ( c.table_name ~ '^(todo|deal|campaign|engagement|attachment|checklist)'
        OR c.table_name IN ('parties', 'party_types', 'contacts') )
ORDER BY c.table_name, c.ordinal_position;
