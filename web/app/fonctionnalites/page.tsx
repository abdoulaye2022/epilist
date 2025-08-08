import FeaturesContent from "@/components/FeaturesContent";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Fonctionnalités EpiList - Synchronisation Famille, Mode Hors Ligne",
  description:
    "🚀 Découvrez toutes les fonctionnalités EpiList : synchronisation familiale temps réel, mode hors ligne, suggestions intelligentes, partage instantané. Gratuit !",
  keywords:
    "fonctionnalités EpiList, synchronisation famille courses, mode hors ligne application, partage liste courses, suggestions intelligentes achats",

  openGraph: {
    title: "🚀 Fonctionnalités EpiList - Sync Famille & Mode Hors Ligne",
    description:
      "Sync temps réel • Mode hors ligne • Suggestions IA • Partage famille • Interface intuitive",
    url: "https://epilist.app/fonctionnalites",
  },

  alternates: {
    canonical: "https://epilist.app/fonctionnalites",
  },
};

export default function FonctionnalitesPage() {
  return <FeaturesContent />;
}
