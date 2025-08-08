import type { Metadata } from "next";
import ComparisonContent from "@/components/ComparisonContent";

export const metadata: Metadata = {
  title:
    "EpiList vs AnyList, Cozi, OurGroceries - Comparaison Apps Courses 2025",
  description:
    "⚖️ Comparaison complète EpiList vs concurrents. Pourquoi choisir EpiList ? Gratuit, sync famille, mode hors ligne, sans pub. Tableau comparatif détaillé.",
  keywords:
    "EpiList vs AnyList, comparaison applications courses, meilleure app liste courses 2025, EpiList vs Cozi, alternative gratuite AnyList",

  openGraph: {
    title: "⚖️ EpiList vs Concurrents - Comparaison Apps Courses 2025",
    description:
      "Tableau comparatif • EpiList 100% gratuit • Sync famille • Sans pub • Mode hors ligne",
    url: "https://epilist.app/comparaison-applications-courses",
  },

  alternates: {
    canonical: "https://epilist.app/comparaison-applications-courses",
  },
};

export default function ComparaisonPage() {
  return <ComparisonContent />;
}
