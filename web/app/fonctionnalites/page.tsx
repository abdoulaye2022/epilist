import FeaturesContent from "@/components/FeaturesContent";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "15+ Fonctionnalités EpiList - Sync Temps Réel, Multi-Devises, Mode Hors Ligne, SSO",
  description:
    "🚀 Découvrez les 15+ fonctionnalités EpiList : synchronisation temps réel, 150+ devises, mode hors ligne avancé, SSO (Google/Apple), catégories personnalisables, reçus photo, notifications instantanées, analytiques visuelles, préférences email. 100% gratuit !",
  keywords:
    "fonctionnalités EpiList, synchronisation famille courses, mode hors ligne application, multi-devises, SSO Google Apple, catégories personnalisables, reçus photo, notifications temps réel, analytiques visuelles, partage liste courses, suggestions intelligentes achats, préférences email",

  openGraph: {
    title: "🚀 15+ Fonctionnalités EpiList - Sync Famille, Multi-Devises & Plus",
    description:
      "Sync temps réel • 150+ devises • Mode hors ligne avancé • SSO Google/Apple • Catégories personnalisables • Reçus photo • Notifications • Analytiques • 100% gratuit",
    url: "https://epilist.app/fonctionnalites",
  },

  twitter: {
    title: "🚀 15+ Fonctionnalités EpiList",
    description:
      "Sync temps réel • 150+ devises • Mode hors ligne • SSO • Catégories • Reçus photo • Notifications • Analytiques",
  },

  alternates: {
    canonical: "https://epilist.app/fonctionnalites",
  },
};

export default function FonctionnalitesPage() {
  return <FeaturesContent />;
}
