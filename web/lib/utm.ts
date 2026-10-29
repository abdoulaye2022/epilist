// lib/utm.ts — d'où vient la visite, et comment elle survit au magasin.
//
// LE PROBLÈME. Une campagne amène quelqu'un sur epilist.app avec un
// `?utm_source=...` dans l'URL. Il lit, il clique sur Google Play, il
// installe. À ce moment précis, tout est perdu : la campagne ne saura
// jamais qu'elle a produit cette installation, et encore moins ce que
// la personne a fait ensuite.
//
// CE QUE FAIT CE FICHIER. Il lit les paramètres UTM à l'arrivée, les
// garde LE TEMPS DE LA SESSION (`sessionStorage`, pas `localStorage` :
// une campagne n'a pas à suivre quelqu'un pendant des mois), et les
// recolle dans le paramètre `referrer` du lien Google Play — le seul
// canal que Google transmet à l'application au premier lancement.
//
// Côté iOS, il n'existe aucun équivalent : l'App Store ne transmet
// rien. C'est une limite de la plateforme, pas un oubli.
//
// Rien ici n'écrit de cookie et rien ne part vers un tiers : les UTM ne
// sont envoyés à Google Analytics que si la mesure a été acceptée,
// parce que `gtag` lui-même n'existe pas avant.

const CLE = 'epilist-utm';

export interface Utm {
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
}

/** Les seuls paramètres retenus. Le reste de l'URL est ignoré. */
const CHAMPS = ['utm_source', 'utm_medium', 'utm_campaign'] as const;

/**
 * Lit les UTM de l'URL courante et les garde pour la session.
 *
 * Les valeurs sont bornées : une campagne s'appelle « automne-2026 »,
 * pas 4 Ko de texte. Ce qui dépasse est coupé — ces chaînes finissent
 * dans une URL de magasin et dans un outil de mesure.
 */
export function capturerUtm(recherche: string): Utm {
  const params = new URLSearchParams(recherche);
  const trouve: Utm = {};

  for (const champ of CHAMPS) {
    const valeur = params.get(champ);

    if (valeur) {
      trouve[champ] = valeur.slice(0, 100).replace(/[^\w.\-+% ]/g, '');
    }
  }

  if (Object.keys(trouve).length === 0) {
    return lireUtm();
  }

  try {
    window.sessionStorage.setItem(CLE, JSON.stringify(trouve));
  } catch {
    // Navigation privée ou stockage bloqué : la campagne ne sera pas
    // suivie, et c'est tout. Rien ne casse.
  }

  return trouve;
}

/** Les UTM de la session, s'il y en a. */
export function lireUtm(): Utm {
  if (typeof window === 'undefined') return {};

  try {
    const brut = window.sessionStorage.getItem(CLE);
    return brut ? (JSON.parse(brut) as Utm) : {};
  } catch {
    return {};
  }
}

/**
 * Le lien Google Play, avec le jeton de partage ET la campagne.
 *
 * Google rend ce `referrer` à l'application au premier lancement.
 * C'est le seul fil qui relie « quelqu'un a cliqué sur cette publicité »
 * à « quelqu'un a créé un compte », et il ne tient qu'à cette chaîne.
 */
export function lienPlay(base: string, options?: { shareToken?: string }): string {
  const utm = lireUtm();
  const morceaux: string[] = [];

  if (options?.shareToken) {
    morceaux.push(`share_token=${options.shareToken}`);
  }

  // utm_source par défaut : sans lui, une installation venue du site
  // apparaît comme « organique » et la page d'où elle vient disparaît.
  morceaux.push(`utm_source=${utm.utm_source ?? 'epilist_site'}`);

  if (utm.utm_medium) morceaux.push(`utm_medium=${utm.utm_medium}`);
  if (utm.utm_campaign) morceaux.push(`utm_campaign=${utm.utm_campaign}`);

  const separateur = base.includes('?') ? '&' : '?';

  return `${base}${separateur}referrer=${encodeURIComponent(morceaux.join('&'))}`;
}
