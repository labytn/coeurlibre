# Cœur Libre — site de rencontres (Vue 3 + Supabase) — web, PWA, Android, iOS

Aucune donnée de démo : la base démarre vide.

## 1. Base de données (Supabase, gratuit)
1. Créer un projet Supabase → SQL Editor → exécuter dans l'ordre `supabase/schema.sql`, `supabase/moderation.sql`, puis **`supabase/grants.sql`** (obligatoire sur les projets récents : sans lui, l'API répond « permission denied » et le site s'affiche sans données).
   Pour tester sans e-mail : Authentication → Sign In / Providers → Email → désactiver « Confirm email » (à réactiver une fois Brevo configuré).
2. **Profils de démonstration (optionnel)** : exécuter `supabase/demo.sql` (12 profils illustrés, tag « DÉMO » sur les photos ; liker une démo crée un match, elle répond une fois dans le chat). Pour tout retirer avant l'ouverture publique : `supabase/demo_remove.sql`.
3. **Premier administrateur** : s'inscrire dans l'app, puis dans le SQL Editor :
   `insert into admins select id from auth.users where email = 'votre-email';`

## 2. E-mails (indispensable : la limite par défaut est de 2 e-mails/heure)
1. Créer un compte **Brevo** (gratuit, 300 e-mails/jour) → *Senders* : ajouter et valider votre adresse expéditrice → *SMTP & API* : générer une clé SMTP.
2. Supabase → Authentication → SMTP Settings → activer le SMTP personnalisé :
   hôte `smtp-relay.brevo.com`, port `587`, utilisateur = identifiant SMTP Brevo, mot de passe = clé SMTP, e-mail expéditeur = l'adresse validée.
3. Supabase → Authentication → Rate Limits : relever la limite d'e-mails/heure (30 par défaut avec SMTP perso).
4. Supabase → Authentication → Email Templates : coller `supabase/email-templates/confirm-signup.html` (« Confirm signup ») et `reset-password.html` (« Reset password »). L'app utilise des **codes** (pas de liens) : ça fonctionne à l'identique sur le web et dans l'app mobile.
Pour une bonne délivrabilité, authentifiez un nom de domaine (SPF/DKIM) dans Brevo ; sans domaine, les e-mails risquent d'aller en spam.

## 3. Configuration
Éditer `public/config.js` (ou `config.js` à la racine du dossier déployé) : URL Supabase, clé anon, nom de l'éditeur, e-mail de contact (affichés dans CGU et confidentialité). L'application affiche un message tant qu'une valeur manque.

## 4. Web — Cloudflare Pages (upload direct)
- `npm install && npm run build` → dossier `dist/`.
- Cloudflare → Workers & Pages → Create → Pages → **Upload assets** → glisser le **dossier** `dist` (ou un .zip dont `index.html` est à la racine).
- Mise à jour : ré-uploader le dossier. Domaine fourni : `xxx.pages.dev`.
- **En ligne de commande** : `npm install` puis `npm run deploy` (compile et publie le Worker `coeur-libre` avec `wrangler.jsonc`).
- **Variante Git (build automatique Cloudflare)** : `wrangler.jsonc` est fourni (Worker `coeur-libre`, dossier `dist`, repli SPA pour que `/cgu` etc. fonctionnent au rafraîchissement). Réglages du projet : commande de build `npm run build`, commande de déploiement `npx wrangler deploy`, et les 4 variables `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_EDITOR_NAME`, `VITE_CONTACT_EMAIL` (ou laisser `public/config.js` rempli).

## 5. Mobile (Capacitor)
Les projets `android/` et `ios/` sont déjà générés (icônes, écran de démarrage, permission caméra inclus).
- Après toute modification : `npm run cap:sync`.
- Android : `npm run android` (Android Studio) → Build > Generate Signed Bundle (AAB) pour le Play Store, ou APK pour une installation directe.
- iOS : sur Mac, `npm run ios` (Xcode) → Product > Archive → App Store Connect.
- **Changer l'identifiant `appId` (`fr.coeurlibre.app`) dans `capacitor.config.ts` AVANT la première publication** (il est définitif), puis `npx cap sync`.
- Coûts : Google Play 25 $ une fois, Apple Developer 99 $/an. Gratuit : PWA (« Ajouter à l'écran d'accueil ») et APK en téléchargement direct.
- Dossiers stores : URL de politique de confidentialité = `https://VOTRE-SITE/privacy` ; classification 18+ ; fournir un compte de test aux relecteurs Apple/Google ; formulaire « Data safety » (Google) / « App Privacy » (Apple) : e-mail, photos, messages, données biométriques (selfie, facultatif).
- Déjà conformes aux exigences des stores pour les contenus générés par les utilisateurs : signalement, blocage, modération, suppression de compte dans l'app, CGU.

## 6. Modération et vérification
`/admin` : signalements (rejeter / suspendre / bannir), vérifications à examiner, réactivation. Vérification : selfie + geste aléatoire, comparaison faciale dans l'appareil (≤ 0,5 badge auto, ≤ 0,6 revue manuelle). Selfies supprimés après revue ou sous 30 jours.

## 7. Anti-pause Supabase gratuit
Workflow GitHub `.github/workflows/keepalive.yml` (secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY`).

## Limites gratuites Supabase
500 Mo de base, 1 Go de fichiers, pause après 7 jours d'inactivité.
