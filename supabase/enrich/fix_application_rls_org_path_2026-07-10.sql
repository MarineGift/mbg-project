-- fix_application_rls_org_path_2026-07-10.sql
-- Bug: application_forms / application_form_fields / application_field_answers /
-- answer_library policies read top-level jwt claim (auth.jwt() ->> organization_id)
-- which is always NULL - org lives in app_metadata. Every INSERT was rejected by
-- WITH CHECK (42501). Fix: use app.current_organization_id() like parties policies.
DROP POLICY IF EXISTS application_forms_org_isolation ON app.application_forms;
CREATE POLICY application_forms_org_isolation ON app.application_forms
  FOR ALL
  USING (organization_id = app.current_organization_id())
  WITH CHECK (organization_id = app.current_organization_id());
DROP POLICY IF EXISTS application_form_fields_org_isolation ON app.application_form_fields;
CREATE POLICY application_form_fields_org_isolation ON app.application_form_fields
  FOR ALL
  USING (organization_id = app.current_organization_id())
  WITH CHECK (organization_id = app.current_organization_id());
DROP POLICY IF EXISTS application_field_answers_org_isolation ON app.application_field_answers;
CREATE POLICY application_field_answers_org_isolation ON app.application_field_answers
  FOR ALL
  USING (organization_id = app.current_organization_id())
  WITH CHECK (organization_id = app.current_organization_id());
DROP POLICY IF EXISTS answer_library_org_isolation ON app.answer_library;
CREATE POLICY answer_library_org_isolation ON app.answer_library
  FOR ALL
  USING (organization_id = app.current_organization_id())
  WITH CHECK (organization_id = app.current_organization_id());