SELECT 'party_types' AS src, jsonb_agg(to_jsonb(t)) AS data FROM app.party_types t
UNION ALL
SELECT 'contact_types', jsonb_agg(to_jsonb(t)) FROM app.contact_types t
UNION ALL
SELECT 'entity_types', jsonb_agg(to_jsonb(t)) FROM app.entity_types t
UNION ALL
SELECT 'pipelines', jsonb_agg(to_jsonb(t)) FROM app.pipelines t
UNION ALL
SELECT 'stages', jsonb_agg(to_jsonb(t)) FROM app.stages t
UNION ALL
SELECT 'todo_status_options', jsonb_agg(to_jsonb(t)) FROM app.todo_status_options t;
