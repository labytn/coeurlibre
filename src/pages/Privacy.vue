<script setup lang="ts">
import { cfg } from '../lib/config'
const editor = cfg('EDITOR_NAME')
const mail = cfg('CONTACT_EMAIL')
</script>

<template>
  <article class="space-y-4 text-sm leading-relaxed [&_h2]:mt-4 [&_h2]:text-base [&_h2]:font-bold [&_ul]:list-disc [&_ul]:pl-5">
    <h1 class="text-xl font-bold">Politique de confidentialité</h1>
    <p class="text-zinc-500">Dernière mise à jour : 3 octobre 2026</p>

    <h2>1. Responsable du traitement</h2>
    <p>{{ editor }} (contact : {{ mail }}) est responsable du traitement des données personnelles collectées via « Cœur Libre » (site web et application mobile).</p>

    <h2>2. Données collectées et finalités</h2>
    <ul>
      <li><b>Compte</b> : adresse e-mail, mot de passe (stocké chiffré, jamais lisible). Finalité : authentification. Base légale : exécution du contrat.</li>
      <li><b>Profil</b> : prénom, date de naissance, genre, genre recherché, ville, présentation, centres d'intérêt, photos. Finalité : fournir le service de rencontres. Base légale : exécution du contrat. Ces données sont visibles des autres membres (sauf l'e-mail et la date de naissance exacte : seul l'âge est affiché).</li>
      <li><b>Interactions</b> : likes, passes, matchs, messages, blocages. Finalité : fonctionnement du service. Base légale : exécution du contrat.</li>
      <li><b>Sécurité et modération</b> : signalements, sanctions, journal des vérifications. Finalité : protéger les membres, lutter contre la fraude. Base légale : intérêt légitime.</li>
      <li><b>Vérification de profil (donnée biométrique)</b> : selfie et score de similitude faciale. Finalité : attribuer le badge « Vérifié ». Base légale : consentement explicite, retirable à tout moment, facultatif. La comparaison est calculée sur votre appareil ; le selfie est conservé jusqu'à son examen par un modérateur, et au plus 30 jours. Aucune empreinte faciale n'est conservée.</li>
    </ul>

    <h2>3. Destinataires et sous-traitants</h2>
    <p>Vos données ne sont ni vendues, ni utilisées à des fins publicitaires. Elles sont traitées par nos sous-traitants techniques : Supabase (base de données, authentification, stockage), Cloudflare (hébergement du site) et un prestataire d'envoi d'e-mails transactionnels (codes de confirmation). Ces prestataires peuvent traiter des données hors de l'Union européenne, avec les garanties prévues par le RGPD (clauses contractuelles types).</p>

    <h2>4. Durées de conservation</h2>
    <ul>
      <li>Compte, profil, messages et photos : jusqu'à la suppression du compte, effective immédiatement depuis la page Profil.</li>
      <li>Selfies de vérification : 30 jours maximum.</li>
      <li>Signalements : le temps nécessaire à la sécurité du service.</li>
    </ul>

    <h2>5. Vos droits</h2>
    <p>Vous disposez des droits d'accès, de rectification, d'effacement, d'opposition, de limitation et de portabilité. Vous pouvez supprimer votre compte et vos données depuis la page Profil, ou écrire à {{ mail }}. Vous pouvez aussi introduire une réclamation auprès de la CNIL (cnil.fr).</p>

    <h2>6. Cookies et stockage local</h2>
    <p>Le service n'utilise aucun cookie publicitaire ni outil de mesure d'audience. Un stockage local technique conserve votre session de connexion.</p>

    <h2>7. Permissions de l'application mobile</h2>
    <p>La caméra n'est utilisée que pour la vérification de profil par selfie, uniquement lorsque vous la lancez. L'accès à vos photos n'a lieu que lorsque vous choisissez d'en ajouter à votre profil.</p>

    <h2>8. Mineurs et sécurité</h2>
    <p>Le service est interdit aux moins de 18 ans. Les données sont protégées par chiffrement des échanges (HTTPS), contrôle d'accès strict par compte et stockage privé des photos.</p>

    <h2>9. Modifications</h2>
    <p>Cette politique peut évoluer ; la date de mise à jour figure en tête de page.</p>
  </article>
</template>
