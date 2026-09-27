// lib/routes.ts - Carte des URL bilingues.
// Le français garde ses slugs historiques (SEO conservé) ; l'anglais vit
// sous /en/... . L'URL est LA source de vérité de la langue.

export type Language = 'fr' | 'en';

export type RouteKey =
  | 'home'
  | 'features'
  | 'download'
  | 'help'
  | 'contact'
  | 'about'
  | 'privacy'
  | 'terms'
  | 'comparison';

export const routes: Record<RouteKey, { fr: string; en: string }> = {
  home: { fr: '/', en: '/en' },
  features: { fr: '/fonctionnalites', en: '/en/features' },
  download: { fr: '/telecharger', en: '/en/download' },
  help: { fr: '/aide', en: '/en/help' },
  contact: { fr: '/contact', en: '/en/contact' },
  about: { fr: '/a-propos', en: '/en/about' },
  privacy: { fr: '/politique-confidentialite', en: '/en/privacy-policy' },
  terms: { fr: '/conditions-utilisation', en: '/en/terms-of-use' },
  comparison: {
    fr: '/comparaison-applications-courses',
    en: '/en/grocery-app-comparison',
  },
};

export const BASE_URL = 'https://epilist.app';

/** Langue portée par le chemin : /en et /en/... = anglais, sinon français. */
export function languageFromPath(pathname: string): Language {
  return pathname === '/en' || pathname.startsWith('/en/') ? 'en' : 'fr';
}

/** Chemin d'une page dans la langue demandée. */
export function href(key: RouteKey, lang: Language): string {
  return routes[key][lang];
}

/** Chemin équivalent dans l'autre langue (ou l'accueil si inconnu). */
export function counterpartPath(pathname: string, target: Language): string {
  const clean = pathname.replace(/\/$/, '') || '/';
  for (const key of Object.keys(routes) as RouteKey[]) {
    const r = routes[key];
    if (r.fr === clean || r.en === clean) {
      return r[target];
    }
  }
  return target === 'en' ? '/en' : '/';
}

/** Bloc `alternates` (canonical + hreflang) pour les metadata Next. */
export function alternatesFor(key: RouteKey, lang: Language) {
  return {
    canonical: `${BASE_URL}${routes[key][lang]}`,
    languages: {
      'fr-CA': `${BASE_URL}${routes[key].fr}`,
      'en-CA': `${BASE_URL}${routes[key].en}`,
      'x-default': `${BASE_URL}${routes[key].fr}`,
    },
  };
}
