import type { Metadata } from "next";
import PageContent from "@/components/PageContent";

// Metadata spécifique à la page d'accueil
export const metadata: Metadata = {
  title:
    "EpiList - App de Liste de Courses Familiale | Sync Temps Réel, Multi-Devises, Mode Hors Ligne",
  description:
    "🛒 EpiList révolutionne vos courses ! Listes partagées, synchronisation temps réel, 150+ devises, mode hors ligne avancé, catégories personnalisables, reçus photo, notifications instantanées. 200+ utilisateurs actifs, 4.9⭐, 100% gratuit sur iOS & Android !",
  keywords:
    "liste de courses gratuite, application courses famille, synchronisation temps réel, multi-devises, courses hors ligne, catégories personnalisables, reçus photo, SSO Google Apple, notifications temps réel, analytiques visuelles, organisateur familial, EpiList Canada",

  openGraph: {
    title: "🛒 EpiList - L'App de Courses Familiale #1 | Gratuite & Sans Pub",
    description:
      "Simplifiez vos courses avec listes partagées, sync temps réel, 150+ devises, mode hors ligne avancé, catégories personnalisables, reçus photo. Rejoignez 200+ utilisateurs actifs satisfaits !",
    url: "https://epilist.app",
    images: [
      {
        url: "/images/og-home.jpg",
        width: 1200,
        height: 630,
        alt: "EpiList - Écran principal de l'application de courses familiale",
      },
    ],
  },

  twitter: {
    title: "🛒 EpiList - App Courses Familiale Gratuite",
    description:
      "Listes partagées • Sync temps réel • 150+ devises • Mode hors ligne avancé • Reçus photo • Catégories personnalisables • 4.9⭐ • 0$ à vie",
  },

  alternates: {
    canonical: "https://epilist.app",
  },
};

export default function Home() {
  return (
    <main id="main-content">
      <PageContent />
    </main>
  );
}
