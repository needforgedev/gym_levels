-- 008_phone_column_fix.sql
-- Fix: 002_schema.sql declared phone_encrypted BYTEA with a
-- "transparent pgcrypto encrypt/decrypt" comment, but no such trigger
-- was ever written, and the Flutter app pushes the column as plain
-- `phone`. The error surfaces as:
--
--   "Could not find the 'phone' column of 'public_profiles' in the
--    schema cache"
--
-- Decision (2026-04-29): drop the bytea column, add `phone TEXT`.
--
-- Rationale:
--   • Supabase Postgres encrypts the whole DB at rest by default
--     (managed-service property). pgcrypto on top would be
--     application-level encryption — overkill for a phone number, and
--     it would break the contact-match flow which compares the plain
--     `phone_hash`.
--   • RLS already prevents other users from reading your phone column
--     (only auth.uid() = user_id can SELECT their own row).
--   • The actual sensitive value — the raw phone — never leaves the
--     row anyway; the contact-match RPC only ever reads/compares
--     `phone_hash`, never `phone` itself.
--
-- Idempotent: safe to re-run.

ALTER TABLE public_profiles
  DROP COLUMN IF EXISTS phone_encrypted;

ALTER TABLE public_profiles
  ADD COLUMN IF NOT EXISTS phone TEXT;

-- No index needed on `phone` itself — lookups go through `phone_hash`.
-- The raw value is only displayed back to the user as "your number on
-- file" inside Settings.
