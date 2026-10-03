-- Cœur Libre — profils de démonstration (marqués « DÉMO »)
-- À exécuter APRÈS schema.sql et moderation.sql. Pour tout retirer : demo_remove.sql

begin;

alter table public.profiles add column if not exists is_demo boolean not null default false;

-- Un utilisateur ne peut ni créer ni modifier un profil démo.
drop policy if exists profiles_own on public.profiles;
create policy profiles_own on public.profiles for all to authenticated
  using (id = auth.uid() and not is_demo) with check (id = auth.uid() and not is_demo);

-- ───────── Fonctions mises à jour (champ is_demo + match automatique avec les démos) ─────────
drop function if exists public.discover_profiles(int);
create function public.discover_profiles(p_limit int default 20)
returns table (id uuid, display_name text, age int, city text, bio text, interests text[], photo_paths text[], verified boolean, is_demo boolean)
language sql security definer set search_path = public stable as $$
  select p.id, p.display_name, date_part('year', age(p.birthdate))::int, p.city, p.bio, p.interests, p.photo_paths, p.verified, p.is_demo
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

drop function if exists public.search_profiles(int, int, text, text, boolean);
create function public.search_profiles(p_min int, p_max int, p_city text, p_interest text, p_verified boolean default false)
returns table (id uuid, display_name text, age int, city text, bio text, interests text[], photo_paths text[], liked boolean, verified boolean, is_demo boolean)
language sql security definer set search_path = public stable as $$
  select p.id, p.display_name, date_part('year', age(p.birthdate))::int, p.city, p.bio, p.interests, p.photo_paths,
         coalesce((select s.liked from swipes s where s.swiper_id = m.id and s.target_id = p.id), false), p.verified, p.is_demo
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

drop function if exists public.my_matches();
create function public.my_matches()
returns table (match_id uuid, other_id uuid, display_name text, photo_paths text[], created_at timestamptz, is_demo boolean)
language sql security definer set search_path = public stable as $$
  select m.id, o.id, o.display_name, o.photo_paths, m.created_at, o.is_demo
  from matches m
  join profiles o on o.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end
  where auth.uid() in (m.user_a, m.user_b) and not is_blocked(m.user_a, m.user_b)
  order by m.created_at desc
$$;

create or replace function public.swipe(p_target uuid, p_liked boolean) returns boolean
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
  if p_liked and (
       exists (select 1 from swipes where swiper_id = p_target and target_id = me and liked)
       or exists (select 1 from profiles where id = p_target and is_demo)) then
    insert into matches (user_a, user_b) values (least(me, p_target), greatest(me, p_target))
    on conflict do nothing;
    matched := true;
  end if;
  return matched;
end $$;

-- Réponse automatique d'un profil démo (une seule fois par conversation)
create or replace function public.demo_reply() returns trigger
language plpgsql security definer set search_path = public as $$
declare o uuid;
begin
  select case when user_a = new.sender_id then user_b else user_a end into o from matches where id = new.match_id;
  if o is not null and exists (select 1 from profiles where id = o and is_demo)
     and not exists (select 1 from messages where match_id = new.match_id and sender_id = o) then
    insert into messages (match_id, sender_id, body)
    values (new.match_id, o, 'Bonjour ! Je suis un profil de démonstration : je ne peux pas répondre, mais le reste du site est bien réel.');
  end if;
  return null;
end $$;

drop trigger if exists demo_reply on public.messages;
create trigger demo_reply after insert on public.messages
for each row execute function public.demo_reply();

revoke execute on function public.discover_profiles(int), public.search_profiles(int, int, text, text, boolean),
  public.my_matches(), public.demo_reply() from public, anon;
grant execute on function public.discover_profiles(int), public.search_profiles(int, int, text, text, boolean),
  public.my_matches() to authenticated;

-- ───────── Profils de démonstration (illustrations dans /demo/*.jpg, aucune vraie personne) ─────────
alter table public.profiles disable trigger profiles_guard;

create temporary table demo_seed (n int, name text, born date, gender text, city text, bio text, interests text[]);
insert into demo_seed values
 (1,  'Camille', '1996-04-12', 'femme', 'Paris',                 'Passionnée de montagne et de cinéma d''auteur.',        array['Randonnée','Cinéma']),
 (2,  'Thomas',  '1992-09-03', 'homme', 'Boulogne-Billancourt',  'Guitare le soir, cuisine le week-end.',                 array['Musique','Cuisine']),
 (3,  'Inès',    '1999-01-22', 'femme', 'Lyon',                  'Toujours un appareil photo dans le sac.',               array['Voyages','Photo']),
 (4,  'Julien',  '1989-06-30', 'homme', 'Paris',                 'Running le matin, séance ciné le dimanche.',            array['Sport','Cinéma']),
 (5,  'Léa',     '1994-11-15', 'femme', 'Marseille',             'À la recherche du meilleur restaurant du quartier.',    array['Voyages','Cuisine']),
 (6,  'Hugo',    '1986-03-08', 'homme', 'Lyon',                  'Week-ends en pleine nature et playlists soignées.',     array['Randonnée','Musique']),
 (7,  'Sarah',   '2000-07-19', 'femme', 'Paris',                 'Yoga, photo de rue et cafés crème.',                    array['Photo','Sport']),
 (8,  'Nathan',  '1983-12-02', 'homme', 'Boulogne-Billancourt',  'Un sac à dos, un billet d''avion, et c''est parti.',    array['Cuisine','Voyages']),
 (9,  'Manon',   '1993-05-27', 'femme', 'Lille',                 'Cinéphile et fan de concerts en plein air.',            array['Cinéma','Musique']),
 (10, 'Karim',   '1997-10-09', 'homme', 'Bordeaux',              'Escalade en salle, grands espaces en vacances.',        array['Sport','Randonnée']),
 (11, 'Chloé',   '1991-02-14', 'femme', 'Toulouse',              'Lectrice compulsive et cheffe du dimanche.',            array['Lecture','Cuisine']),
 (12, 'Maxime',  '1990-08-21', 'homme', 'Nantes',                'Vélo, vinyles et brunchs.',                             array['Musique','Sport']);

-- Comptes techniques sans mot de passe (connexion impossible)
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change, email_change_token_new)
select ('d0000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid, '00000000-0000-0000-0000-000000000000',
       'authenticated', 'authenticated', 'demo' || n || '@demo.invalid', '', now(),
       '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', ''
from demo_seed
on conflict (id) do nothing;

insert into public.profiles (id, display_name, birthdate, gender, looking_for, city, bio, interests, photo_paths, is_complete, is_demo)
select ('d0000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid, name, born, gender, 'tous', city, bio, interests,
       array['demo/' || n || '.jpg'], true, true
from demo_seed
on conflict (id) do nothing;

drop table demo_seed;
alter table public.profiles enable trigger profiles_guard;

commit;
