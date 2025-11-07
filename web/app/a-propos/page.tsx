import AboutContent from "@/components/AboutContent";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "À Propos EpiList - Équipe Nouveau-Brunswick, Mission & Valeurs",
  description:
    "👥 Découvrez l'équipe EpiList basée au Nouveau-Brunswick. Notre mission : simplifier les courses familiales. 200+ utilisateurs actifs nous font confiance depuis 2024.",
  keywords:
    "équipe EpiList, entreprise Nouveau-Brunswick, mission EpiList, à propos application courses, startup tech maritime",

  openGraph: {
    title: "👥 À Propos EpiList - Équipe Nouveau-Brunswick",
    description:
      "Startup tech maritime • Mission familiale • 200+ utilisateurs actifs • Gratuit à vie",
    url: "https://epilist.app/a-propos",
  },

  alternates: {
    canonical: "https://epilist.app/a-propos",
  },
};

export default function AProposPage() {
  return <AboutContent />;
}
