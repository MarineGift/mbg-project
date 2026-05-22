// src/lib/utils/sequence-processor.ts (v7 ??Phase 22a)
// ============================================================
// Phase 22a ??Updated sequence processor with proper threading
// Changes vs v5:
//   - Generates RFC-compliant Message-ID for each outbound
//   - Sets thread_id = message_id (new threads)
//   - Sets occurred_at = NOW()
//   - Sets from_address / from_name explicitly
//   - Sets to_addresses[] correctly
//   - Sets template_id (from sequence step)
//   - Sets ai_generated = false
//   - Passes Message-ID header to nodemailer (so replies match)
//   - Adds List-Unsubscribe headers (RFC 8058)
//   - Calls classifyInboundEmail not needed here (inbound only)
// ============================================================
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { rpc } from "@/lib/rpc/typed-rpc";
import nodemailer from "nodemailer";
import { renderMergeFields } from "@/lib/utils/merge-fields";

const FROM_NAME = process.env.TABS_MAILER_FROM_NAME || "URM";

interface DueEnrollment {
  enrollment_id: string;
  org_id: string;
  party_id: string;
  contact_id: string | null;
  sequence_id: string;
  step_id: string;
  step_order: number;
  step_subject: string;
  step_body: string;
  step_body_html: string | null;
  step_template_id: string | null;
  contact_email: string | null;
  contact_given_name: string | null;
  contact_family_name: string | null;
  party_name: string;
}

export async function processSequence(): Promise<{
  processed: number;
  sent: number;
  failed: number;
  skipped: number;
}> {
  const supabase = await createSupabaseServerClient();

  // Get due enrollments
  const { data: due, error: dueErr } = await rpc(supabase, "get_due_enrollments");
  if (dueErr || !due) {
    console.error("[processSequence] get_due_enrollments error", dueErr);
    return { processed: 0, sent: 0, failed: 0, skipped: 0 };
  }

  const enrollments = (due as DueEnrollment[]) || [];
  let sent = 0,
    failed = 0,
    skipped = 0;

  const fromAddress = process.env.TABS_MAILER_USERNAME!;
  const transporter = nodemailer.createTransport({
    host: process.env.TABS_MAILER_HOST!,
    port: Number(process.env.TABS_MAILER_PORT || 587),
    secure: false,
    auth: {
      user: process.env.TABS_MAILER_USERNAME!,
      pass: process.env.TABS_MAILER_PASSWORD!,
    },
  });

  for (const e of enrollments) {
    try {
      if (!e.contact_email) {
        await rpc(supabase, "advance_enrollment", {
          p_enrollment_id: e.enrollment_id,
          p_status: "skipped_no_email",
        });
        skipped++;
        continue;
      }

      // Render merge fields
      const ctx = {
        contact: {
          given_name: e.contact_given_name || "",
          family_name: e.contact_family_name || "",
          email: e.contact_email,
        },
        party: { name: e.party_name },
      };
      const subjectResult = renderMergeFields(e.step_subject || "", ctx);
      const bodyResult = renderMergeFields(e.step_body || "", ctx);
      const subject = unwrapMerge(subjectResult);
      const bodyPlain = unwrapMerge(bodyResult);
      const bodyHtml = e.step_body_html
        ? unwrapMerge(renderMergeFields(e.step_body_html, ctx))
        : plainToHtml(bodyPlain);

      // Generate communication id + Message-ID
      const commId = crypto.randomUUID();
      const messageId = `<${commId}.${Date.now()}@marinebiogroup.com>`;
      const occurredAt = new Date().toISOString();

      // Add tracking pixel
      const trackedHtml = injectTrackingPixel(bodyHtml, commId);

      // Insert communications row (with full threading fields)
      const { error: insErr } = await supabase
        .schema("app")
        .from("communications")
        .insert({
          id: commId,
          organization_id: e.organization_id,
          party_id: e.party_id,
          contact_id: e.contact_id,
          channel: "email",
          direction: "outbound",
          message_id: messageId,
          in_reply_to: null,
          thread_id: messageId,  // new thread
          from_address: fromAddress,
          from_name: FROM_NAME,
          to_addresses: [e.contact_email],
          cc_addresses: [],
          bcc_addresses: [],
          subject,
          body_html: trackedHtml,
          body_plain: bodyPlain,
          status: "sending",
          occurred_at: occurredAt,
          template_id: e.step_template_id,
          template_variables: {
            enrollment_id: e.enrollment_id,
            step_id: e.step_id,
            step_order: e.step_order,
            sequence_id: e.sequence_id,
          },
          external_data: {
            source: "sequence",
            sequence_id: e.sequence_id,
            step_id: e.step_id,
          },
          ai_generated: false,
          ai_processing_status: "skipped",
          is_starred: false,
          is_important: false,
        });

      if (insErr) {
        console.error("[processSequence] insert error", insErr);
        await rpc(supabase, "advance_enrollment", {
          p_enrollment_id: e.enrollment_id,
          p_status: "failed",
        });
        failed++;
        continue;
      }

      // Send via SMTP with full headers
      if (process.env.TABS_MAILER_USE_MOCK === "true") {
        console.log(`[MOCK SEND] ${e.contact_email} - ${subject}`);
      } else {
        try {
          await transporter.sendMail({
            from: `${FROM_NAME} <${fromAddress}>`,
            to: e.contact_email,
            subject,
            text: bodyPlain,
            html: trackedHtml,
            headers: {
              "Message-ID": messageId,
              "List-Unsubscribe": `<mailto:unsubscribe@marinebiogroup.com>`,
              "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
              "X-URM-Sequence-Id": e.sequence_id,
              "X-URM-Step-Order": String(e.step_order),
            },
          });
        } catch (smtpErr) {
          const msg = smtpErr instanceof Error ? smtpErr.message : String(smtpErr);
          console.error("[processSequence] SMTP error", smtpErr);
          await supabase
            .schema("app")
            .from("communications")
            .update({
              status: "failed",
              bounce_reason: msg,
              updated_at: new Date().toISOString(),
            })
            .eq("id", commId);
          await rpc(supabase, "advance_enrollment", {
            p_enrollment_id: e.enrollment_id,
            p_status: "failed",
          });
          failed++;
          continue;
        }
      }

      // Mark sent
      const sentAt = new Date().toISOString();
      await supabase
        .schema("app")
        .from("communications")
        .update({
          status: "sent",
          sent_at: sentAt,
          delivered_at: sentAt,
          updated_at: sentAt,
        })
        .eq("id", commId);

      // Record send in email_sequence_sends
      await supabase
        .schema("app")
        .from("email_sequence_sends")
        .insert({
          enrollment_id: e.enrollment_id,
          step_id: e.step_id,
          communication_id: commId,
          sent_at: sentAt,
          status: "sent",
        });

      // Advance enrollment
      await rpc(supabase, "advance_enrollment", {
        p_enrollment_id: e.enrollment_id,
        p_status: "sent",
      });

      sent++;
    } catch (err) {
      console.error("[processSequence] unhandled error for enrollment", e.enrollment_id, err);
      failed++;
    }
  }

  return { processed: enrollments.length, sent, failed, skipped };
}

// ?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?
// Helpers
// ?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?
function unwrapMerge(result: unknown): string {
  if (typeof result === "string") return result;
  if (
    result &&
    typeof result === "object" &&
    "rendered" in result &&
    typeof (result as { rendered: unknown }).rendered === "string"
  ) {
    return (result as { rendered: string }).rendered;
  }
  return "";
}

function plainToHtml(plain: string): string {
  if (!plain) return "";
  const escaped = plain
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
  return escaped
    .split(/\n\n+/)
    .map((p) => `<p>${p.replace(/\n/g, "<br/>")}</p>`)
    .join("\n");
}

function injectTrackingPixel(html: string, communicationId: string): string {
  const baseUrl =
    process.env.NEXT_PUBLIC_APP_URL || "https://app.marinebiogroup.com";
  const pixel = `<img src="${baseUrl}/api/email/track/open/${communicationId}.gif" width="1" height="1" style="display:none" alt=""/>`;
  // Insert before closing body tag, or append
  if (html.includes("</body>")) {
    return html.replace("</body>", `${pixel}</body>`);
  }
  return html + pixel;
}
