import type { Metadata } from "next";
import TermsContent from "@/components/TermsContent";

export const metadata: Metadata = {
  title: "Conditions d'Utilisation EpiList - Termes & Politique Usage",
  description:
    "📋 Conditions d'utilisation EpiList. Termes simples et transparents pour utilisation gratuite. Pas de piège, pas de frais cachés. Mise à jour 2025.",
  keywords:
    "conditions utilisation EpiList, termes service application courses, politique usage app gratuite, CGU EpiList",

  openGraph: {
    title: "📋 Conditions d'Utilisation EpiList - Transparence Totale",
    description:
      "Termes simples • Gratuit à vie • Pas de piège • Transparent • Mis à jour 2025",
    url: "https://epilist.app/conditions-utilisation",
  },

  alternates: {
    canonical: "https://epilist.app/conditions-utilisation",
  },
};

export default function ConditionsPage() {
  return <TermsContent />;
}
