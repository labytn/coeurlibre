-- Cœur Libre — supprime tous les profils de démonstration et leurs données (matchs, messages, likes)
delete from auth.users where id in (select id from public.profiles where is_demo);
