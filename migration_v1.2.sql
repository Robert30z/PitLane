-- ============================================================
-- PitLane v1.2 migration — run once in Supabase → SQL Editor → Run
-- Safe to re-run (idempotent). Adds the security + polish layer
-- for the v1.2 overhaul. The app already works without this; this
-- hardens it and turns on view counts + live un-flag/un-RSVP.
-- ============================================================

-- 1) SECURITY: freeze master/founder against browser writes.
--    Without this, a logged-in user could POST {master:true} to
--    their own profile and become a second founder with admin powers.
create or replace function guard_master() returns trigger as $$
begin
  if current_setting('role', true) = 'service_role' or current_user = 'postgres' then
    return new;                     -- trusted path (SQL editor / admin): allow
  end if;
  if tg_op = 'INSERT' then
    new.master  := false;
    new.founder := false;
  else
    new.master  := old.master;      -- keep whatever the server last set
    new.founder := old.founder;
  end if;
  if new.data is not null then
    new.data := (new.data - 'master') - 'founder';
  end if;
  return new;
end $$ language plpgsql security definer;
drop trigger if exists trg_master on profiles;
create trigger trg_master before insert or update on profiles
  for each row execute function guard_master();

-- 2) Grant the founder their crown (runs as the privileged SQL-editor role):
update profiles set master = true, founder = true
 where id = (select id from auth.users where email = 'rjohn7148@gmail.com');

-- 3) VIEW COUNTER: buyers aren't the listing owner, so RLS blocks them
--    from writing the row. This SECURITY DEFINER fn does it server-side.
create or replace function bump_view(lid text) returns void as $$
  update listings
     set data = jsonb_set(data, '{views}',
                to_jsonb(coalesce((data->>'views')::int, 0) + 1))
   where data->>'id' = lid;
$$ language sql security definer;

-- 4) app_data policies (no-op if they already exist from the earlier setup)
alter table if exists app_data enable row level security;
do $$ begin
  create policy "public read app_data"  on app_data for select using (true);
  create policy "authed write app_data" on app_data for insert with check (auth.uid() = owner);
  create policy "owner update app_data" on app_data for update using (auth.uid() = owner);
  create policy "owner delete app_data" on app_data for delete using (auth.uid() = owner);
exception when duplicate_object then null; end $$;

-- 5) Broadcast DELETEs with the old row id so un-flag / un-RSVP /
--    dismissed-report propagate live to other clients.
alter table app_data replica identity full;
alter table listings replica identity full;
