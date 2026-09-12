-- Non-destructive Safety schema. Additive only.
CREATE TABLE IF NOT EXISTS safety_preferences (
  user_id TEXT PRIMARY KEY,
  pin_required BOOLEAN NOT NULL DEFAULT FALSE,
  trip_share_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  trip_share_mode TEXT NOT NULL DEFAULT 'manual',
  trip_share_contact_ids JSONB NOT NULL DEFAULT '[]',
  ridecheck_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  version INT NOT NULL DEFAULT 1
);

-- PIN value is backend-authoritative. Do not log pin_hash.
CREATE TABLE IF NOT EXISTS ride_pins (
  pin_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  pin_hash TEXT NOT NULL,
  required_for_start BOOLEAN NOT NULL DEFAULT FALSE,
  rotated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  version INT NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  phone_e164 TEXT NOT NULL,
  relationship TEXT NOT NULL DEFAULT 'Other',
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  share_trips BOOLEAN NOT NULL DEFAULT FALSE,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trip_shares (
  share_id TEXT PRIMARY KEY,
  ride_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  contact_ids JSONB NOT NULL DEFAULT '[]',
  share_token TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  UNIQUE (share_token)
);

CREATE TABLE IF NOT EXISTS ridecheck_events (
  event_id TEXT PRIMARY KEY,
  ride_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  payload JSONB NOT NULL DEFAULT '{}',
  at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS safety_audio (
  id TEXT PRIMARY KEY,
  ride_id TEXT,
  duration_ms INT NOT NULL DEFAULT 0,
  upload_status TEXT NOT NULL DEFAULT 'localOnly',
  remote_id TEXT,
  encryption_state TEXT NOT NULL DEFAULT 'local',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS emergency_contacts_user_idx ON emergency_contacts (user_id);
CREATE INDEX IF NOT EXISTS trip_shares_ride_idx ON trip_shares (ride_id);
CREATE INDEX IF NOT EXISTS ridecheck_events_ride_idx ON ridecheck_events (ride_id);
