// Les donnees structurees envoyees a Google.
//
// Ce fichier portait un aggregateRating : note 4.9 sur 1247 avis, deux
// nombres ecrits a la main que rien ne soutient. Google les lisait et
// pouvait les afficher comme des avis verifies : c'est exactement ce que
// ses regles sur les faux avis interdisent. Ils sont partis. Un
// SoftwareApplication sans note reste parfaitement valide.
export interface AppSchema {
  "@context": string
  "@type": string
  name: string
  applicationCategory: string
  operatingSystem: string[]
  offers: {
    "@type": string
    price: string
    priceCurrency: string
  }
  downloadUrl: string[]
  description: string
  author: {
    "@type": string
    name: string
  }
  screenshots: string[]
  featureList: string[]
}

// Schema pour EpiList
export const epilistAppSchema: AppSchema = {
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  name: "EpiList - Simplifiez vos courses",
  applicationCategory: "LifestyleApplication",
  operatingSystem: ["iOS", "Android"],
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "CAD"
  },
  downloadUrl: [
    "https://apps.apple.com/ca/app/epilist/id6748285596",
    "https://play.google.com/store/apps/details?id=com.m2atech.epilist"
  ],
  description: "L'application mobile de listes de courses partagées : créez vos listes, partagez-les avec votre foyer, suivez votre budget et lisez vos reçus. Gratuite, sans publicité, et utilisable hors ligne.",
  author: {
    "@type": "Organization",
    name: "M2atech Solutions Inc."
  },
  // Les trois ecrans de la section « L'application, telle qu'elle est »,
  // rendus en image. Les trois adresses d'avant pointaient sur une
  // capture de deux refontes (dash.png) et sur deux fichiers qui
  // n'existent pas : Google les lisait, et ne trouvait rien.
  screenshots: [
    "https://epilist.app/images/ecran-accueil.jpg",
    "https://epilist.app/images/ecran-a-la-maison.jpg",
    "https://epilist.app/images/ecran-au-magasin.jpg"
  ],
  featureList: [
    "Listes partagées avec le foyer, avec droits par personne",
    "Notifications instantanées lors des changements",
    "Mode hors ligne",
    "Lecture des reçus sur l'appareil",
    "Budgets et alertes de dépassement",
    "Comparaison des prix entre magasins",
    "Bilingue français et anglais",
    "Gratuite, sans publicité"
  ]
}

// Schema FAQ
export const epilistFAQSchema = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: [
    {
      "@type": "Question",
      name: "EpiList est-elle vraiment gratuite ?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Oui, EpiList est 100% gratuite à vie. Aucun frais caché, aucun abonnement, aucune publicité. Nous croyons que l'organisation familiale devrait être accessible à tous."
      }
    },
    {
      "@type": "Question", 
      name: "Comment synchroniser mes listes avec ma famille ?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Créez votre liste et partagez-la avec les membres de votre foyer par lien ou par invitation. Chacun retrouve la liste sur son appareil, et reçoit une notification instantanée quand un article change."
      }
    },
    {
      "@type": "Question",
      name: "L'application fonctionne-t-elle hors ligne ?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Absolument ! EpiList fonctionne parfaitement hors ligne. Vos listes sont stockées localement et se synchronisent automatiquement dès que vous retrouvez une connexion."
      }
    },
    {
      "@type": "Question",
      name: "Sur quelles plateformes EpiList est-elle disponible ?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "EpiList est disponible sur iOS (App Store) et sur Android (Google Play)."
      }
    }
  ]
}

// L'editeur. « EpiList Inc. » n'existe pas : la societe est M2atech
// Solutions Inc., au Nouveau-Brunswick.
export const epilistBusinessSchema = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "EpiList",
  url: "https://epilist.app",
  sameAs: [
    "https://apps.apple.com/ca/app/epilist/id6748285596",
    "https://play.google.com/store/apps/details?id=com.m2atech.epilist"
  ],
  applicationCategory: "Business",
  operatingSystem: "iOS, Android",
  provider: {
    "@type": "Organization",
    name: "M2atech Solutions Inc.",
    location: {
      "@type": "Place",
      addressLocality: "Nouveau-Brunswick",
      addressCountry: "CA"
    }
  }
}