import ContactContent from "@/components/ContactContent";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Contact EpiList - Support & Questions | Équipe Nouveau-Brunswick",
  description:
    "Contactez l'équipe EpiList pour support, questions ou suggestions. Basés au Nouveau-Brunswick, nous répondons sous 24h. Support gratuit pour tous nos utilisateurs.",
  keywords:
    "contact EpiList, support application courses, aide EpiList, équipe Nouveau-Brunswick, service client gratuit",

  openGraph: {
    title: "Contactez EpiList - Support Gratuit 24/7",
    description:
      "Questions sur EpiList ? Notre équipe du Nouveau-Brunswick est là pour vous aider. Support gratuit et réactif.",
    url: "https://epilist.app/contact",
  },

  alternates: {
    canonical: "https://epilist.app/contact",
  },
};

export default function ContactPage() {
  return <ContactContent />;
}
