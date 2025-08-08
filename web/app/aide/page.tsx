import HelpContent from "@/components/HelpContent";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Aide EpiList - FAQ, Tutoriels & Support Gratuit",
  description:
    "❓ Besoin d'aide avec EpiList ? FAQ complète, tutoriels vidéo, guide synchronisation famille. Support gratuit 24/7 par équipe Nouveau-Brunswick.",
  keywords:
    "aide EpiList, FAQ application courses, tutoriel synchronisation famille, support EpiList gratuit, guide utilisation app courses",

  openGraph: {
    title: "❓ Aide EpiList - FAQ & Support Gratuit",
    description:
      "FAQ complète • Tutoriels • Support 24/7 • Équipe NB • Réponse garantie sous 24h",
    url: "https://epilist.app/aide",
  },

  alternates: {
    canonical: "https://epilist.app/aide",
  },
};

export default function AidePage() {
  return <HelpContent />;
}
