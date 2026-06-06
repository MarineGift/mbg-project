// src/lib/queries/country-peers.ts
// Shared type for the country-peers panel. The server wrapper
// (components/parties/country-peers-panel.tsx) fetches peer rows inline and
// passes them to the client component (country-peers-panel-client.tsx), which
// only needs this shape. (This module was referenced but never committed,
// which broke `tsc`; this restores it.)

export interface CountryPeer {
  id: string;
  module: string;
  name: string;
  tier?: string | null;
  status?: string | null;
  tags?: string[] | null;
  description?: string | null;
  city?: string | null;
  party_level?: string | null;
}
