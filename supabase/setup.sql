-- Floor & Decor Merch Review — Supabase setup (run once in Supabase > SQL Editor > New query > Run)
-- Creates: the approved-reviewer list, one storage table for the site (items, decisions, samples, layouts),
-- and security rules so only approved, signed-in people can read or save anything.

create table if not exists public.allowed_users (
  email text primary key,
  name  text,
  role  text not null default 'reviewer' check (role in ('reviewer','admin'))
);

create table if not exists public.kv (
  collection text not null,
  id         text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by text,
  primary key (collection, id)
);
create index if not exists kv_coll_updated on public.kv (collection, updated_at);

-- who is signing in (null = not on the list)
create or replace function public.my_role() returns text
language sql stable security definer set search_path = public as $$
  select role from public.allowed_users where email = lower(coalesce(auth.jwt() ->> 'email', ''))
$$;

-- stamp every save with the time and the signed-in email
create or replace function public.kv_stamp() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := clock_timestamp();
  new.updated_by := lower(coalesce(auth.jwt() ->> 'email', new.updated_by));
  return new;
end $$;
drop trigger if exists kv_stamp on public.kv;
create trigger kv_stamp before insert or update on public.kv for each row execute function public.kv_stamp();

alter table public.allowed_users enable row level security;
alter table public.kv enable row level security;

drop policy if exists "see own row or admin" on public.allowed_users;
create policy "see own row or admin" on public.allowed_users for select to authenticated
  using (email = lower(auth.jwt() ->> 'email') or public.my_role() = 'admin');

drop policy if exists "approved can read" on public.kv;
create policy "approved can read" on public.kv for select to authenticated
  using (public.my_role() is not null);

drop policy if exists "approved can add" on public.kv;
create policy "approved can add" on public.kv for insert to authenticated
  with check (public.my_role() is not null and (collection <> 'site' or public.my_role() = 'admin'));

drop policy if exists "approved can change" on public.kv;
create policy "approved can change" on public.kv for update to authenticated
  using (public.my_role() is not null and (collection <> 'site' or public.my_role() = 'admin'))
  with check (public.my_role() is not null and (collection <> 'site' or public.my_role() = 'admin'));

drop policy if exists "admin can delete" on public.kv;
create policy "admin can delete" on public.kv for delete to authenticated
  using (public.my_role() = 'admin');

revoke all on public.kv, public.allowed_users from anon;
grant select, insert, update, delete on public.kv to authenticated;
grant select on public.allowed_users to authenticated;

-- ===== Approved people (edit this list any time and re-run just these lines) =====
insert into public.allowed_users (email, name, role) values
  ('jessicac@corp-imaging.com', 'Jessica Cole', 'admin')
on conflict (email) do update set name = excluded.name, role = excluded.role;

-- Add reviewers like this (use their exact email, lowercase):
-- insert into public.allowed_users (email, name, role) values
--   ('first.last@example.com', 'First Last', 'reviewer')
-- on conflict (email) do update set name = excluded.name, role = excluded.role;

-- Remove someone:
-- delete from public.allowed_users where email = 'first.last@example.com';
