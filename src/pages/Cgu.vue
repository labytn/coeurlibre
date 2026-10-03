<script setup lang="ts">
const editor = import.meta.env.VITE_EDITOR_NAME as string
const mail = import.meta.env.VITE_CONTACT_EMAIL as string
</script>

<template>
  <article class="space-y-4 text-sm leading-relaxed [&_h2]:mt-4 [&_h2]:text-base [&_h2]:font-bold [&_ul]:list-disc [&_ul]:pl-5">
    <h1 class="text-xl font-bold">Conditions générales d'utilisation</h1>
    <p class="text-zinc-500">Dernière mise à jour : 3 octobre 2026</p>

    <h2>1. Objet et éditeur</h2>
    <p>Les présentes conditions régissent l'usage de « Cœur Libre », service gratuit de mise en relation entre adultes, édité par {{ editor }} (contact : {{ mail }}). Le service est hébergé par Cloudflare (site) et Supabase (données). Utiliser le service implique l'acceptation pleine et entière des présentes.</p>

    <h2>2. Accès et inscription</h2>
    <ul>
      <li>Le service est strictement réservé aux personnes de 18 ans révolus. Toute inscription d'un mineur est interdite et le compte sera supprimé.</li>
      <li>Vous fournissez des informations exactes (prénom, date de naissance, genre, ville, photos vous représentant réellement) et les tenez à jour.</li>
      <li>Un seul compte par personne. Vos identifiants sont personnels ; vous êtes responsable de leur confidentialité et de l'activité du compte.</li>
    </ul>

    <h2>3. Règles de conduite</h2>
    <p>Il est interdit de :</p>
    <ul>
      <li>usurper l'identité d'autrui, utiliser des photos qui ne sont pas les vôtres ou créer un faux profil ;</li>
      <li>harceler, menacer, insulter, discriminer ou tenir des propos haineux, violents ou à caractère pornographique ;</li>
      <li>publier des contenus illégaux, ou des images de personnes tierces ou de mineurs ;</li>
      <li>solliciter de l'argent, faire de la prospection commerciale, du démarchage, de l'escroquerie (notamment « arnaque aux sentiments ») ou promouvoir des services sexuels tarifés ;</li>
      <li>collecter les données d'autres membres, utiliser des robots ou perturber le fonctionnement du service.</li>
    </ul>

    <h2>4. Vérification de profil</h2>
    <p>Vous pouvez faire vérifier votre profil par un selfie en direct comparé automatiquement à vos photos (badge « Vérifié »). Cette opération repose sur un traitement de données biométriques (reconnaissance faciale), effectué uniquement avec votre consentement explicite, que vous pouvez refuser sans perdre l'accès au service. Le calcul de similitude est réalisé dans votre navigateur ; seul le résultat chiffré de similitude et le selfie sont transmis. Les cas incertains sont examinés par un modérateur. Le selfie est supprimé après examen manuel, ou au plus tard 30 jours après la vérification. Le badge est retiré si vous modifiez vos photos ou en cas de manquement aux règles.</p>

    <h2>5. Signalement et modération</h2>
    <p>Chaque membre peut signaler et bloquer un profil ou une conversation. Les modérateurs examinent les signalements et peuvent, selon la gravité, rejeter le signalement, suspendre ou bannir un compte, sans préavis en cas de manquement grave. Un compte suspendu ou banni devient invisible et ne peut plus échanger. Vous pouvez contester une décision en écrivant à {{ mail }}.</p>

    <h2>6. Contenus et licence</h2>
    <p>Vous restez propriétaire de vos contenus (photos, textes, messages). Vous accordez au service une licence non exclusive, gratuite et limitée à l'exploitation du service (affichage à d'autres membres, hébergement). Vous garantissez détenir les droits nécessaires sur ces contenus.</p>

    <h2>7. Données personnelles</h2>
    <p>Les données collectées (e-mail, profil, photos, messages, interactions, signalements) servent à fournir le service, assurer la sécurité et la modération. Les photos et le profil sont visibles des autres membres ; l'e-mail et la date de naissance exacte ne le sont pas. Conformément au RGPD, vous disposez des droits d'accès, de rectification, d'effacement, d'opposition, de limitation et de portabilité : la suppression du compte est immédiate depuis la page Profil, et toute demande peut être adressée à {{ mail }}. Vous pouvez saisir la CNIL (cnil.fr). Les données sont supprimées à la clôture du compte ; les signalements peuvent être conservés le temps nécessaire à la sécurité du service.</p>

    <h2>8. Sécurité et prudence</h2>
    <p>Le service ne vérifie pas l'intégralité des profils et ne garantit ni l'identité, ni les intentions des membres. Soyez prudent : ne communiquez jamais d'argent, de coordonnées bancaires ou de documents d'identité, et donnez un premier rendez-vous dans un lieu public.</p>

    <h2>9. Responsabilité et disponibilité</h2>
    <p>Le service est fourni gratuitement « en l'état », sans garantie de disponibilité continue ; il peut être interrompu pour maintenance ou évolution. L'éditeur n'est pas responsable des échanges ni des rencontres entre membres, ni des contenus publiés par ceux-ci, sous réserve de ses obligations légales de retrait des contenus manifestement illicites signalés.</p>

    <h2>10. Résiliation</h2>
    <p>Vous pouvez supprimer votre compte à tout moment depuis la page Profil. L'éditeur peut suspendre ou clore un compte en cas de manquement aux présentes.</p>

    <h2>11. Modification et droit applicable</h2>
    <p>Les CGU peuvent évoluer ; la date de mise à jour figure en tête de page et la poursuite de l'usage vaut acceptation. Elles sont soumises au droit français. En cas de litige, et à défaut de solution amiable, les tribunaux français sont compétents.</p>
  </article>
</template>
