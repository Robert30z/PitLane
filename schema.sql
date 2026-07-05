-- ============================================================
-- PitLane — Phase 2 backend schema (Supabase / Postgres)
-- Turns the prototype (per-device localStorage) into a real
-- shared, multi-user app with real email verification.
-- Run this in Supabase → SQL Editor → New query → Run.
-- ============================================================

-- USERS (profile rows; auth handled by Supabase Auth = real email verification)
create table if not exists profiles (
  id            uuid primary key references auth.users on delete cascade,
  profile_no    text unique,               -- PL-0001 etc (assigned by trigger below)
  first_name    text not null,
  last_name     text not null,
  nick          text not null,
  bio           text default '',
  verified      boolean default false,     -- true once email confirmed
  founder       boolean default false,
  master        boolean default false,     -- gold name / master control (founder only)
  prestige      int default 0,
  xp            int default 0,
  race_wins     int default 0,
  eq_title      text,
  eq_emblem     jsonb,                      -- [name, color]
  eq_card       text,
  eq_name       text,                       -- name color hex (gold blocked for non-master by policy)
  clan_id       uuid,
  loc           jsonb default '{"visible":false}'::jsonb,
  car_photos    jsonb default '[]'::jsonb,  -- storage URLs
  created_at    timestamptz default now()
);

-- GARAGE (multiple vehicles per user)
create table if not exists vehicles (
  id            uuid primary key default gen_random_uuid(),
  owner         uuid references profiles(id) on delete cascade,
  discipline    text,                       -- Street / Circuit / Rally / Drift / Drag ...
  brand         text, model text, year text,
  paint         text, rim text, rim_color text,
  stance        text, drive text, hp text,
  mods          text,
  created_at    timestamptz default now()
);

-- LISTINGS (marketplace)
create table if not exists listings (
  id            uuid primary key default gen_random_uuid(),
  seller        uuid references profiles(id) on delete cascade,
  category      text not null,              -- cars / moto / atv / water / parts
  title         text not null, model text,
  price         numeric not null,
  location      text,
  miles         int, title_status text, vin text,
  mods          jsonb default '[]'::jsonb,
  description   text,
  photos        jsonb default '[]'::jsonb,  -- storage URLs (6 required, enforced in app)
  boosted       boolean default false,
  boosted_until timestamptz,
  created_at    timestamptz default now()
);

-- EVENTS + RSVPs
create table if not exists events (
  id            uuid primary key default gen_random_uuid(),
  host          uuid references profiles(id) on delete cascade,
  type          text, title text not null,
  starts_on     date, venue text, description text,
  sanctioned    boolean default true,       -- app requires this true
  created_at    timestamptz default now()
);
create table if not exists rsvps (
  event_id uuid references events(id) on delete cascade,
  user_id  uuid references profiles(id) on delete cascade,
  primary key (event_id, user_id)
);

-- CLANS
create table if not exists clans (
  id       uuid primary key default gen_random_uuid(),
  tag      text not null, name text not null,
  color    text, about text,
  owner    uuid references profiles(id) on delete set null,
  created_at timestamptz default now()
);
create table if not exists clan_members (
  clan_id uuid references clans(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  primary key (clan_id, user_id)
);

-- CHAT
create table if not exists threads (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references listings(id) on delete set null,
  created_at timestamptz default now()
);
create table if not exists thread_users (
  thread_id uuid references threads(id) on delete cascade,
  user_id   uuid references profiles(id) on delete cascade,
  primary key (thread_id, user_id)
);
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid references threads(id) on delete cascade,
  sender    uuid references profiles(id) on delete cascade,
  body      text not null,
  created_at timestamptz default now()
);

-- REVIEW QUEUE (mission proofs + race-win claims → Master approves)
create table if not exists review_queue (
  id uuid primary key default gen_random_uuid(),
  user_id  uuid references profiles(id) on delete cascade,
  kind     text not null,                   -- 'proof' | 'race'
  mission_id text,
  video_url text, note text, claim int default 1,
  status   text default 'pending',          -- pending | approved | denied
  created_at timestamptz default now()
);

-- Auto-assign PL-#### profile numbers
create sequence if not exists pl_seq start 1;
create or replace function assign_profile_no() returns trigger as $$
begin
  new.profile_no := 'PL-' || lpad(nextval('pl_seq')::text, 4, '0');
  return new;
end $$ language plpgsql;
drop trigger if exists trg_profile_no on profiles;
create trigger trg_profile_no before insert on profiles
  for each row when (new.profile_no is null) execute function assign_profile_no();

-- ============================================================
-- Row Level Security (so users can only edit their own stuff,
-- everyone can read public marketplace/community data)
-- ============================================================
alter table profiles enable row level security;
alter table vehicles enable row level security;
alter table listings enable row level security;
alter table events   enable row level security;
alter table clans    enable row level security;

create policy "public read profiles"  on profiles for select using (true);
create policy "self update profile"    on profiles for update using (auth.uid() = id);
create policy "self insert profile"    on profiles for insert with check (auth.uid() = id);

create policy "public read listings"   on listings for select using (true);
create policy "owner writes listing"   on listings for all
  using (auth.uid() = seller) with check (auth.uid() = seller);

create policy "public read vehicles"   on vehicles for select using (true);
create policy "owner writes vehicle"   on vehicles for all
  using (auth.uid() = owner) with check (auth.uid() = owner);

create policy "public read events"     on events for select using (true);
create policy "host writes event"      on events for all
  using (auth.uid() = host) with check (auth.uid() = host);

-- GOLD-NAME GUARD: block non-master users from setting gold (#FFD34D)
create or replace function guard_gold() returns trigger as $$
begin
  if new.eq_name = '#FFD34D' and coalesce(new.master, false) = false then
    new.eq_name := null;   -- silently strip gold from non-founders
  end if;
  return new;
end $$ language plpgsql;
drop trigger if exists trg_gold on profiles;
create trigger trg_gold before insert or update on profiles
  for each row execute function guard_gold();
