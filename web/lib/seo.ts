// lib/seo.ts - Métadonnées bilingues centralisées : une table fr/en par
// page, un seul générateur. Garantit la parité de traduction du SEO,
// sans emoji ni chiffres invérifiables.
import type { Metadata } from 'next';
import { alternatesFor, href, BASE_URL, type Language, type RouteKey } from './routes';

interface PageSeo {
  title: string;
  description: string;
  keywords: string;
}

const seo: Record<RouteKey, Record<Language, PageSeo>> = {
  home: {
    fr: {
      title:
        'EpiList — Listes de courses partagées, budget et prix intelligents',
      description:
        "Listes de courses partagées en temps réel, suivi de budget, scanner de reçus, comparateur de prix entre magasins et suggestions selon vos habitudes. Gratuit, sans publicité, hors ligne, iOS et Android.",
      keywords:
        'liste de courses, application courses famille, liste partagée, budget épicerie, scanner de reçus, comparateur de prix épicerie, application courses gratuite, courses hors ligne, EpiList Canada',
    },
    en: {
      title: 'EpiList — Shared grocery lists, smart budget and prices',
      description:
        'Real-time shared grocery lists, budget tracking, receipt scanner, store price comparison and suggestions based on your habits. Free, ad-free, offline-ready, iOS and Android.',
      keywords:
        'grocery list app, shared shopping list, family groceries, grocery budget, receipt scanner, grocery price comparison, free shopping list app, offline grocery list, EpiList Canada',
    },
  },
  features: {
    fr: {
      title: 'Fonctionnalités — EpiList',
      description:
        "Tout EpiList : listes partagées et synchronisées, scanner de reçus, historique et comparateur de prix, suggestions prédictives, inventaire maison, mode magasin trié par rayon, budgets et analyses, 150+ devises, hors ligne.",
      keywords:
        'fonctionnalités EpiList, synchronisation liste courses, scanner reçu épicerie, comparateur prix magasins, suggestions courses, inventaire maison, tri par rayon, budget courses',
    },
    en: {
      title: 'Features — EpiList',
      description:
        'Everything in EpiList: shared synced lists, receipt scanner, price history and store comparison, predictive suggestions, home inventory, in-store mode sorted by aisle, budgets and analytics, 150+ currencies, offline.',
      keywords:
        'EpiList features, shopping list sync, grocery receipt scanner, store price comparison, shopping suggestions, home inventory, aisle sorting, grocery budget',
    },
  },
  download: {
    fr: {
      title: "Télécharger l'application — EpiList",
      description:
        "Téléchargez EpiList gratuitement sur iOS (App Store) et Android (Google Play). Installation en moins d'une minute, aucune publicité, fonctionne hors ligne.",
      keywords:
        'télécharger EpiList, application courses iOS, application courses Android, App Store, Google Play, liste de courses gratuite',
    },
    en: {
      title: 'Download the app — EpiList',
      description:
        'Download EpiList for free on iOS (App Store) and Android (Google Play). Installed in under a minute, no ads, works offline.',
      keywords:
        'download EpiList, grocery app iOS, grocery app Android, App Store, Google Play, free shopping list',
    },
  },
  help: {
    fr: {
      title: 'Aide et questions fréquentes — EpiList',
      description:
        "Réponses aux questions fréquentes sur EpiList : partage de listes, synchronisation, budgets, scanner de reçus, mode hors ligne et gestion du compte.",
      keywords:
        'aide EpiList, FAQ EpiList, support application courses, partage de liste, synchronisation, compte EpiList',
    },
    en: {
      title: 'Help and FAQ — EpiList',
      description:
        'Answers to frequently asked questions about EpiList: list sharing, sync, budgets, receipt scanner, offline mode and account management.',
      keywords:
        'EpiList help, EpiList FAQ, grocery app support, list sharing, sync, EpiList account',
    },
  },
  contact: {
    fr: {
      title: 'Contact — EpiList',
      description:
        "Contactez l'équipe EpiList : question, suggestion ou problème technique. Nous répondons rapidement, en français ou en anglais.",
      keywords: 'contact EpiList, support EpiList, aide application courses',
    },
    en: {
      title: 'Contact — EpiList',
      description:
        'Get in touch with the EpiList team: questions, suggestions or technical issues. We reply quickly, in French or English.',
      keywords: 'contact EpiList, EpiList support, grocery app help',
    },
  },
  about: {
    fr: {
      title: 'À propos — EpiList',
      description:
        "EpiList est développée au Nouveau-Brunswick, Canada, par M2atech Solutions Inc. Notre mission : simplifier les courses des familles et les aider à maîtriser leur budget.",
      keywords:
        'à propos EpiList, M2atech Solutions, application canadienne, Nouveau-Brunswick',
    },
    en: {
      title: 'About — EpiList',
      description:
        'EpiList is built in New Brunswick, Canada, by M2atech Solutions Inc. Our mission: make family groceries simpler and budgets easier to control.',
      keywords:
        'about EpiList, M2atech Solutions, Canadian app, New Brunswick',
    },
  },
  privacy: {
    fr: {
      title: 'Politique de confidentialité — EpiList',
      description:
        "Comment EpiList collecte, utilise et protège vos données : listes, budgets, reçus et informations de compte. Vos données ne sont jamais vendues.",
      keywords: 'politique de confidentialité EpiList, données personnelles, vie privée',
    },
    en: {
      title: 'Privacy policy — EpiList',
      description:
        'How EpiList collects, uses and protects your data: lists, budgets, receipts and account information. Your data is never sold.',
      keywords: 'EpiList privacy policy, personal data, privacy',
    },
  },
  terms: {
    fr: {
      title: "Conditions d'utilisation — EpiList",
      description:
        "Les conditions d'utilisation du service EpiList : compte, contenu, responsabilités et résiliation.",
      keywords: "conditions d'utilisation EpiList, CGU, termes du service",
    },
    en: {
      title: 'Terms of use — EpiList',
      description:
        'The terms of use of the EpiList service: account, content, responsibilities and termination.',
      keywords: 'EpiList terms of use, terms of service',
    },
  },
  comparison: {
    fr: {
      title: 'Comparaison des applications de courses — EpiList',
      description:
        "EpiList face aux autres applications de listes de courses : partage, budget, prix, hors ligne, devises et gratuité comparés point par point.",
      keywords:
        'comparaison applications courses, alternative AnyList, alternative Bring, meilleure application liste de courses',
    },
    en: {
      title: 'Grocery app comparison — EpiList',
      description:
        'EpiList versus other grocery list apps: sharing, budget, prices, offline mode, currencies and pricing compared point by point.',
      keywords:
        'grocery app comparison, AnyList alternative, Bring alternative, best grocery list app',
    },
  },
};

/** Métadonnées complètes d'une page (titre, description, OG, hreflang). */
export function pageMetadata(key: RouteKey, lang: Language): Metadata {
  const s = seo[key][lang];
  const url = `${BASE_URL}${href(key, lang)}`;
  return {
    title: s.title,
    description: s.description,
    keywords: s.keywords,
    alternates: alternatesFor(key, lang),
    openGraph: {
      title: s.title,
      description: s.description,
      url,
      siteName: 'EpiList',
      locale: lang === 'fr' ? 'fr_CA' : 'en_CA',
      alternateLocale: lang === 'fr' ? 'en_CA' : 'fr_CA',
      type: 'website',
      images: [
        {
          url: '/images/og-image-main.jpg',
          width: 1200,
          height: 630,
          alt: 'EpiList',
        },
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: s.title,
      description: s.description,
    },
  };
}
