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
  aggregateRating: {
    "@type": string
    ratingValue: string
    ratingCount: string
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
  aggregateRating: {
    "@type": "AggregateRating",
    ratingValue: "4.9",
    ratingCount: "1247"
  },
  downloadUrl: [
    "https://apps.apple.com/ca/app/epilist/id6748285596?l=fr-CA",
    "https://play.google.com/store/apps/details?id=com.m2atech.epilist"
  ],
  description: "L'application mobile qui révolutionne votre façon de faire les courses. Créez, partagez et gérez vos listes en famille avec synchronisation temps réel.",
  author: {
    "@type": "Organization",
    name: "EpiList Team"
  },
  screenshots: [
    "https://epilist.app/dash.png",
    "https://epilist.app/images/app-screenshot-1.jpg",
    "https://epilist.app/images/app-screenshot-2.jpg"
  ],
  featureList: [
    "Synchronisation familiale temps réel",
    "Mode hors ligne disponible",
    "Suggestions intelligentes d'achats",
    "Interface intuitive et moderne",
    "Sécurité des données garantie",
    "Gratuit à vie, sans publicité"
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
        text: "Créez simplement votre liste et partagez-la avec les membres de votre famille via un code unique. Tous les changements sont synchronisés en temps réel sur tous les appareils."
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
        text: "EpiList est disponible sur iOS (App Store) et Android (Google Play). Une version web est également accessible depuis n'importe quel navigateur."
      }
    }
  ]
}

// Schema LocalBusiness (si vous avez une entreprise au Nouveau-Brunswick)
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
  operatingSystem: "iOS, Android, Web",
  provider: {
    "@type": "Organization",
    name: "EpiList Inc.",
    location: {
      "@type": "Place",
      addressLocality: "Nouveau-Brunswick",
      addressCountry: "CA"
    }
  }
}