'use client';

/**
 * EmailHtmlFrame - renders an HTML email body in a sandboxed iframe whose height
 * grows to fit the full message, so the email is read with the page's own scroll
 * (no small inner scroll box).
 *
 * Security: sandbox has NO `allow-scripts`, so nothing inside the email can execute.
 * `allow-same-origin` is added only so the parent can measure the content height.
 * (Never add allow-scripts together with allow-same-origin.)
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { cn } from '@/lib/utils';

const MIN_HEIGHT = 200;
const ROOT_ID = 'mbg-email-root';
/** Used until the real content height is known (or if measuring is impossible). */
const FALLBACK_HEIGHT = 'max(420px, calc(100dvh - 200px))';

interface Props {
  html: string;
  className?: string;
  title?: string;
}

export function EmailHtmlFrame({ html, className, title = 'email-body' }: Props) {
  const frameRef = useRef<HTMLIFrameElement>(null);
  const cleanupRef = useRef<(() => void) | null>(null);
  const [height, setHeight] = useState<number | null>(null);

  const measure = useCallback(() => {
    const doc = frameRef.current?.contentDocument;
    if (!doc) return;
    const root = doc.getElementById(ROOT_ID);
    if (!root) return;
    const h = Math.max(
      root.offsetTop + root.offsetHeight,
      root.offsetTop + root.scrollHeight,
    );
    if (h > 0) {
      const next = Math.max(MIN_HEIGHT, Math.ceil(h) + 4);
      setHeight((prev) => (prev === next ? prev : next));
    }
  }, []);

  const setup = useCallback(() => {
    cleanupRef.current?.();
    cleanupRef.current = null;

    const frame = frameRef.current;
    const doc = frame?.contentDocument;
    if (!frame || !doc) return;

    measure();

    const timers = [100, 400, 1000, 2500].map((ms) => window.setTimeout(measure, ms));

    // Late-loading images change the height.
    const onAssetLoad = () => measure();
    doc.addEventListener('load', onAssetLoad, true);
    doc.addEventListener('error', onAssetLoad, true);

    let ro: ResizeObserver | null = null;
    const root = doc.getElementById(ROOT_ID);
    if (root && typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(() => measure());
      ro.observe(root);
    }

    // Width changes (sidebar toggle, window resize) re-flow the email.
    window.addEventListener('resize', onAssetLoad);

    cleanupRef.current = () => {
      timers.forEach((t) => window.clearTimeout(t));
      doc.removeEventListener('load', onAssetLoad, true);
      doc.removeEventListener('error', onAssetLoad, true);
      window.removeEventListener('resize', onAssetLoad);
      ro?.disconnect();
    };
  }, [measure]);

  // The iframe may finish loading before React hydrates (missed onLoad).
  useEffect(() => {
    if (frameRef.current?.contentDocument?.readyState === 'complete') setup();
    return () => {
      cleanupRef.current?.();
      cleanupRef.current = null;
    };
  }, [html, setup]);

  const srcDoc =
    '<base target="_blank">' +
    '<style>html,body{margin:0;padding:0;}</style>' +
    `<div id="${ROOT_ID}" style="display:flow-root;` +
    'font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;' +
    'font-size:14px;line-height:1.6;color:#111;padding:12px;' +
    'word-break:break-word;overflow-wrap:anywhere;">' +
    html +
    '</div>';

  return (
    <iframe
      ref={frameRef}
      title={title}
      sandbox="allow-same-origin allow-popups allow-popups-to-escape-sandbox"
      onLoad={setup}
      className={cn('block w-full rounded-md border border-border bg-white', className)}
      style={{ height: height != null ? `${height}px` : FALLBACK_HEIGHT }}
      srcDoc={srcDoc}
    />
  );
}
