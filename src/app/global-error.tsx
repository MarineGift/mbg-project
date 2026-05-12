'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="en">
      <body>
        <div style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: 'system-ui, sans-serif',
          padding: '1rem',
        }}>
          <div style={{ textAlign: 'center', maxWidth: '480px' }}>
            <h2 style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>
              Critical Error
            </h2>
            <p style={{ marginBottom: '1.5rem', color: '#666' }}>
              {error.message}
            </p>
            <button
              onClick={reset}
              style={{
                padding: '0.5rem 1.25rem',
                background: '#0f172a',
                color: '#fff',
                border: 0,
                borderRadius: '0.375rem',
                cursor: 'pointer',
              }}
            >
              Try again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
