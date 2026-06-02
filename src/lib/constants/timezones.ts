// src/lib/constants/timezones.ts
// Single source of truth for the timezone selector and its server-side validation.
// Plain module (no server-only / client-only) so both the Server Action and the
// client form can import it.

export interface TimezoneOption {
  /** IANA timezone identifier, e.g. "America/Chicago". */
  value: string;
  /** Human-readable label shown in the dropdown. */
  label: string;
}

/** Default display timezone: US Central (Texas / company HQ). */
export const DEFAULT_TIMEZONE = 'America/Chicago';

/** Allowed timezones for the profile selector. Keep values as valid IANA ids. */
export const SUPPORTED_TIMEZONES: readonly TimezoneOption[] = [
  { value: 'America/Chicago', label: 'US Central (Texas) - CST/CDT' },
  { value: 'America/New_York', label: 'US Eastern - EST/EDT' },
  { value: 'America/Denver', label: 'US Mountain - MST/MDT' },
  { value: 'America/Los_Angeles', label: 'US Pacific - PST/PDT' },
  { value: 'Asia/Seoul', label: 'Korea (Seoul) - KST' },
  { value: 'Asia/Tokyo', label: 'Japan (Tokyo) - JST' },
  { value: 'Europe/London', label: 'UK (London) - GMT/BST' },
  { value: 'UTC', label: 'UTC' },
] as const;

export const SUPPORTED_TIMEZONE_VALUES: readonly string[] = SUPPORTED_TIMEZONES.map(
  (t) => t.value,
);

/** True if the given string is one of the supported IANA timezones. */
export function isSupportedTimezone(value: string): boolean {
  return SUPPORTED_TIMEZONE_VALUES.includes(value);
}
