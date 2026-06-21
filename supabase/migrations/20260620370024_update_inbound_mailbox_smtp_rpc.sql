-- 20260620370024_update_inbound_mailbox_smtp_rpc.sql
-- Per-mailbox SMTP (sending) settings, saved from the Inbound Mailboxes UI.
-- Password is OPTIONAL: when null/blank the stored ciphertext is kept, so
-- host/port/TLS/username can change without re-entering the password.
-- Encryption mirrors the IMAP path: pgp_sym_encrypt(pw, enc_key) -> bytea,
-- decryptable by the existing decrypt_inbound_mailbox_password(encrypted, enc_key).
-- Idempotent (CREATE OR REPLACE).
create or replace function app.update_inbound_mailbox_smtp(
  p_organization_id uuid,
  p_address         text,
  p_smtp_host       text,
  p_smtp_port       integer,
  p_smtp_use_tls    boolean,
  p_smtp_username   text,
  p_smtp_password   text,
  p_enc_key         text
) returns void
language plpgsql
security definer
set search_path = app, public, extensions, pg_temp
as $func$
begin
  update app.inbound_mailboxes
  set smtp_host        = nullif(btrim(p_smtp_host), ''),
      smtp_port        = p_smtp_port,
      smtp_use_tls     = coalesce(p_smtp_use_tls, false),
      smtp_username    = coalesce(nullif(btrim(p_smtp_username), ''), smtp_username, address),
      smtp_auth_method = coalesce(smtp_auth_method, 'login'),
      smtp_password_encrypted = case
        when p_smtp_password is not null and btrim(p_smtp_password) <> ''
          then pgp_sym_encrypt(p_smtp_password, p_enc_key)
        else smtp_password_encrypted
      end
  where organization_id = p_organization_id
    and lower(address) = lower(p_address);
end;
$func$;

grant execute on function app.update_inbound_mailbox_smtp(
  uuid, text, text, integer, boolean, text, text, text
) to authenticated, service_role;
