-- Cœur Libre — droits d'accès à l'API de données Supabase
-- OBLIGATOIRE sur les projets Supabase récents : les nouvelles tables du schéma « public »
-- ne sont plus accessibles à l'application tant qu'un GRANT explicite n'existe pas
-- (sans lui : « permission denied for table … » ou listes vides).
-- À exécuter APRÈS schema.sql et moderation.sql. Sans danger à relancer.
-- La sécurité des données reste assurée par les règles RLS déjà en place.

grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on public.profiles      to authenticated;
grant select                         on public.matches       to authenticated;
grant select, insert                 on public.messages      to authenticated;
grant select, insert, update, delete on public.blocks        to authenticated;
grant insert                         on public.reports       to authenticated;
grant select                         on public.verifications to authenticated;

grant usage, select on all sequences in schema public to authenticated;
