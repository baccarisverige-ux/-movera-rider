-- Modular production schema. Backend owns these tables.
CREATE TABLE users (id TEXT PRIMARY KEY, phone TEXT UNIQUE, created_at TIMESTAMPTZ NOT NULL);
CREATE TABLE riders (id TEXT PRIMARY KEY, user_id TEXT NOT NULL);
CREATE TABLE drivers (id TEXT PRIMARY KEY, user_id TEXT NOT NULL);
CREATE TABLE vehicles (id TEXT PRIMARY KEY, driver_id TEXT NOT NULL, plate TEXT);
CREATE TABLE rides (id TEXT PRIMARY KEY, rider_id TEXT NOT NULL, status TEXT NOT NULL);
CREATE TABLE ride_status_events (
  id TEXT PRIMARY KEY,
  ride_id TEXT NOT NULL,
  status TEXT NOT NULL,
  at TIMESTAMPTZ NOT NULL
);
CREATE TABLE quotes (id TEXT PRIMARY KEY, ride_id TEXT, amount_minor INT NOT NULL, expires_at TIMESTAMPTZ NOT NULL);
CREATE TABLE payments (id TEXT PRIMARY KEY, ride_id TEXT, amount_minor INT NOT NULL, status TEXT NOT NULL);
CREATE TABLE wallets (id TEXT PRIMARY KEY, rider_id TEXT NOT NULL);
CREATE TABLE wallet_transactions (
  id TEXT PRIMARY KEY,
  wallet_id TEXT NOT NULL,
  amount_minor INT NOT NULL,
  kind TEXT NOT NULL,
  at TIMESTAMPTZ NOT NULL
);
CREATE TABLE promotions (id TEXT PRIMARY KEY, title TEXT NOT NULL, active BOOLEAN NOT NULL);
CREATE TABLE saved_places (id TEXT PRIMARY KEY, rider_id TEXT NOT NULL, label TEXT NOT NULL);
CREATE TABLE scheduled_rides (id TEXT PRIMARY KEY, ride_id TEXT NOT NULL, scheduled_at TIMESTAMPTZ NOT NULL);
CREATE TABLE support_cases (id TEXT PRIMARY KEY, rider_id TEXT NOT NULL, status TEXT NOT NULL);
CREATE TABLE safety_events (id TEXT PRIMARY KEY, ride_id TEXT, kind TEXT NOT NULL, at TIMESTAMPTZ NOT NULL);
