'use client';

import { useState, useTransition, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  parseCsv,
  detectEmailColumn,
  isValidEmail,
  applyVariables,
  extractTemplateVariables,
} from '@/lib/csv/parser';
import { createCampaignAction } from './actions';

const MAX_RECIPIENTS = 500;
const SYNC_SEND_LIMIT = 100;

type Step = 1 | 2 | 3 | 4 | 5;

interface CsvData {
  fileName: string;
  columns: string[];
  rows: Array<Record<string, string>>;
  errors: string[];
}

interface CampaignSettings {
  name: string;
  subjectTemplate: string;
  bodyTemplate: string;
  fromName: string;
  fromAddress: string;
  replyToAddress: string;
}

export interface CampaignWizardProps {
  defaultFromAddress: string;
}

export default function CampaignWizard({ defaultFromAddress }: CampaignWizardProps) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  const [step, setStep] = useState<Step>(1);
  const [csv, setCsv] = useState<CsvData | null>(null);
  const [emailColumn, setEmailColumn] = useState<string | null>(null);
  const [settings, setSettings] = useState<CampaignSettings>({
    name: '',
    subjectTemplate: '',
    bodyTemplate: '',
    fromName: '',
    fromAddress: defaultFromAddress,
    replyToAddress: '',
  });
  const [submitError, setSubmitError] = useState<string | null>(null);

  // 변수 — emailColumn 제외한 모든 컬럼
  const variableColumns = useMemo(() => {
    if (!csv || !emailColumn) return [];
    return csv.columns.filter((c) => c !== emailColumn);
  }, [csv, emailColumn]);

  // 템플릿에서 사용된 변수 vs 컬럼에 있는 변수 비교
  const usedVariables = useMemo(() => {
    return Array.from(
      new Set([
        ...extractTemplateVariables(settings.subjectTemplate),
        ...extractTemplateVariables(settings.bodyTemplate),
      ]),
    );
  }, [settings.subjectTemplate, settings.bodyTemplate]);

  const undefinedVariables = useMemo(() => {
    return usedVariables.filter((v) => !csv?.columns.includes(v));
  }, [usedVariables, csv]);

  // 유효한 수신자 (이메일 형식 검증)
  const validRecipients = useMemo(() => {
    if (!csv || !emailColumn) return [];
    return csv.rows
      .map((row) => {
        const email = row[emailColumn] ?? '';
        if (!isValidEmail(email)) return null;
        const variables: Record<string, string> = {};
        for (const col of csv.columns) {
          if (col !== emailColumn) variables[col] = row[col] ?? '';
        }
        return { email: email.trim(), variables };
      })
      .filter((r): r is { email: string; variables: Record<string, string> } => r !== null);
  }, [csv, emailColumn]);

  const invalidRowCount = useMemo(() => {
    if (!csv) return 0;
    return csv.rows.length - validRecipients.length;
  }, [csv, validRecipients]);

  // 첫 행으로 라이브 프리뷰
  const firstRowPreview = useMemo(() => {
    if (!validRecipients[0]) return null;
    return {
      to: validRecipients[0].email,
      subject: applyVariables(settings.subjectTemplate, validRecipients[0].variables),
      body: applyVariables(settings.bodyTemplate, validRecipients[0].variables),
    };
  }, [validRecipients, settings.subjectTemplate, settings.bodyTemplate]);

  function handleFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.name.toLowerCase().endsWith('.csv')) {
      alert('CSV 파일만 업로드할 수 있습니다');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      alert('파일 크기는 5MB 이하여야 합니다');
      return;
    }
    const reader = new FileReader();
    reader.onload = (ev) => {
      const text = String(ev.target?.result ?? '');
      const result = parseCsv(text);
      if (result.rows.length === 0) {
        alert('파싱된 행이 0개입니다. CSV 형식을 확인하세요.');
        return;
      }
      if (result.rows.length > MAX_RECIPIENTS) {
        alert(`최대 ${MAX_RECIPIENTS}명까지만 지원됩니다 (현재 ${result.rows.length}명).`);
        return;
      }
      setCsv({ fileName: file.name, ...result });
      // 자동으로 이메일 컬럼 감지
      const detected = detectEmailColumn(result.columns, result.rows[0]);
      if (detected) setEmailColumn(detected);
    };
    reader.readAsText(file, 'utf-8');
  }

  function goNext() {
    if (step < 5) setStep((s) => (s + 1) as Step);
  }
  function goBack() {
    if (step > 1) setStep((s) => (s - 1) as Step);
  }

  function canAdvance(): boolean {
    if (step === 1) return !!csv && csv.rows.length > 0;
    if (step === 2) return !!emailColumn && validRecipients.length > 0;
    if (step === 3) {
      return (
        settings.subjectTemplate.trim().length > 0
        && settings.bodyTemplate.trim().length > 0
      );
    }
    if (step === 4) {
      return settings.name.trim().length > 0 && isValidEmail(settings.fromAddress);
    }
    return true;
  }

  async function handleLaunch() {
    setSubmitError(null);
    startTransition(async () => {
      const result = await createCampaignAction({
        name: settings.name,
        subjectTemplate: settings.subjectTemplate,
        bodyTemplate: settings.bodyTemplate,
        fromName: settings.fromName || undefined,
        fromAddress: settings.fromAddress,
        replyToAddress: settings.replyToAddress || undefined,
        recipients: validRecipients,
      });
      if (!result.ok) {
        setSubmitError(result.error ?? 'unknown error');
        return;
      }
      router.push(`/campaigns/${result.mailMergeJobId}`);
    });
  }

  return (
    <div style={{ maxWidth: 960 }}>
      <h1 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 8px' }}>새 캠페인</h1>
      <StepIndicator current={step} />

      {step === 1 ? (
        <Step1Upload csv={csv} onUpload={handleFileUpload} />
      ) : null}

      {step === 2 && csv ? (
        <Step2Mapping
          csv={csv}
          emailColumn={emailColumn}
          onSelectEmailColumn={setEmailColumn}
          validRecipients={validRecipients.length}
          invalidRows={invalidRowCount}
        />
      ) : null}

      {step === 3 ? (
        <Step3Compose
          settings={settings}
          onChange={setSettings}
          variableColumns={variableColumns}
          undefinedVariables={undefinedVariables}
          preview={firstRowPreview}
        />
      ) : null}

      {step === 4 ? <Step4Settings settings={settings} onChange={setSettings} /> : null}

      {step === 5 ? (
        <Step5Review
          settings={settings}
          totalRecipients={validRecipients.length}
          invalidRows={invalidRowCount}
          preview={firstRowPreview}
          fileName={csv?.fileName ?? ''}
          submitError={submitError}
          onLaunch={handleLaunch}
          isPending={isPending}
        />
      ) : null}

      {/* Navigation */}
      <div className="flex justify-between mt-6">
        <button
          type="button"
          onClick={goBack}
          disabled={step === 1 || isPending}
          className="btn-secondary disabled:opacity-50"
        >
          ← 이전
        </button>
        {step < 5 ? (
          <button
            type="button"
            onClick={goNext}
            disabled={!canAdvance() || isPending}
            className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            다음 →
          </button>
        ) : null}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// 단계별 컴포넌트
// ─────────────────────────────────────────────────────────────────────

function StepIndicator({ current }: { current: Step }) {
  const labels = ['CSV 업로드', '컬럼 매핑', '템플릿', '설정', '검토 & 발송'];
  return (
    <div style={{ display: 'flex', gap: 8, margin: '16px 0 24px', fontSize: 12 }}>
      {labels.map((label, i) => {
        const stepNum = (i + 1) as Step;
        const active = stepNum === current;
        const done = stepNum < current;
        return (
          <div
            key={label}
            style={{
              flex: 1,
              padding: '8px 12px',
              background: active ? '#111' : done ? '#dcfce7' : '#f4f4f5',
              color: active ? '#fff' : done ? '#166534' : '#888',
              borderRadius: 6,
              fontWeight: active ? 600 : 400,
              textAlign: 'center',
            }}
          >
            {done ? '✓ ' : `${stepNum}. `}
            {label}
          </div>
        );
      })}
    </div>
  );
}

function Step1Upload({
  csv,
  onUpload,
}: {
  csv: CsvData | null;
  onUpload: (e: React.ChangeEvent<HTMLInputElement>) => void;
}) {
  return (
    <Card title="1. CSV 파일 업로드">
      <p style={{ fontSize: 13, color: '#666', margin: '0 0 16px' }}>
        첫 행이 헤더(컬럼명)인 CSV 파일을 업로드하세요. 최대 {MAX_RECIPIENTS}명, 5MB 이하.
        UTF-8 인코딩 권장.
      </p>
      <input
        type="file"
        accept=".csv,text/csv"
        onChange={onUpload}
        style={{ marginBottom: 16 }}
      />
      {csv ? (
        <>
          <div className={summaryStyle}>
            <strong>{csv.fileName}</strong> · {csv.rows.length}행 · {csv.columns.length}컬럼
          </div>
          {csv.errors.length > 0 ? (
            <div className={warningBoxStyle}>
              <strong>경고:</strong>
              <ul style={{ margin: '4px 0 0', paddingLeft: 16 }}>
                {csv.errors.map((e, i) => <li key={i}>{e}</li>)}
              </ul>
            </div>
          ) : null}
          <div style={{ overflowX: 'auto', marginTop: 12 }}>
            <table className={tableStyle}>
              <thead>
                <tr>
                  {csv.columns.map((c) => <th key={c} className={thStyle}>{c}</th>)}
                </tr>
              </thead>
              <tbody>
                {csv.rows.slice(0, 5).map((row, i) => (
                  <tr key={i}>
                    {csv.columns.map((c) => <td key={c} className={tdStyle}>{row[c] ?? ''}</td>)}
                  </tr>
                ))}
              </tbody>
            </table>
            {csv.rows.length > 5 ? (
              <div style={{ fontSize: 11, color: '#888', marginTop: 4 }}>
                ... 외 {csv.rows.length - 5}행 더
              </div>
            ) : null}
          </div>
        </>
      ) : null}
    </Card>
  );
}

function Step2Mapping({
  csv,
  emailColumn,
  onSelectEmailColumn,
  validRecipients,
  invalidRows,
}: {
  csv: CsvData;
  emailColumn: string | null;
  onSelectEmailColumn: (c: string) => void;
  validRecipients: number;
  invalidRows: number;
}) {
  return (
    <Card title="2. 이메일 컬럼 선택 + 변수 확인">
      <p style={{ fontSize: 13, color: '#666', margin: '0 0 16px' }}>
        수신자 이메일이 들어 있는 컬럼을 선택하세요. 나머지 컬럼은 템플릿에서{' '}
        <code className={codeStyle}>{'{{ 컬럼명 }}'}</code> 형태로 사용 가능합니다.
      </p>

      <div style={{ display: 'grid', gap: 8, marginBottom: 16 }}>
        {csv.columns.map((c) => (
          <label key={c} className={radioRowStyle}>
            <input
              type="radio"
              name="email_col"
              checked={emailColumn === c}
              onChange={() => onSelectEmailColumn(c)}
            />
            <strong style={{ minWidth: 120 }}>{c}</strong>
            <span style={{ fontSize: 12, color: '#888' }}>
              예시: {csv.rows[0]?.[c] ?? '(빈 값)'}
            </span>
          </label>
        ))}
      </div>

      {emailColumn ? (
        <>
          <div className={summaryStyle}>
            유효한 수신자: <strong>{validRecipients}명</strong>
            {invalidRows > 0 ? (
              <span style={{ color: '#b91c1c', marginLeft: 12 }}>
                · 이메일 형식 오류로 제외: {invalidRows}명
              </span>
            ) : null}
          </div>

          <div style={{ marginTop: 16 }}>
            <h3 className={subTitleStyle}>사용 가능한 변수</h3>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {csv.columns
                .filter((c) => c !== emailColumn)
                .map((c) => (
                  <code key={c} className={tagStyle}>{`{{${c}}}`}</code>
                ))}
            </div>
          </div>
        </>
      ) : null}
    </Card>
  );
}

function Step3Compose({
  settings,
  onChange,
  variableColumns,
  undefinedVariables,
  preview,
}: {
  settings: CampaignSettings;
  onChange: (s: CampaignSettings) => void;
  variableColumns: string[];
  undefinedVariables: string[];
  preview: { to: string; subject: string; body: string } | null;
}) {
  return (
    <Card title="3. 제목 & 본문 템플릿">
      <p style={{ fontSize: 13, color: '#666', margin: '0 0 16px' }}>
        <code className={codeStyle}>{'{{ 컬럼명 }}'}</code>으로 변수를 삽입하세요.
        오른쪽에 첫 행 기준 미리보기가 표시됩니다.
      </p>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        <div style={{ display: 'grid', gap: 12 }}>
          <Field label="제목 (Subject)">
            <input
              type="text"
              value={settings.subjectTemplate}
              onChange={(e) => onChange({ ...settings, subjectTemplate: e.target.value })}
              placeholder="안녕하세요 {{name}}님, ..."
              className={inputStyle}
            />
          </Field>
          <Field label="본문 (Plain Text)">
            <textarea
              value={settings.bodyTemplate}
              onChange={(e) => onChange({ ...settings, bodyTemplate: e.target.value })}
              rows={14}
              placeholder={'{{name}}님 안녕하세요,\n\n...'}
              className={`${inputStyle} font-mono resize-y`}
            />
          </Field>

          <div className="text-sm text-muted-foreground">
            <strong>가능한 변수:</strong>{' '}
            {variableColumns.map((v) => (
              <code key={v} className={`${codeStyle} mr-1.5`}>{`{{${v}}}`}</code>
            ))}
          </div>

          {undefinedVariables.length > 0 ? (
            <div className={warningBoxStyle}>
              <strong>경고:</strong> CSV에 없는 변수가 사용됨 →{' '}
              {undefinedVariables.map((v) => (
                <code key={v} className={`${codeStyle} mr-1 bg-destructive-subtle`}>
                  {`{{${v}}}`}
                </code>
              ))}{' '}
              (빈 문자열로 치환됨)
            </div>
          ) : null}
        </div>

        <div>
          <h3 className={subTitleStyle}>미리보기 (첫 번째 수신자 기준)</h3>
          {preview ? (
            <div className={previewBoxStyle}>
              <div className="text-xs text-zinc-400 mb-1">
                To: {preview.to}
              </div>
              <div className="text-md font-semibold mb-2">
                {preview.subject || <em className="text-zinc-400">(제목 없음)</em>}
              </div>
              <pre className={`${preStyle} m-0`}>
                {preview.body || <em className="text-zinc-400">(본문 없음)</em>}
              </pre>
            </div>
          ) : (
            <div className={`${previewBoxStyle} text-zinc-400 italic`}>
              유효한 수신자가 있으면 미리보기가 표시됩니다.
            </div>
          )}
        </div>
      </div>
    </Card>
  );
}

function Step4Settings({
  settings,
  onChange,
}: {
  settings: CampaignSettings;
  onChange: (s: CampaignSettings) => void;
}) {
  return (
    <Card title="4. 캠페인 설정">
      <div style={{ display: 'grid', gap: 12, maxWidth: 480 }}>
        <Field label="캠페인 이름 (관리용)" required>
          <input
            type="text"
            value={settings.name}
            onChange={(e) => onChange({ ...settings, name: e.target.value })}
            placeholder="2026 Q1 투자자 업데이트"
            className={inputStyle}
          />
        </Field>
        <Field label="발송자 표시 이름 (선택)">
          <input
            type="text"
            value={settings.fromName}
            onChange={(e) => onChange({ ...settings, fromName: e.target.value })}
            placeholder="Your Company Updates"
            className={inputStyle}
          />
        </Field>
        <Field label="발송 주소 (From)" required>
          <input
            type="email"
            value={settings.fromAddress}
            onChange={(e) => onChange({ ...settings, fromAddress: e.target.value })}
            className={inputStyle}
          />
        </Field>
        <Field label="답장 주소 Reply-To (선택)">
          <input
            type="email"
            value={settings.replyToAddress}
            onChange={(e) => onChange({ ...settings, replyToAddress: e.target.value })}
            placeholder="ir@yourcompany.com"
            className={inputStyle}
          />
        </Field>
      </div>
    </Card>
  );
}

function Step5Review({
  settings,
  totalRecipients,
  invalidRows,
  preview,
  fileName,
  submitError,
  onLaunch,
  isPending,
}: {
  settings: CampaignSettings;
  totalRecipients: number;
  invalidRows: number;
  preview: { to: string; subject: string; body: string } | null;
  fileName: string;
  submitError: string | null;
  onLaunch: () => void;
  isPending: boolean;
}) {
  return (
    <Card title="5. 검토 & 캠페인 생성">
      <dl className={dlStyle}>
        <dt>이름</dt><dd>{settings.name}</dd>
        <dt>CSV 파일</dt><dd>{fileName}</dd>
        <dt>유효 수신자</dt>
        <dd>
          <strong>{totalRecipients}명</strong>
          {invalidRows > 0 ? (
            <span style={{ color: '#b91c1c', marginLeft: 8 }}>
              ({invalidRows}명 제외)
            </span>
          ) : null}
        </dd>
        <dt>발송자</dt>
        <dd>
          {settings.fromName ? `${settings.fromName} <${settings.fromAddress}>` : settings.fromAddress}
        </dd>
        {settings.replyToAddress ? (
          <>
            <dt>Reply-To</dt><dd>{settings.replyToAddress}</dd>
          </>
        ) : null}
      </dl>

      {totalRecipients > SYNC_SEND_LIMIT ? (
        <div className={warningBoxStyle}>
          <strong>주의:</strong> {SYNC_SEND_LIMIT}명을 초과하는 캠페인은
          <strong>한 번의 "Start" 호출로 완료되지 않습니다</strong>. 캠페인 생성 후 상세 페이지에서
          여러 번 "이어 발송" 버튼을 누르거나, 별도 워커 프로세스에서 일괄 처리해야 합니다.
        </div>
      ) : null}

      {preview ? (
        <div style={{ marginTop: 16 }}>
          <h3 className={subTitleStyle}>발송 예시 (첫 번째 수신자)</h3>
          <div className={previewBoxStyle}>
            <div className="text-xs text-zinc-400 mb-1">
              From: {settings.fromName ? `${settings.fromName} <${settings.fromAddress}>` : settings.fromAddress}
            </div>
            <div className="text-xs text-zinc-400 mb-1">To: {preview.to}</div>
            <div className="text-md font-semibold mb-2">{preview.subject}</div>
            <pre className={`${preStyle} m-0`}>{preview.body}</pre>
          </div>
        </div>
      ) : null}

      {submitError ? (
        <div className={errorBoxStyle}>
          <strong>생성 실패:</strong> {submitError}
        </div>
      ) : null}

      <div className="mt-6 p-4 bg-warning-subtle border border-warning-border rounded text-base">
        본 단계에서는 <strong>캠페인이 큐(queued) 상태로만 생성</strong>됩니다.
        실제 발송은 다음 페이지에서 <strong>Start</strong> 버튼을 눌러야 시작됩니다.
      </div>

      <button
        type="button"
        onClick={onLaunch}
        disabled={isPending || totalRecipients === 0}
        className="btn-accent mt-6 px-6 py-2.5 text-md font-semibold disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isPending ? '생성 중...' : `캠페인 생성 (${totalRecipients}명)`}
      </button>
    </Card>
  );
}

// ─────────────────────────────────────────────────────────────────────
// 작은 컴포넌트들
// ─────────────────────────────────────────────────────────────────────

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className={cardStyle}>
      <h2 style={{ fontSize: 14, fontWeight: 600, color: '#444', margin: '0 0 16px' }}>
        {title}
      </h2>
      {children}
    </section>
  );
}

function Field({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <label style={{ display: 'grid', gap: 6 }}>
      <span style={{ fontSize: 12, color: '#555', fontWeight: 500 }}>
        {label}
        {required ? <span style={{ color: '#b91c1c' }}> *</span> : null}
      </span>
      {children}
    </label>
  );
}

// ─────────────────────────────────────────────────────────────────────
// 스타일
// ─────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────
// 스타일 (Tailwind utility class 상수 — 사용처에서 className으로 적용)
// ─────────────────────────────────────────────────────────────────────

const cardStyle = 'bg-surface border border-border rounded-md p-6';

const inputStyle =
  'w-full box-border px-3 py-2 text-base border border-border-strong rounded bg-surface focus:outline-none focus:ring-2 focus:ring-zinc-500/30';

const buttonStyle =
  'px-4 py-2 text-base font-medium border-0 rounded cursor-pointer';

const codeStyle =
  'bg-surface-muted px-1.5 py-px rounded-sm text-sm font-mono';

const tagStyle =
  'bg-surface-muted px-2 py-0.5 rounded-sm text-xs font-mono';

const summaryStyle =
  'bg-accent-subtle border border-emerald-200 text-accent-hover px-3 py-2 rounded text-base';

const warningBoxStyle =
  'bg-warning-subtle text-warning-foreground border border-warning-border rounded px-3.5 py-2.5 text-base mt-3';

const errorBoxStyle =
  'bg-destructive-subtle text-destructive border border-destructive-border rounded px-3.5 py-2.5 text-base mt-4';

const previewBoxStyle =
  'bg-surface-subtle border border-border rounded p-3 text-base h-80 overflow-y-auto';

const preStyle = 'whitespace-pre-wrap break-words text-base font-mono m-0';

const tableStyle = 'w-full border-collapse text-sm';

const thStyle =
  'text-left px-2.5 py-1.5 bg-surface-muted font-semibold border-b border-border-strong';

const tdStyle = 'px-2.5 py-1.5 border-b border-border-subtle';

const radioRowStyle =
  'flex items-center gap-3 px-3 py-2 bg-surface-subtle border border-border-subtle rounded cursor-pointer text-base hover:bg-surface-muted transition-colors';

const subTitleStyle =
  'text-xs font-semibold text-zinc-500 uppercase tracking-wide mb-2 mt-0';

const dlStyle =
  'grid grid-cols-[160px_1fr] gap-y-2 gap-x-4 m-0 text-base';
