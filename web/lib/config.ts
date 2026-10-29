// lib/config.ts — les affirmations qui attendent une vérification.
//
// Une phrase de site qu'on ne peut pas prouver ne doit pas s'afficher
// « en attendant ». Elle vit ici derrière un interrupteur, à faux par
// défaut : le texte existe, il est traduit, il est prêt — et il reste
// invisible jusqu'à ce que le fait soit établi.

/**
 * « Nos serveurs et le stockage des images sont situés au Canada. »
 *
 * À vérifier AVANT de l'activer : la région du bucket d'images n'est pas
 * fixée par le code, et un bucket ne se déplace pas. Le script
 * `api/scripts/make_receipts_private.php` affiche la région réelle et la
 * compare à celle attendue ; la console d'hébergement la donne aussi.
 *
 * Pour activer : NEXT_PUBLIC_DATA_RESIDENCY_CANADA_CONFIRMED=true dans
 * l'environnement de déploiement, puis reconstruire le site.
 */
export const DATA_RESIDENCY_CANADA_CONFIRMED =
  process.env.NEXT_PUBLIC_DATA_RESIDENCY_CANADA_CONFIRMED === 'true';

/**
 * La section Témoignages.
 *
 * Elle affichait cinq témoignages écrits de toutes pièces : cinq noms
 * génériques sur cinq villes du Nouveau-Brunswick, un par segment
 * démographique, dont un qui annonçait « 200 $ d'économies par mois ».
 * Ils sont partis.
 *
 * La structure reste, vide, prête pour de vrais retours : voir
 * `components/TestimonialsSection.tsx` pour la forme attendue et la
 * règle de consentement. Tant que la liste est vide, la section ne
 * s'affiche pas, même si cet interrupteur passe à vrai.
 */
export const TESTIMONIALS_ENABLED =
  process.env.NEXT_PUBLIC_TESTIMONIALS_ENABLED === 'true';
