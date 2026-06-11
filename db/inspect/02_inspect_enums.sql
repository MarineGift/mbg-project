SELECT t.typname AS enum_type,
       e.enumlabel,
       e.enumsortorder
FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname = 'app'
ORDER BY t.typname, e.enumsortorder;
