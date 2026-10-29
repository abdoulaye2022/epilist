// lib/consent.ts — le consentement, et ce qu'il commande.
//
// CE QUI SE PASSAIT AVANT. Google Analytics, le pixel Meta et Hotjar se
// chargeaient à la première visite, sans rien demander. Hotjar
// enregistre les sessions, et le seul formulaire du site est celui du
// contact — un message libre, qui peut contenir n'importe quoi. Pour un
// public canadien, la Loi 25 et la LPRPDE demandent un consentement
// préalable, et aucune bannière n'existait.
//
// LA RÈGLE, SIMPLE : rien ne se charge tant que la personne n'a pas
// choisi. Pas « rien ne se déclenche » — rien ne SE CHARGE. Un script
// tiers qui s'exécute a déjà lu l'adresse IP et posé ce qu'il voulait.
//
// Deux catégories, parce qu'elles ne servent pas à la même chose :
//
//   - `mesure` : combien de personnes viennent, par où elles arrivent.
//     C'est ce qui permet de savoir si une campagne a servi.
//   - `marketing` : le pixel publicitaire, qui sert à reconnaître la
//     personne ailleurs. Refusable séparément, et c'est le but.
//
// Le choix vit dans le navigateur de la personne, douze mois, et se
// change à tout moment par « Gérer les témoins » dans le pied de page.

export type CategorieConsentement = 'mesure' | 'marketing';

export interface Consentement {
  mesure: boolean;
  marketing: boolean;
  /** Date du choix, en ISO. Sert à le faire expirer. */
  decideLe: string;
  /** Version des catégories : si elles changent, on redemande. */
  version: number;
}

/** Monter ce nombre redemande son choix à tout le monde. */
export const VERSION_CONSENTEMENT = 1;

/** Douze mois : au-delà, on redemande plutôt que de supposer. */
export const VALIDITE_JOURS = 365;

const CLE = 'epilist-consentement';

/** Prévient les composants quand le choix change, sans recharger la page. */
export const EVENEMENT_CHANGEMENT = 'epilist:consentement';

/** Aucun consentement : c'est l'état de départ, et il refuse tout. */
export const REFUS_TOTAL: Consentement = {
  mesure: false,
  marketing: false,
  decideLe: '',
  version: VERSION_CONSENTEMENT,
};

/**
 * Le choix enregistré, ou null s'il n'y en a pas (ou plus).
 *
 * null veut dire « il faut demander ». Il ne veut jamais dire
 * « accepté » : c'est toute la différence entre un consentement et une
 * absence de refus.
 */
export function lireConsentement(): Consentement | null {
  if (typeof window === 'undefined') return null;

  try {
    const brut = window.localStorage.getItem(CLE);
    if (!brut) return null;

    const valeur = JSON.parse(brut) as Partial<Consentement>;

    if (valeur.version !== VERSION_CONSENTEMENT) return null;
    if (typeof valeur.mesure !== 'boolean') return null;
    if (typeof valeur.marketing !== 'boolean') return null;

    const decideLe = Date.parse(valeur.decideLe ?? '');
    if (Number.isNaN(decideLe)) return null;

    const ageJours = (Date.now() - decideLe) / 86_400_000;
    if (ageJours > VALIDITE_JOURS) return null;

    return {
      mesure: valeur.mesure,
      marketing: valeur.marketing,
      decideLe: valeur.decideLe!,
      version: VERSION_CONSENTEMENT,
    };
  } catch {
    // Stockage inaccessible (navigation privée, blocage) : on demandera
    // à nouveau, ce qui est le comportement sûr.
    return null;
  }
}

/** Enregistre le choix et prévient la page. */
export function enregistrerConsentement(choix: {
  mesure: boolean;
  marketing: boolean;
}): Consentement {
  const valeur: Consentement = {
    mesure: choix.mesure,
    marketing: choix.marketing,
    decideLe: new Date().toISOString(),
    version: VERSION_CONSENTEMENT,
  };

  try {
    window.localStorage.setItem(CLE, JSON.stringify(valeur));
  } catch {
    // Même sans stockage, le choix vaut pour la visite en cours.
  }

  appliquerAuConsentMode(valeur);
  window.dispatchEvent(
    new CustomEvent<Consentement>(EVENEMENT_CHANGEMENT, { detail: valeur })
  );

  return valeur;
}

/** Rouvre la bannière, depuis « Gérer les témoins ». */
export function redemanderLeChoix(): void {
  try {
    window.localStorage.removeItem(CLE);
  } catch {
    // sans importance : l'événement suffit à rouvrir la bannière
  }

  window.dispatchEvent(new CustomEvent(EVENEMENT_CHANGEMENT, { detail: null }));
}

/**
 * Le Consent Mode v2 de Google.
 *
 * À poser AVANT le chargement de gtag.js, avec tout en « denied » : le
 * script se charge alors sans rien écrire, et attend. Sans cet appel
 * préalable, GA considère le consentement accordé et pose ses cookies
 * dès la première image.
 */
export function scriptConsentModeParDefaut(): string {
  return `
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('consent', 'default', {
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied',
      functionality_storage: 'granted',
      security_storage: 'granted',
      wait_for_update: 500
    });
  `;
}

/** Transmet le choix à gtag, une fois qu'il est fait. */
export function appliquerAuConsentMode(choix: Consentement): void {
  if (typeof window === 'undefined') return;

  const gtag = (window as unknown as { gtag?: (...args: unknown[]) => void })
    .gtag;

  if (typeof gtag !== 'function') return;

  gtag('consent', 'update', {
    analytics_storage: choix.mesure ? 'granted' : 'denied',
    ad_storage: choix.marketing ? 'granted' : 'denied',
    ad_user_data: choix.marketing ? 'granted' : 'denied',
    ad_personalization: choix.marketing ? 'granted' : 'denied',
  });
}
