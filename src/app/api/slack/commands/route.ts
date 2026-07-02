// src/app/api/slack/commands/route.ts
//
// Inbound Slack slash command: `/urm ...`
//   /urm note <text>            -> saves a note in app.slack_notes
//   /urm contact <name> | <email>  -> adds a contact under the auto-managed
//                                       "Inbound (Slack)" party
//   /urm help                   -> usage
//
// Security: every request is signature-verified with SLACK_SIGNING_SECRET
// (see @/lib/slack/verify). Writes use the service_role admin client and set
// organization_id EXPLICITLY (resolved from the Slack team_id -> slack_integrations).
//
// Node runtime required (crypto + raw body). New tables aren't in the generated
// Database types yet, so the admin client is used loosely (`as any`); regenerate
// types when convenient.

import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseAdminClient } from '@/lib/supabase/admin';
import { verifySlackSignature } from '@/lib/slack/verify';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function ephemeral(text: string) {
  return NextResponse.json({ response_type: 'ephemeral', text });
}

const HELP =
  'URM commands:\n' +
  '• `/urm note <text>` — save a quick note to URM\n' +
  '• `/urm contact <name> | <email>` — add a contact (email optional)\n' +
  '• `/urm help` — show this';

export async function POST(req: NextRequest) {
  // 1) verify signature over the RAW body
  const raw = await req.text();
  const ok = verifySlackSignature(
    raw,
    req.headers.get('x-slack-request-timestamp'),
    req.headers.get('x-slack-signature'),
  );
  if (!ok) return new NextResponse('invalid signature', { status: 401 });

  // 2) parse Slack's form-encoded payload
  const p = new URLSearchParams(raw);
  const teamId = p.get('team_id') ?? '';
  const teamName = p.get('team_domain') ?? '';
  const userId = p.get('user_id') ?? '';
  const userName = p.get('user_name') ?? '';
  const text = (p.get('text') ?? '').trim();

  const db = createSupabaseAdminClient() as any;

  // 3) resolve org from the workspace; self-heal team_id if a single config exists
  let orgId: string | null = null;
  {
    const byTeam = await db
      .schema('app')
      .from('slack_integrations')
      .select('organization_id')
      .eq('slack_team_id', teamId)
      .eq('enabled', true)
      .limit(1)
      .maybeSingle();

    if (byTeam.data?.organization_id) {
      orgId = byTeam.data.organization_id;
    } else {
      const rows = await db
        .schema('app')
        .from('slack_integrations')
        .select('id, organization_id')
        .eq('enabled', true)
        .limit(2);
      if (rows.data && rows.data.length === 1) {
        orgId = rows.data[0].organization_id;
        await db
          .schema('app')
          .from('slack_integrations')
          .update({ slack_team_id: teamId, slack_team_name: teamName })
          .eq('id', rows.data[0].id);
      }
    }
  }
  if (!orgId) {
    return ephemeral(
      'URM is not linked to this Slack workspace yet. Add a row to app.slack_integrations (organization_id + webhook_url) and try again.',
    );
  }

  // 4) dispatch
  const [sub, ...rest] = text.split(/\s+/);
  const arg = rest.join(' ').trim();

  if (!sub || sub === 'help') return ephemeral(HELP);

  if (sub === 'note') {
    if (!arg) return ephemeral('Usage: `/urm note <text>`');
    const { error } = await db.schema('app').from('slack_notes').insert({
      organization_id: orgId,
      body: arg,
      slack_user_id: userId,
      slack_user_name: userName,
      slack_team_id: teamId,
    });
    if (error) return ephemeral('Could not save the note - please try again.');
    return ephemeral(`Saved to URM: "${arg}"`);
  }

  if (sub === 'contact') {
    const [nm, em] = arg.split('|').map((s) => s.trim());
    if (!nm) return ephemeral('Usage: `/urm contact <name> | <email>`');

    // find-or-create the auto-managed "Inbound (Slack)" party for this org
    let partyId: string | null = null;
    const found = await db
      .schema('app')
      .from('parties')
      .select('id')
      .eq('organization_id', orgId)
      .eq('party_name', 'Inbound (Slack)')
      .is('deleted_at', null)
      .limit(1)
      .maybeSingle();

    if (found.data?.id) {
      partyId = found.data.id;
    } else {
      // party_type_id: resolve 'partner' via app.party_types
      const pt = await db
        .schema('app')
        .from('party_types')
        .select('id')
        .eq('code', 'partner')
        .limit(1)
        .maybeSingle();
      const created = await db
        .schema('app')
        .from('parties')
        .insert({
          party_type_id: pt.data?.id ?? 1,
          entity_type_id: 1,
          party_name: 'Inbound (Slack)',
          status: 'active',
          source: 'slack_urm',
          organization_id: orgId,
        })
        .select('id')
        .single();
      if (created.error || !created.data?.id) {
        return ephemeral('Could not create the inbound party - please try again.');
      }
      partyId = created.data.id;
    }

    // contact_type_id: same coalesce pattern used by the SQL seed batches
    const ct = await db
      .schema('app')
      .from('contact_types')
      .select('id, code, sort_order')
      .order('sort_order', { ascending: true });
    const ctList: Array<{ id: number; code: string }> = ct.data ?? [];
    const preferred = ctList.find((r) =>
      ['general', 'other', 'company', 'main', 'primary'].includes(r.code),
    );
    const contactTypeId = preferred?.id ?? ctList[0]?.id ?? null;

    const { error } = await db.schema('app').from('contacts').insert({
      party_id: partyId,
      organization_id: orgId,
      contact_type_id: contactTypeId,
      full_name: nm,
      email: em || null,
      is_primary: false,
      is_active: true,
      source: 'slack_urm',
    });
    if (error) return ephemeral('Could not add the contact - please try again.');
    return ephemeral(
      `Added contact to URM: ${nm}${em ? ` <${em}>` : ''} (under "Inbound (Slack)")`,
    );
  }

  return ephemeral('Unknown command. Try `/urm help`.');
}
