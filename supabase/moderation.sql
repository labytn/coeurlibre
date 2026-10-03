-- Cœur Libre — modération + vérification de profil
-- À exécuter APRÈS schema.sql, une seule fois, dans Supabase > SQL Editor.

-- ───────── Colonnes ─────────
alter table public.profiles
  add column status text not null default 'active' check (status in ('active','suspended','banned')),
  add column verified boolean not null default false;

alter table public.reports
  add column status text not null default 'open' check (status in ('open','resolved','dismissed')),
  add column action text,
  add column resolved_by uuid references auth.users(id) on delete set null,
  add column resolved_at timestamptz;

create table public.admins (user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.admins enable row level security;

create table public.verifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  selfie_path text,
  challenge text not null,
  distance real not null,
  status text not null check (status in ('verified','pending','rejected')),
  auto boolean not null default false,
  consent_at timestamptz not null,
  reviewed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index verifications_user_idx on public.verifications (user_id, created_at);
alter table public.verifications enable row level security;
create policy verifications_own on public.verifications for select to authenticated
  using (user_id = auth.uid());

-- ───────── Garde profil : status/verified non modifiables par l'utilisateur ─────────
create or replace function public.profiles_guard() returns trigger
language plpgsql as $$
declare bypass boolean := coalesce(current_setting('app.bypass', true), '') = '1';
begin
  if new.birthdate is not null and new.birthdate > current_date - interval '18 years' then
    raise exception 'Vous devez avoir 18 ans minimum.';
  end if;
  if exists (select 1 from unnest(new.photo_paths) p where p not like new.id::text || '/%') then
    raise exception 'Chemin de photo invalide.';
  end if;
  if tg_op = 'INSERT' then
    if not bypass then new.status := 'active'; new.verified := false; end if;
  elsif not bypass then
    new.status := old.status;
    if new.photo_paths is distinct from old.photo_paths then new.verified := false;
    else new.verified := old.verified; end if;
  end if;
  new.is_complete := new.display_name <> '' and new.birthdate is not null
    and new.gender is not null and new.looking_for is not null
    and coalesce(new.city, '') <> '' and cardinality(new.photo_paths) >= 1;
  return new;
end $$;

-- ───────── Un compte suspendu/banni est invisible et ne peut plus interagir ─────────
create or replace function public.is_blocked(a uuid, b uuid) returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from blocks
           where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a))
      or exists (select 1 from profiles where id in (a, b) and status <> 'active')
$$;

create function public.is_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from admins where user_id = auth.uid())
$$;

-- ───────── Découverte / recherche avec badge « vérifié » ─────────
drop function public.discover_profiles(int);
create function public.discover_profiles(p_limit int default 20)
returns table (id uuid, display_name text, age int, city text, bio text, interests text[], photo_paths text[], verified boolean)
language sql security definer set search_path = public stable as $$
  select p.id, p.display_name, date_part('year', age(p.birthdate))::int, p.city, p.bio, p.interests, p.photo_paths, p.verified
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

drop function public.search_profiles(int, int, text, text);
create function public.search_profiles(p_min int, p_max int, p_city text, p_interest text, p_verified boolean default false)
returns table (id uuid, display_name text, age int, city text, bio text, interests text[], photo_paths text[], liked boolean, verified boolean)
language sql security definer set search_path = public stable as $$
  select p.id, p.display_name, date_part('year', age(p.birthdate))::int, p.city, p.bio, p.interests, p.photo_paths,
         coalesce((select s.liked from swipes s where s.swiper_id = m.id and s.target_id = p.id), false), p.verified
  from profiles p
  join profiles m on m.id = auth.uid() and m.is_complete
  where p.id <> m.id and p.is_complete
    and (m.looking_for = 'tous' or p.gender = m.looking_for)
    and (p.looking_for = 'tous' or p.looking_for = m.gender)
    and not is_blocked(m.id, p.id)
    and (not coalesce(p_verified, false) or p.verified)
    and date_part('year', age(p.birthdate)) between greatest(p_min, 18) and least(p_max, 120)
    and (coalesce(p_city, '') = '' or p.city ilike '%' || replace(replace(p_city, '%', ''), '_', '') || '%')
    and (coalesce(p_interest, '') = '' or exists (select 1 from unnest(p.interests) i where lower(i) = lower(p_interest)))
  order by p.created_at desc
  limit 100
$$;

-- ───────── Vérification de profil (automatique + revue manuelle) ─────────
-- Distance de visage (selfie vs photos) : <= 0.5 vérifié auto, <= 0.6 revue manuelle, sinon refus.
create function public.submit_verification(p_selfie text, p_challenge text, p_distance real, p_consent boolean)
returns text language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); st text;
begin
  if me is null then raise exception 'Non authentifié.'; end if;
  if not coalesce(p_consent, false) then raise exception 'Consentement requis.'; end if;
  if p_selfie not like me::text || '/%' or p_distance is null or p_distance < 0 or p_distance > 2 then
    raise exception 'Données invalides.';
  end if;
  if not exists (select 1 from storage.objects where bucket_id = 'selfies' and name = p_selfie) then
    raise exception 'Selfie introuvable.';
  end if;
  if exists (select 1 from profiles where id = me and status <> 'active') then
    raise exception 'Compte restreint.';
  end if;
  if (select count(*) from verifications where user_id = me and created_at > now() - interval '24 hours') >= 3 then
    raise exception 'Trop de tentatives, réessayez demain.';
  end if;
  st := case when p_distance <= 0.5 then 'verified' when p_distance <= 0.6 then 'pending' else 'rejected' end;
  insert into verifications (user_id, selfie_path, challenge, distance, status, auto, consent_at)
  values (me, p_selfie, p_challenge, p_distance, st, st = 'verified', now());
  if st = 'verified' then
    perform set_config('app.bypass', '1', true);
    update profiles set verified = true where id = me;
  end if;
  return st;
end $$;

-- ───────── Fonctions d'administration (toutes protégées par is_admin) ─────────
create function public.admin_open_reports()
returns table (id bigint, reason text, created_at timestamptz, reporter_name text, reported_id uuid,
               reported_name text, reported_status text, reported_photo text, report_count bigint)
language sql security definer set search_path = public stable as $$
  select r.id, r.reason, r.created_at, rp.display_name, r.reported_id, dp.display_name, dp.status,
         dp.photo_paths[1], (select count(*) from reports x where x.reported_id = r.reported_id)
  from reports r
  left join profiles rp on rp.id = r.reporter_id
  left join profiles dp on dp.id = r.reported_id
  where is_admin() and r.status = 'open'
  order by r.created_at
$$;

create function public.admin_resolve_report(p_id bigint, p_action text) returns void
language plpgsql security definer set search_path = public as $$
declare t uuid;
begin
  if not is_admin() then raise exception 'Accès refusé.'; end if;
  if p_action not in ('dismiss','suspend','ban') then raise exception 'Action invalide.'; end if;
  select reported_id into t from reports where id = p_id;
  if t is null then raise exception 'Signalement introuvable.'; end if;
  perform set_config('app.bypass', '1', true);
  if p_action <> 'dismiss' then
    update profiles set status = case p_action when 'ban' then 'banned' else 'suspended' end where id = t;
  end if;
  update reports
     set status = case when p_action = 'dismiss' then 'dismissed' else 'resolved' end,
         action = p_action, resolved_by = auth.uid(), resolved_at = now()
   where id = p_id or (reported_id = t and status = 'open' and p_action <> 'dismiss');
end $$;

create function public.admin_set_status(p_user uuid, p_status text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Accès refusé.'; end if;
  if p_status not in ('active','suspended','banned') then raise exception 'Statut invalide.'; end if;
  perform set_config('app.bypass', '1', true);
  update profiles set status = p_status where id = p_user;
end $$;

create function public.admin_sanctioned()
returns table (id uuid, name text, status text)
language sql security definer set search_path = public stable as $$
  select p.id, p.display_name, p.status from profiles p where is_admin() and p.status <> 'active' order by p.display_name
$$;

create function public.admin_verifications()
returns table (id bigint, user_id uuid, name text, selfie_path text, photo_path text, distance real,
               status text, auto boolean, created_at timestamptz)
language sql security definer set search_path = public stable as $$
  select v.id, v.user_id, p.display_name, v.selfie_path, p.photo_paths[1], v.distance, v.status, v.auto, v.created_at
  from verifications v join profiles p on p.id = v.user_id
  where is_admin() and v.selfie_path is not null
    and (v.status = 'pending' or (v.auto and v.status = 'verified' and v.created_at > now() - interval '30 days'))
  order by (v.status = 'pending') desc, v.created_at desc
  limit 100
$$;

create function public.admin_review_verification(p_id bigint, p_approve boolean) returns void
language plpgsql security definer set search_path = public as $$
declare t uuid;
begin
  if not is_admin() then raise exception 'Accès refusé.'; end if;
  update verifications
     set status = case when p_approve then 'verified' else 'rejected' end, reviewed_by = auth.uid(), selfie_path = null
   where id = p_id returning user_id into t;
  if t is null then raise exception 'Vérification introuvable.'; end if;
  perform set_config('app.bypass', '1', true);
  update profiles set verified = p_approve where id = t;
end $$;

create function public.admin_old_selfies() returns table (id bigint, selfie_path text)
language sql security definer set search_path = public stable as $$
  select v.id, v.selfie_path from verifications v
  where is_admin() and v.selfie_path is not null and v.status <> 'pending' and v.created_at < now() - interval '30 days'
$$;

create function public.admin_clear_selfies(p_ids bigint[]) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Accès refusé.'; end if;
  update verifications set selfie_path = null where id = any(p_ids);
end $$;

-- ───────── Stockage des selfies (bucket privé) ─────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('selfies', 'selfies', false, 3145728, array['image/jpeg'])
on conflict (id) do nothing;

create policy selfies_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'selfies' and (storage.foldername(name))[1] = auth.uid()::text);
create policy selfies_read on storage.objects for select to authenticated
  using (bucket_id = 'selfies' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
create policy selfies_delete on storage.objects for delete to authenticated
  using (bucket_id = 'selfies' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- ───────── Droits d'exécution ─────────
revoke execute on all functions in schema public from public, anon;
grant execute on function
  public.is_blocked(uuid, uuid), public.is_admin(), public.swipe(uuid, boolean),
  public.discover_profiles(int), public.search_profiles(int, int, text, text, boolean),
  public.my_matches(), public.delete_my_account(),
  public.submit_verification(text, text, real, boolean),
  public.admin_open_reports(), public.admin_resolve_report(bigint, text), public.admin_set_status(uuid, text),
  public.admin_sanctioned(), public.admin_verifications(), public.admin_review_verification(bigint, boolean),
  public.admin_old_selfies(), public.admin_clear_selfies(bigint[])
to authenticated;
