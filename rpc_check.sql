SELECT n.nspname AS schema, p.proname AS name,
       pg_get_function_arguments(p.oid) AS args
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname IN ('create_email_tracking','list_email_whitelist','get_unregistered_party_domains','add_email_whitelist','toggle_email_whitelist','delete_email_whitelist','get_party_communications_timeline','get_contact_communications_timeline','get_communications_stats_per_party','get_thread_context','list_templates_for_compose','get_email_history','count_email_history','list_sequences','get_sequence_with_steps','get_party_enrollments','get_tracking_for_communications','get_tracking_for_drafts','get_lead_scores_many')
ORDER BY schema, name;
