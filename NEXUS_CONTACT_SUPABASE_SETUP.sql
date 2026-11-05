-- NEXUS HUB Contact: run once in the SAME Supabase project used by Global Chat.
-- Supabase SQL Editor > New query > paste this whole file > Run.
-- Then create your owner account in Authentication > Users > Add user.
-- LAST: run the owner authorization INSERT at the bottom with the real Auth user UUID.

-- Uses built-in PostgreSQL SHA-256; no extension required.

create table if not exists public.nexus_contact_owners (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.nexus_contact_owners enable row level security;
revoke all on public.nexus_contact_owners from anon;
grant select on public.nexus_contact_owners to authenticated;
drop policy if exists "Owner can verify own account" on public.nexus_contact_owners;
create policy "Owner can verify own account" on public.nexus_contact_owners
  for select to authenticated using (user_id = (select auth.uid()));

create table if not exists public.nexus_contact_messages (
 id uuid primary key default gen_random_uuid(),
 username text not null check (char_length(username) between 1 and 40),
 title text not null check (char_length(title) between 1 and 120),
 content text not null check (char_length(content) between 1 and 4000),
 receipt_hash text not null,
 reply text check (reply is null or char_length(reply)<=4000),
 created_at timestamptz not null default now(),
 replied_at timestamptz
);
create index if not exists nexus_contact_messages_created_idx on public.nexus_contact_messages(created_at desc);
alter table public.nexus_contact_messages enable row level security;
revoke all on public.nexus_contact_messages from anon, authenticated;
grant select,update,delete on public.nexus_contact_messages to authenticated;
drop policy if exists "Owner reads inbox" on public.nexus_contact_messages;
drop policy if exists "Owner replies" on public.nexus_contact_messages;
drop policy if exists "Owner deletes" on public.nexus_contact_messages;
create policy "Owner reads inbox" on public.nexus_contact_messages for select to authenticated
 using (exists(select 1 from public.nexus_contact_owners o where o.user_id=(select auth.uid())));
create policy "Owner replies" on public.nexus_contact_messages for update to authenticated
 using (exists(select 1 from public.nexus_contact_owners o where o.user_id=(select auth.uid())))
 with check (exists(select 1 from public.nexus_contact_owners o where o.user_id=(select auth.uid())));
create policy "Owner deletes" on public.nexus_contact_messages for delete to authenticated
 using (exists(select 1 from public.nexus_contact_owners o where o.user_id=(select auth.uid())));

-- Visitors submit through a controlled function; they never receive table read permissions.
create or replace function public.nexus_contact_submit(p_username text,p_title text,p_content text,p_receipt text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare new_id uuid;
begin
 if char_length(trim(p_username)) not between 1 and 40 or
    char_length(trim(p_title)) not between 1 and 120 or
    char_length(trim(p_content)) not between 1 and 4000 or
    p_receipt !~ '^[a-f0-9]{64}$' then
    raise exception 'Invalid message fields';
 end if;
 insert into public.nexus_contact_messages(username,title,content,receipt_hash)
 values(trim(p_username),trim(p_title),trim(p_content),encode(pg_catalog.sha256(pg_catalog.convert_to(p_receipt,'UTF8')),'hex')) returning id into new_id;
 return new_id;
end $$;

-- Receipt possession allows only that single visitor's message and reply to be viewed.
create or replace function public.nexus_contact_check(p_id uuid,p_receipt text)
returns table(content text,reply text) language sql security definer set search_path = '' as $$
 select m.content,m.reply from public.nexus_contact_messages m
 where m.id=p_id and m.receipt_hash=encode(pg_catalog.sha256(pg_catalog.convert_to(p_receipt,'UTF8')),'hex')
 limit 1;
$$;
revoke all on function public.nexus_contact_submit(text,text,text,text) from public;
revoke all on function public.nexus_contact_check(uuid,text) from public;
grant execute on function public.nexus_contact_submit(text,text,text,text) to anon,authenticated;
grant execute on function public.nexus_contact_check(uuid,text) to anon,authenticated;

-- OWNER ACTIVATION (run AFTER creating your account in Supabase Auth):
-- Replace the placeholder UUID with your account's User UID from Authentication > Users.
-- insert into public.nexus_contact_owners(user_id) values ('YOUR-AUTH-USER-UUID-HERE');
-- Never put your Supabase service_role/secret key in HTML or GitHub.
