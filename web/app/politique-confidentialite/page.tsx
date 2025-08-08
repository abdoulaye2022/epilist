import type { Metadata } from "next";
import PrivacyContent from "@/components/PrivacyContent";

export const metadata: Metadata = {
  title: "Politique Confidentialité EpiList - Protection Données Familiales",
  description:
    "🔒 Politique de confidentialité EpiList. Vos données familiales 100% protégées. Pas de vente de données, chiffrement bout en bout. Conformité RGPD.",
  keywords:
    "politique confidentialité EpiList, protection données famille, sécurité application courses, RGPD conformité, vie privée app",

  openGraph: {
    title: "🔒 Confidentialité EpiList - Vos Données 100% Protégées",
    description:
      "Chiffrement bout en bout • Pas de vente données • RGPD • Sécurité famille • Transparent",
    url: "https://epilist.app/politique-confidentialite",
  },

  alternates: {
    canonical: "https://epilist.app/politique-confidentialite",
  },
};

export default function PolitiqueConfidentialitePage() {
  return <PrivacyContent />;
}
