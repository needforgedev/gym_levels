-- 006_seed.sql
-- Seed data: usernames that should never be claimed by users.
-- Add more entries here as the brand evolves.

INSERT INTO reserved_usernames (username) VALUES
  -- System / brand
  ('admin'),
  ('administrator'),
  ('root'),
  ('system'),
  ('support'),
  ('help'),
  ('staff'),
  ('moderator'),
  ('mod'),
  ('official'),
  ('verified'),
  ('owner'),
  ('founder'),
  ('team'),
  -- Brand
  ('levelupirl'),
  ('level_up_irl'),
  ('levelup'),
  ('iral'),
  ('lui'),
  ('lui_official'),
  -- Common impersonation targets
  ('null'),
  ('undefined'),
  ('void'),
  ('test'),
  ('testing'),
  ('demo'),
  ('default'),
  ('anonymous'),
  ('anon'),
  ('guest'),
  ('user'),
  ('player'),
  -- Service-y handles
  ('api'),
  ('app'),
  ('bot'),
  ('feedback'),
  ('billing'),
  ('payments'),
  ('legal'),
  ('privacy'),
  ('security'),
  ('abuse'),
  ('contact'),
  ('hello'),
  ('info'),
  ('press'),
  ('careers'),
  ('jobs'),
  ('about')
ON CONFLICT DO NOTHING;
