-- ══════════════════════════════════════════════════════
-- P&TO TOC Request — Supabase Schema
-- Paste this entire file into the Supabase SQL Editor
-- and click Run
-- ══════════════════════════════════════════════════════

-- 1. Enable bcrypt for secure password hashing
create extension if not exists pgcrypto;

-- 2. App config (stores hashed password)
create table if not exists app_config (
  key        text primary key,
  value      text not null,
  updated_at timestamptz default now()
);

-- Row Level Security — config table cannot be read directly
alter table app_config enable row level security;
create policy "block_direct_read" on app_config for select using (false);

-- 3. Store hashed password (bcrypt)
insert into app_config (key, value)
values ('password_hash', crypt('tm230', gen_salt('bf')))
on conflict (key) do update set value = excluded.value;

-- 4. Password verify function (server-side, hash never exposed)
create or replace function verify_app_password(input_password text)
returns boolean
language plpgsql
security definer
as $$
declare
  stored_hash text;
begin
  select value into stored_hash from app_config where key = 'password_hash';
  if stored_hash is null then return false; end if;
  return stored_hash = crypt(input_password, stored_hash);
end;
$$;
grant execute on function verify_app_password to anon;

-- 5. List config (feed names, sources, destinations)
create table if not exists toc_lists (
  key        text primary key,
  items      jsonb not null default '[]',
  updated_at timestamptz default now()
);
alter table toc_lists enable row level security;
create policy "anon_all" on toc_lists for all to anon using (true) with check (true);

-- 6. Presets
create table if not exists toc_presets (
  id         uuid default gen_random_uuid() primary key,
  name       text not null,
  feed_count integer default 0,
  data       jsonb not null default '{}',
  created_at timestamptz default now()
);
alter table toc_presets enable row level security;
create policy "anon_all" on toc_presets for all to anon using (true) with check (true);

-- 7. Request history
create table if not exists toc_requests (
  id         uuid default gen_random_uuid() primary key,
  show_name  text not null,
  start_date text,
  start_time text,
  end_date   text,
  end_time   text,
  feeds      jsonb not null default '[]',
  created_at timestamptz default now()
);
alter table toc_requests enable row level security;
create policy "anon_all" on toc_requests for all to anon using (true) with check (true);

-- Done! Your database is ready.
