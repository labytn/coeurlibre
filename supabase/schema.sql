-- Cœur Libre — schéma de production (Supabase / Postgres)
-- À exécuter une seule fois dans Supabase > SQL Editor.

create extension if not exists pgcrypto;

-- ───────── Tables ─────────
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 40),
  birthdate date,
  gender text check (gender in ('homme','femme','autre')),
  looking_for text check (looking_for in ('homme','femme','tous')),
  city text check (char_length(city) <= 80),
  bio text not null default '' check (char_length(bio) <= 500),
  interests text[] not null default '{}' check (cardinality(interests) <= 10),
  photo_paths text[] not null default '{}' check (cardinality(photo_paths) <= 6),
  is_complete boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.swipes (
  swiper_id uuid not null references auth.users(id) on delete cascade,
  target_id uuid not null references auth.users(id) on delete cascade,
  liked boolean not null,
  created_at timestamptz not null default now(),
  primary key (swiper_id, target_id),
  check (swiper_id <> target_id)
);

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_a, user_b),
  check (user_a < user_b)
);

create table public.messages (
  id bigint generated always as identity primary key,
  match_id uuid not null references public.matches(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index messages_match_idx on public.messages (match_id, created_at);

create table public.blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table public.reports (
  id bigint generated always as identity primary key,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (char_length(reason) between 3 and 500),
  created_at timestamptz not null default now()
);

-- ───────── Contrôles profil (majorité, complétude, dossier photo) ─────────
create function public.profiles_guard() returns trigger
language plpgsql as $$
begin
  if new.birthdate is not null and new.birthdate > current_date - interval '18 years' then
    raise exception 'Vous devez avoir 18 ans minimum.';
  end if;
  if exists (select 1 from unnest(new.photo_paths) p where p not like new.id::text || '/%') then
    raise exception 'Chemin de photo invalide.';
  end if;
  new.is_complete := new.display_name <> '' and new.birthdate is not null
    and new.gender is not null and new.looking_for is not null
    and coalesce(new.city, '') <> '' and cardinality(new.photo_paths) >= 1;
  return new;
end $$;

create trigger profiles_guard before insert or update on public.profiles
for each row execute function public.profiles_guard();

-- ───────── Fonctions ─────────
create function public.is_blocked(a uuid, b uuid) returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a))
$$;

create function public.swipe(p_target uuid, p_liked boolean) returns boolean
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); matched boolean := false;
begin
  if me is null then raise exception 'Non authentifié.'; end if;
  if me = p_target or is_blocked(me, p_target)
     or not exists (select 1 from profiles where id = p_target and is_complete)
     or not exists (select 1 from profiles where id = me and is_complete) then
    raise exception 'Profil invalide.';
  end if;
  insert into swipes (swiper_id, target_id, liked) values (me, p_target, p_liked)
  on conflict (swiper_id, target_id) do update set liked = excluded.liked;
  if p_liked and exists (select 1 from swipes where swiper_id = p_target and target_id = me and liked) then
    insert into matches (user_a, user_b) values (least(me, p_target), greatest(me, p_target))
    on conflict do nothing;
    matched := true;
  end if;
  return matched;
end $$;

create function public.discover_profiles(p_limit int default 20)
returns table (id uuid, display_name text, age int, city text, bio text, interests text[], photo_paths text[])
language sql security definer set search_path = public stable as $$
  select p.id, p.display_name, date_part('year', age(p.birthdate))::int, p.city, p.bio, p.interests, p.photo_paths
  from profiles p
  join profiles m on m.id = auth.uid() and m.is_complete
  where p.id <> m.id and p.is_complete
    and (m.looking_for = 'tous' or p.gender = m.looking_for)
    and (p.looking_for = 'tous' or p.looking_for = m.gender)
    and not exists (select 1 from swipes s where s.swiper_id = m.id and s.target_id = p.id)
    and not is_blocked(m.id, p.id)
  order by random()
  limit least(greatest(p_limit, 1), 50)
$$;

create function public.search_profiles(p_min int, p_max int, p_city text, p_interest text)
returns table (id uuid, display_name text, age int, city text, bio text, interests text[], photo_paths text[], liked boolean)
language sql security definer set search_path = public stable as $$
  select p.id, p.display_name, date_part('year', age(p.birthdate))::int, p.city, p.bio, p.interests, p.photo_paths,
         coalesce((select s.liked from swipes s where s.swiper_id = m.id and s.target_id = p.id), false)
  from profiles p
  join profiles m on m.id = auth.uid() and m.is_complete
  where p.id <> m.id and p.is_complete
    and (m.looking_for = 'tous' or p.gender = m.looking_for)
    and (p.looking_for = 'tous' or p.looking_for = m.gender)
    and not is_blocked(m.id, p.id)
    and date_part('year', age(p.birthdate)) between greatest(p_min, 18) and least(p_max, 120)
    and (coalesce(p_city, '') = '' or p.city ilike '%' || replace(replace(p_city, '%', ''), '_', '') || '%')
    and (coalesce(p_interest, '') = '' or exists (select 1 from unnest(p.interests) i where lower(i) = lower(p_interest)))
  order by p.created_at desc
  limit 100
$$;

create function public.my_matches()
returns table (match_id uuid, other_id uuid, display_name text, photo_paths text[], created_at timestamptz)
language sql security definer set search_path = public stable as $$
  select m.id, o.id, o.display_name, o.photo_paths, m.created_at
  from matches m
  join profiles o on o.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end
  where auth.uid() in (m.user_a, m.user_b) and not is_blocked(m.user_a, m.user_b)
  order by m.created_at desc
$$;

create function public.delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  if auth.uid() is null then raise exception 'Non authentifié.'; end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke execute on all functions in schema public from public, anon;
grant execute on function public.is_blocked(uuid, uuid), public.swipe(uuid, boolean),
  public.discover_profiles(int), public.search_profiles(int, int, text, text),
  public.my_matches(), public.delete_my_account() to authenticated;

-- ───────── Row Level Security ─────────
alter table public.profiles enable row level security;
alter table public.swipes   enable row level security;
alter table public.matches  enable row level security;
alter table public.messages enable row level security;
alter table public.blocks   enable row level security;
alter table public.reports  enable row level security;

-- profiles : chacun ne lit/écrit que sa ligne (les autres profils passent par les fonctions)
create policy profiles_own on public.profiles for all to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- swipes : aucun accès direct (tout passe par swipe())

create policy matches_read on public.matches for select to authenticated
  using (auth.uid() in (user_a, user_b));

create policy messages_read on public.messages for select to authenticated
  using (exists (select 1 from public.matches m where m.id = match_id and auth.uid() in (m.user_a, m.user_b)));

create policy messages_send on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and exists (
    select 1 from public.matches m
    where m.id = match_id and auth.uid() in (m.user_a, m.user_b) and not public.is_blocked(m.user_a, m.user_b)));

create policy blocks_own on public.blocks for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

create policy reports_insert on public.reports for insert to authenticated
  with check (reporter_id = auth.uid());

-- ───────── Temps réel ─────────
alter publication supabase_realtime add table public.messages;

-- ───────── Stockage photos (bucket privé, URLs signées) ─────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy photos_read on storage.objects for select to authenticated
  using (bucket_id = 'photos');
create policy photos_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy photos_update on storage.objects for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy photos_delete on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
