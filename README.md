# Cœur Libre — site de rencontres (Vue 3 + Supabase + Cloudflare Pages)

Aucune donnée de démo : la base démarre vide.

## Mise en production (100 % gratuit)
1. **Supabase** : créer un projet gratuit → SQL Editor → exécuter, dans l'ordre, `supabase/schema.sql` puis `supabase/moderation.sql`.
2. Supabase > Authentication > URL Configuration : renseigner *Site URL* et *Redirect URLs* (votre URL `*.pages.dev`).
3. Copier `.env.example` en `.env` et renseigner les 4 variables (URL, clé anon, nom de l'éditeur, e-mail de contact : affichés dans les CGU). Le build échoue si l'une manque.
4. Local : `npm install && npm run dev`.
5. **Cloudflare Pages** : connecter le dépôt → build `npm run build`, sortie `dist`, les 4 variables d'environnement. Domaine fourni : `xxx.pages.dev`.
6. GitHub : secrets `SUPABASE_URL` et `SUPABASE_ANON_KEY` (workflow anti-pause).
7. **Premier administrateur** : s'inscrire sur le site, puis dans le SQL Editor :
   `insert into admins select id from auth.users where email = 'votre-email';`
   L'onglet « Modération » apparaît alors.

## Modération (`/admin`)
- **Signalements** : rejeter, suspendre ou bannir (un compte sanctionné devient invisible et ne peut plus écrire). Sanctionner clôt tous ses signalements ouverts.
- **Vérifs** : cas incertains à approuver/refuser + contrôle par sondage des auto-validations.
- **Sanctions** : réactiver un compte.

## Vérification de profil
Selfie en direct + geste aléatoire (sourire / tourner la tête), comparaison faciale dans le navigateur (face-api, modèles inclus dans `public/models`, aucun CDN). Distance ≤ 0,5 : badge automatique ; ≤ 0,6 : revue manuelle ; sinon refus. 3 essais / 24 h. Le badge tombe si les photos changent. Selfies supprimés après revue ou sous 30 jours (purge à l'ouverture de `/admin`).
Limite : le calcul étant côté navigateur, un attaquant technique peut forger un score — d'où le contrôle par sondage des auto-validations.

## Limites gratuites
500 Mo de base, 1 Go de fichiers, pause après 7 jours d'inactivité (workflow fourni). E-mail Supabase par défaut très limité : configurer un SMTP (Resend/Brevo).
