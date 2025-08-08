import type { Metadata } from "next";
import PageContent from "@/components/PageContent";

// Metadata spécifique à la page d'accueil
export const metadata: Metadata = {
  title:
    "EpiList - App de Liste de Courses Familiale | Sync Temps Réel, Mode Hors Ligne",
  description:
    "🛒 EpiList révolutionne vos courses ! Créez des listes partagées avec votre famille, synchronisation instantanée, mode hors ligne. 50k+ utilisateurs, 4.9⭐, 100% gratuit. Téléchargez maintenant sur iOS & Android !",
  keywords:
    "liste de courses gratuite, application courses famille, synchronisation temps réel, courses hors ligne, organisateur familial, EpiList Canada",

  openGraph: {
    title: "🛒 EpiList - L'App de Courses Familiale #1 | Gratuite & Sans Pub",
    description:
      "Simplifiez vos courses avec des listes partagées, sync instantanée et mode hors ligne. Rejoignez 50k+ familles satisfaites !",
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
      "Listes partagées • Sync temps réel • Mode hors ligne • 4.9⭐ • 0$ à vie",
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
